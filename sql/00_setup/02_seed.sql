SET search_path TO saas;

-- Optional: to make randomness reproducible within a session
SELECT setseed(0.42);

-- plans
INSERT INTO plans (plan_name, monthly_price) VALUES
('basic', 49.00),
('pro', 149.00),
('enterprise', 499.00);

-- accounts
INSERT INTO accounts (created_at, country, industry)
SELECT
  (TIMESTAMP '2024-10-01' + (random() * INTERVAL '365 days')) AT TIME ZONE 'UTC',
  (ARRAY['UA','NL','DE','PL','FR','US'])[1 + floor(random()*6)],
  (ARRAY['ecommerce','fintech','edtech','health','media','logistics'])[1 + floor(random()*6)]
FROM generate_series(1, 100);

-- acquisition 
INSERT INTO acquisition (account_id, source, campaign, acquired_at)
SELECT
  a.account_id,
  (ARRAY['google','organic','partner','linkedin','referral'])[1 + floor(random()*5)] AS source,
  (ARRAY['brand','promo','retarget','q1_push','webinar'])[1 + floor(random()*5)] AS campaign,
  a.created_at - (random() * INTERVAL '10 days')
FROM accounts a;

-- users
INSERT INTO users (account_id, created_at, role)
SELECT
  a.account_id,
  a.created_at + (random() * INTERVAL '30 days'),
  CASE WHEN gs = 1 THEN 'admin' ELSE 'member' END
FROM accounts a
JOIN LATERAL generate_series(1, (1 + floor(random()*8))::int) AS gs ON true;

-- subscriptions
-- almost everyone's first subscription (ended_at >= started_at)
WITH base AS (
  SELECT
    a.account_id,
    (SELECT plan_id FROM plans ORDER BY random() LIMIT 1) AS plan_id,
    (a.created_at + (random() * INTERVAL '14 days')) AS started_at,
    random() AS r_status,
    random() AS r_end
  FROM accounts a
)
INSERT INTO subscriptions (account_id, plan_id, started_at, ended_at, status)
SELECT
  account_id,
  plan_id,  
  started_at,
  CASE
    WHEN r_end < 0.25 THEN started_at + (random() * INTERVAL '200 days')
    ELSE NULL
  END AS ended_at,
  CASE
    WHEN r_status < 0.20 THEN 'trial'
    WHEN r_status < 0.35 THEN 'canceled'
    ELSE 'active'
  END AS status
FROM base;


-- second subscription (upgrade) for some accounts
INSERT INTO subscriptions (account_id, plan_id, started_at, ended_at, status)
SELECT
  s.account_id,
  -- upgrade: pro or enterprise more often
  (SELECT plan_id FROM plans WHERE plan_name IN ('pro','enterprise') ORDER BY random() LIMIT 1),
  s.started_at + INTERVAL '60 days' + (random() * INTERVAL '60 days'),
  NULL,
  'active'
FROM subscriptions s
WHERE random() < 0.30;

-- invoices
-- We create invoices for months 2025 for each subscription during the active period
INSERT INTO invoices (subscription_id, invoice_month, amount, issued_at, paid_at)
SELECT
  s.subscription_id,
  m.month::date AS invoice_month,
  -- amount = plan price + a few random increases/decreases (simulating changes)
  (p.monthly_price * (0.9 + random()*0.3))::numeric(10,2) AS amount,
  (m.month + INTERVAL '1 day') AT TIME ZONE 'UTC' AS issued_at,
  CASE WHEN random() < 0.85 THEN (m.month + INTERVAL '3 days') AT TIME ZONE 'UTC' ELSE NULL END AS paid_at
FROM subscriptions s
JOIN plans p ON p.plan_id = s.plan_id
JOIN LATERAL (
  SELECT generate_series(date '2025-01-01', date '2025-12-01', interval '1 month') AS month
) m ON true
WHERE s.started_at < (m.month + interval '1 month')
  AND (s.ended_at IS NULL OR s.ended_at >= m.month);

-- refunds
-- Create refunds only for paid invoices
INSERT INTO refunds (invoice_id, refunded_at, refund_amount)
SELECT
  i.invoice_id,
  (i.paid_at + (random() * INTERVAL '45 days')) AS refunded_at,
  (i.amount * (0.1 + random()*0.6))::numeric(10,2) AS refund_amount
FROM invoices i
WHERE i.paid_at IS NOT NULL
  AND random() < 0.12;  -- 12% of invoices with refund

-- product_events
-- For each user we will generate ~20-120 events
INSERT INTO product_events (user_id, event_time, event_type, meta)
SELECT
  u.user_id,
  (TIMESTAMP '2025-01-01' + (random() * INTERVAL '365 days')) AT TIME ZONE 'UTC' AS event_time,
  (ARRAY['login','login','login','api_call','invite','settings_change','export'])[1 + floor(random()*7)] AS event_type,
  jsonb_build_object('rand', (random()*1000)::int)
FROM users u
JOIN LATERAL generate_series(1, (20 + floor(random()*100))::int) gs ON true;



