SET search_path TO saas;

-- Paid invoices only
WITH paid_invoices AS (
    SELECT
        invoice_id,
        subscription_id,
        invoice_month,
        paid_at,
        amount
    FROM invoices
    WHERE paid_at IS NOT NULL
),

-- Flag subscriptions with multiple paid invoices in the same month
flagged AS (
    SELECT
        *,
        COUNT(*) OVER (
            PARTITION BY subscription_id, invoice_month
        ) AS invoices_cnt_in_month,
        ROW_NUMBER() OVER (
            PARTITION BY subscription_id, invoice_month
            ORDER BY paid_at, invoice_id
        ) AS rank_in_month
    FROM paid_invoices
)

SELECT
    subscription_id,
    invoice_month,
    invoice_id,
    paid_at,
    amount,
    rank_in_month
FROM flagged
WHERE invoices_cnt_in_month > 1
ORDER BY subscription_id, invoice_month, rank_in_month;
