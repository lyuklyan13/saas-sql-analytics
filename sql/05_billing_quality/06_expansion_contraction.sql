SET search_path TO saas;

-- Paid invoices only (per subscription over time)
WITH paid_invoices AS (
    SELECT
        subscription_id,
        invoice_month,
        amount AS paid_amount
    FROM invoices
    WHERE paid_at IS NOT NULL
),

-- Previous paid amount per subscription
invoice_with_lag AS (
    SELECT
        subscription_id,
        invoice_month,
        paid_amount,
        LAG(paid_amount) OVER (
            PARTITION BY subscription_id
            ORDER BY invoice_month
        ) AS prev_amount
    FROM paid_invoices
)

SELECT
    subscription_id,
    invoice_month,
    paid_amount,
    (paid_amount - prev_amount) AS delta,
    CASE
        WHEN prev_amount IS NULL THEN 'first_payment'
        WHEN paid_amount > prev_amount THEN 'expansion'
        WHEN paid_amount < prev_amount THEN 'contraction'
        ELSE 'flat'
    END AS classification
FROM invoice_with_lag
ORDER BY subscription_id, invoice_month;
