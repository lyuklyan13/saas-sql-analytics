SET search_path TO saas;

-- Gross MRR: sum of paid invoices by invoice month
WITH gross AS (
    SELECT
        date_trunc('month', invoice_month)::date AS month,
        SUM(amount) AS gross_mrr
    FROM invoices
    WHERE paid_at IS NOT NULL
    GROUP BY 1
),

-- Refunds by refund month (refund timing can differ from invoice_month)
refunds_by_month AS (
    SELECT
        date_trunc('month', refunded_at)::date AS month,
        SUM(refund_amount) AS refunds
    FROM refunds
    GROUP BY 1
),

-- Net MRR = Gross MRR - Refunds (align by month)
net AS (
    SELECT
        COALESCE(g.month, r.month) AS month,
        COALESCE(g.gross_mrr, 0) AS gross_mrr,
        COALESCE(r.refunds, 0) AS refunds,
        COALESCE(g.gross_mrr, 0) - COALESCE(r.refunds, 0) AS net_mrr
    FROM gross g
    FULL JOIN refunds_by_month r USING (month)
)

SELECT
    month,
    gross_mrr,
    refunds,
    net_mrr,
    -- MoM% change of net_mrr (guard against division by zero)
    ROUND(
        100.0
        * (net_mrr - LAG(net_mrr) OVER (ORDER BY month))
        / NULLIF(LAG(net_mrr) OVER (ORDER BY month), 0),
        2
    ) AS mom_change_pct
FROM net
ORDER BY month;
