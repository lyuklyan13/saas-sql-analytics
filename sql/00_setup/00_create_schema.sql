-- 0) (Optional) clean everything
DROP SCHEMA IF EXISTS saas CASCADE;
CREATE SCHEMA saas;
SET search_path TO saas;

-- 1) accounts
CREATE TABLE accounts (
  account_id   BIGSERIAL PRIMARY KEY,
  created_at   TIMESTAMPTZ NOT NULL,
  country      TEXT NOT NULL,
  industry     TEXT NOT NULL
);

-- 2) users
CREATE TABLE users (
  user_id     BIGSERIAL PRIMARY KEY,
  account_id  BIGINT NOT NULL REFERENCES accounts(account_id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL,
  role        TEXT NOT NULL CHECK (role IN ('admin','member'))
);

-- 3) plans
CREATE TABLE plans (
  plan_id        BIGSERIAL PRIMARY KEY,
  plan_name      TEXT NOT NULL UNIQUE,
  monthly_price  NUMERIC(10,2) NOT NULL CHECK (monthly_price >= 0)
);

-- 4) subscriptions
CREATE TABLE subscriptions (
  subscription_id BIGSERIAL PRIMARY KEY,
  account_id      BIGINT NOT NULL REFERENCES accounts(account_id) ON DELETE CASCADE,
  plan_id         BIGINT NOT NULL REFERENCES plans(plan_id),
  started_at      TIMESTAMPTZ NOT NULL,
  ended_at        TIMESTAMPTZ,
  status          TEXT NOT NULL CHECK (status IN ('trial','active','canceled')),
  CHECK (ended_at IS NULL OR ended_at >= started_at)
);

-- 5) invoices
CREATE TABLE invoices (
  invoice_id      BIGSERIAL PRIMARY KEY,
  subscription_id BIGINT NOT NULL REFERENCES subscriptions(subscription_id) ON DELETE CASCADE,
  invoice_month   DATE NOT NULL,          
  amount          NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
  issued_at       TIMESTAMPTZ NOT NULL,
  paid_at         TIMESTAMPTZ
);

-- 6) refunds
CREATE TABLE refunds (
  refund_id      BIGSERIAL PRIMARY KEY,
  invoice_id     BIGINT NOT NULL REFERENCES invoices(invoice_id) ON DELETE CASCADE,
  refunded_at    TIMESTAMPTZ NOT NULL,
  refund_amount  NUMERIC(10,2) NOT NULL CHECK (refund_amount >= 0)
);

-- 7) product_events
CREATE TABLE product_events (
  event_id    BIGSERIAL PRIMARY KEY,
  user_id     BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  event_time  TIMESTAMPTZ NOT NULL,
  event_type  TEXT NOT NULL CHECK (event_type IN ('login','export','invite','api_call','settings_change')),
  meta        JSONB
);

-- 8) acquisition 
CREATE TABLE acquisition (
  account_id   BIGINT PRIMARY KEY REFERENCES accounts(account_id) ON DELETE CASCADE,
  source       TEXT NOT NULL,
  campaign     TEXT,
  acquired_at  TIMESTAMPTZ NOT NULL
);
