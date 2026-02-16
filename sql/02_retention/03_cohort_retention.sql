SET search_path TO saas;

-- Cohort month = account signup month
WITH cohorts AS (
    SELECT
        account_id,
        date_trunc('month', created_at)::date AS cohort_month
    FROM accounts
),

-- Active month = month with at least one PAID invoice
active_months AS (
    SELECT
        s.account_id,
        date_trunc('month', i.invoice_month)::date AS active_month
    FROM invoices i
    JOIN subscriptions s ON s.subscription_id = i.subscription_id
    WHERE i.paid_at IS NOT NULL
    GROUP BY 1, 2
),

-- Link cohorts to activity and compute month_number (months since cohort)
activity_by_cohort AS (
    SELECT
        c.account_id,
        c.cohort_month,
        a.active_month,
        (
            (EXTRACT(YEAR FROM a.active_month) - EXTRACT(YEAR FROM c.cohort_month)) * 12
          + (EXTRACT(MONTH FROM a.active_month) - EXTRACT(MONTH FROM c.cohort_month))
        )::int AS month_number
    FROM cohorts c
    JOIN active_months a
      ON a.account_id = c.account_id
    -- safety: avoid negative offsets if data contains anomalies
    WHERE a.active_month >= c.cohort_month
),

-- Retained accounts per cohort/month_number
retained AS (
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT account_id) AS retained_accounts
    FROM activity_by_cohort
    GROUP BY 1, 2
),

-- Cohort size = retained at month_number = 0
cohort_size AS (
    SELECT
        cohort_month,
        retained_accounts AS cohort_size
    FROM retained
    WHERE month_number = 0
)

SELECT
    r.cohort_month,
    r.month_number,
    r.retained_accounts,
    cs.cohort_size,
    ROUND(r.retained_accounts::numeric / NULLIF(cs.cohort_size, 0), 3) AS retention_rate
FROM retained r
JOIN cohort_size cs USING (cohort_month)
ORDER BY r.cohort_month, r.month_number;
