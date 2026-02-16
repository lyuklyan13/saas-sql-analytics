SET search_path TO saas;

-- Insert CRM attribution data
INSERT INTO crm_acquisition (account_id, source)
SELECT
    account_id,
    (ARRAY['google','organic','partner','linkedin','facebook'])[1 + floor(random()*5)]
FROM accounts
WHERE random() < 0.9   -- not all accounts exist in CRM
ON CONFLICT (account_id) DO NOTHING;
