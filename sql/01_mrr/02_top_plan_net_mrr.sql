SET search_path TO saas;

-- Paid invoice gross by (month, plan)
WITH gross_plan AS (
    SELECT
        date_trunc('month', i.invoice_month)::date AS month,
        s.plan_id,
        SUM(i.amount) AS gross_mrr,
        -- Tie-break metric: unique paying accounts per plan per month
        COUNT(DISTINCT s.account_id) AS accounts_cnt
    FROM invoices i
    JOIN subscriptions s ON s.subscription_id = i.subscription_id
    WHERE i.paid_at IS NOT NULL
    GROUP BY 1, 2
),

-- Refunds by (refund_month, plan) using refunds -> invoices -> subscriptions
refunds_plan AS (
    SELECT
        date_trunc('month', r.refunded_at)::date AS month,
        s.plan_id,
        SUM(r.refund_amount) AS refunds
    FROM refunds r
    JOIN invoices i ON i.invoice_id = r.invoice_id
    JOIN subscriptions s ON s.subscription_id = i.subscription_id
    GROUP BY 1, 2
),

-- Net MRR per (month, plan)
net_plan AS (
    SELECT
        COALESCE(g.month, rp.month) AS month,
        COALESCE(g.plan_id, rp.plan_id) AS plan_id,
        COALESCE(g.gross_mrr, 0) AS gross_mrr,
        COALESCE(rp.refunds, 0) AS refunds,
        COALESCE(g.gross_mrr, 0) - COALESCE(rp.refunds, 0) AS net_mrr,
        COALESCE(g.accounts_cnt, 0) AS accounts_cnt
    FROM gross_plan g
    FULL JOIN refunds_plan rp USING (month, plan_id)
),

-- Rank plans within each month by net_mrr desc; tie-break by accounts_cnt desc
ranked AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY month
            ORDER BY net_mrr DESC, accounts_cnt DESC
        ) AS rnk
    FROM net_plan
)

SELECT
    r.month,
    r.plan_id,
    p.plan_name,
    r.net_mrr,
    r.accounts_cnt
FROM ranked r
JOIN plans p ON p.plan_id = r.plan_id
WHERE r.rnk = 1
ORDER BY r.month;
