SET search_path TO saas;

-- Accounts that have at least one canceled subscription
WITH canceled_accounts AS (
    SELECT DISTINCT account_id
    FROM subscriptions
    WHERE status = 'canceled'
),

-- Weekly usage = count of product events per (account, week)
weekly_usage AS (
    SELECT
        u.account_id,
        date_trunc('week', pe.event_time)::date AS week,
        COUNT(*) AS usage
    FROM product_events pe
    JOIN users u USING (user_id)
    JOIN canceled_accounts ca
      ON ca.account_id = u.account_id
    GROUP BY 1, 2
),

-- Add previous week usage using LAG
usage_with_lag AS (
    SELECT
        account_id,
        week,
        usage,
        LAG(usage) OVER (
            PARTITION BY account_id
            ORDER BY week
        ) AS prev_usage
    FROM weekly_usage
)

SELECT
    account_id,
    week,
    usage,
    prev_usage,
    -- Drop% = (prev - current) / prev
    ROUND((prev_usage - usage)::numeric / NULLIF(prev_usage, 0), 2) AS drop_pct
FROM usage_with_lag
WHERE prev_usage > 0
  AND (prev_usage - usage)::numeric / prev_usage >= 0.40
ORDER BY account_id, week;
