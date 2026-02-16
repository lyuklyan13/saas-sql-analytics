SET search_path TO saas;

-- CRM system acquisition table
-- This table simulates attribution data stored in CRM
CREATE TABLE IF NOT EXISTS crm_acquisition (
    account_id BIGINT PRIMARY KEY
        REFERENCES accounts(account_id)
        ON DELETE CASCADE,
    source TEXT NOT NULL
);
