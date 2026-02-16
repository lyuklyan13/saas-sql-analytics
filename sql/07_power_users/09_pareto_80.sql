SET search_path TO saas;

-- Usage per user for last 30 days
WITH user_usage_30d AS (
    SELECT
        u.account_id,
        u.user_id,
        COUNT(*) AS usage
    FROM users u
    JOIN product_events pe USING (user_id)
    WHERE pe.event_time >= current_date - interval '30 days'
    GROUP BY 1, 2
),

-- Total usage per account
with_totals AS (
    SELECT
        account_id,
        user_id,
        usage,
        SUM(usage) OVER (PARTITION BY account_id) AS total_usage
    FROM user_usage_30d
),

-- Cumulative usage ordered by most active users first
cumulative AS (
    SELECT
        account_id,
        user_id,
        usage,
        total_usage,
        SUM(usage) OVER (
            PARTITION BY account_id
            ORDER BY usage DESC, user_id
            ROWS UNBOUNDED PRECEDING
        ) AS cumulative_usage
    FROM with_totals
),

-- Add cumulative pct and stable rank within account
marked AS (
    SELECT
        *,
        cumulative_usage::numeric / NULLIF(total_usage, 0) AS cumulative_pct,
        ROW_NUMBER() OVER (
            PARTITION BY account_id
            ORDER BY usage DESC, user_id
        ) AS rn
    FROM cumulative
),

-- Find the first row where we reach/exceed 80%
threshold AS (
    SELECT
        account_id,
        MIN(rn) AS rn_cut
    FROM marked
    WHERE cumulative_pct >= 0.8
    GROUP BY 1
)

-- Minimal prefix of users that reaches 80% usage
SELECT
    m.account_id,
    m.user_id,
    m.usage,
    m.total_usage,
    ROUND(m.cumulative_pct, 3) AS cumulative_pct
FROM marked m
JOIN threshold t USING (account_id)
WHERE m.rn <= t.rn_cut
ORDER BY m.account_id, m.rn;
