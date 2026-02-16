SET search_path TO saas;

-- Timeline of plans per account (ordered in time)
WITH plan_timeline AS (
    SELECT
        s.account_id,
        s.subscription_id,
        s.started_at,
        s.plan_id,
        LAG(s.plan_id) OVER (
            PARTITION BY s.account_id
            ORDER BY s.started_at, s.subscription_id
        ) AS prev_plan_id
    FROM subscriptions s
),

-- Keep only actual plan changes
transitions AS (
    SELECT
        account_id,
        started_at::date AS transition_date,
        prev_plan_id AS from_plan_id,
        plan_id      AS to_plan_id
    FROM plan_timeline
    WHERE prev_plan_id IS NOT NULL
      AND prev_plan_id <> plan_id
)

SELECT
    t.account_id,
    t.transition_date,
    pf.plan_name AS from_plan,
    pt.plan_name AS to_plan
FROM transitions t
JOIN plans pf ON pf.plan_id = t.from_plan_id
JOIN plans pt ON pt.plan_id = t.to_plan_id
ORDER BY t.account_id, t.transition_date;
