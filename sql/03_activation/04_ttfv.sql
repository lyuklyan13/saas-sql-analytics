SET search_path TO saas;

-- First value event (export) AFTER signup (data quality guard)
WITH first_value AS (
    SELECT
        u.account_id,
        MIN(pe.event_time) AS first_value_date
    FROM users u
    JOIN accounts a USING (account_id)
    JOIN product_events pe USING (user_id)
    WHERE pe.event_type = 'export'
      AND pe.event_time >= a.created_at
    GROUP BY 1
),

-- Days to value per account
ttfv_by_account AS (
    SELECT
        a.account_id,
        a.created_at::date AS signup_date,
        fv.first_value_date::date AS first_value_date,
        (fv.first_value_date::date - a.created_at::date) AS days_to_value
    FROM accounts a
    JOIN first_value fv USING (account_id)
)

SELECT
    ac.source,
    COUNT(*) AS accounts_cnt,
    -- Median days_to_value by acquisition source
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY t.days_to_value) AS median_days_to_value
FROM ttfv_by_account t
JOIN acquisition ac USING (account_id)
GROUP BY ac.source
ORDER BY median_days_to_value;
