SET search_path TO saas;

-- Indexes (to make date/join queries fast)
CREATE INDEX idx_users_account ON users(account_id);
CREATE INDEX idx_subs_account ON subscriptions(account_id);
CREATE INDEX idx_invoices_sub_month ON invoices(subscription_id, invoice_month);
CREATE INDEX idx_invoices_paid ON invoices(paid_at);
CREATE INDEX idx_refunds_refunded_at ON refunds(refunded_at);
CREATE INDEX idx_events_user_time ON product_events(user_id, event_time);