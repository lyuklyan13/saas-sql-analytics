SET search_path TO saas;

-- Compare attribution sources across two systems
SELECT
    COALESCE(a.account_id, c.account_id) AS account_id,
    a.source AS acquisition_source,
    c.source AS crm_source,
    CASE
        WHEN a.account_id IS NULL THEN 'only_in_crm'
        WHEN c.account_id IS NULL THEN 'only_in_acquisition'
        WHEN a.source <> c.source THEN 'source_mismatch'
        ELSE 'match'
    END AS attribution_status
FROM acquisition a
FULL JOIN crm_acquisition c USING (account_id)
-- Keep only issues (drop matches)
WHERE a.account_id IS NULL
   OR c.account_id IS NULL
   OR a.source <> c.source
ORDER BY account_id;


