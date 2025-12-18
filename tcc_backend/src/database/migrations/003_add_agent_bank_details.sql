-- Migration: Add agent_bank_details table for storing agent banking information
-- Date: 2024-12-17
-- Description: This table stores bank account information for agents to receive commission payments

-- Create agent_bank_details table
CREATE TABLE IF NOT EXISTS agent_bank_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID NOT NULL,
    bank_name VARCHAR(100) NOT NULL,
    branch_address TEXT NOT NULL,
    ifsc_code VARCHAR(11) NOT NULL,
    account_holder_name VARCHAR(100) NOT NULL,
    account_number VARCHAR(255), -- Will be encrypted
    account_type VARCHAR(20) DEFAULT 'SAVINGS' CHECK (account_type IN ('SAVINGS', 'CURRENT')),
    is_primary BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID,
    verified_at TIMESTAMP,
    verification_notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    -- Foreign key constraints
    CONSTRAINT fk_agent_bank_details_agent
        FOREIGN KEY (agent_id)
        REFERENCES agents(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_agent_bank_details_verified_by
        FOREIGN KEY (verified_by)
        REFERENCES users(id)
        ON DELETE SET NULL
);

-- Create indexes for better query performance
CREATE INDEX idx_agent_bank_details_agent_id ON agent_bank_details(agent_id);
CREATE INDEX idx_agent_bank_details_is_primary ON agent_bank_details(is_primary);
CREATE INDEX idx_agent_bank_details_is_verified ON agent_bank_details(is_verified);

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_agent_bank_details_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_agent_bank_details_updated_at
    BEFORE UPDATE ON agent_bank_details
    FOR EACH ROW
    EXECUTE FUNCTION update_agent_bank_details_updated_at();

-- Add comments for documentation
COMMENT ON TABLE agent_bank_details IS 'Stores bank account information for agents to receive commission payments';
COMMENT ON COLUMN agent_bank_details.id IS 'Unique identifier for the bank account record';
COMMENT ON COLUMN agent_bank_details.agent_id IS 'Reference to the agent who owns this bank account';
COMMENT ON COLUMN agent_bank_details.bank_name IS 'Name of the bank';
COMMENT ON COLUMN agent_bank_details.branch_address IS 'Full address of the bank branch';
COMMENT ON COLUMN agent_bank_details.ifsc_code IS 'Indian Financial System Code for the bank branch';
COMMENT ON COLUMN agent_bank_details.account_holder_name IS 'Name of the account holder as per bank records';
COMMENT ON COLUMN agent_bank_details.account_number IS 'Encrypted bank account number';
COMMENT ON COLUMN agent_bank_details.account_type IS 'Type of bank account (SAVINGS or CURRENT)';
COMMENT ON COLUMN agent_bank_details.is_primary IS 'Indicates if this is the primary account for commission payments';
COMMENT ON COLUMN agent_bank_details.is_verified IS 'Indicates if the bank account has been verified by admin';
COMMENT ON COLUMN agent_bank_details.verified_by IS 'Admin user who verified the bank account';
COMMENT ON COLUMN agent_bank_details.verified_at IS 'Timestamp when the account was verified';
COMMENT ON COLUMN agent_bank_details.verification_notes IS 'Notes from admin during verification';

-- Function to ensure only one primary account per agent
CREATE OR REPLACE FUNCTION ensure_single_primary_bank_account()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_primary = TRUE THEN
        -- Set all other accounts for this agent to non-primary
        UPDATE agent_bank_details
        SET is_primary = FALSE
        WHERE agent_id = NEW.agent_id
        AND id != NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_ensure_single_primary_bank_account
    BEFORE INSERT OR UPDATE ON agent_bank_details
    FOR EACH ROW
    WHEN (NEW.is_primary = TRUE)
    EXECUTE FUNCTION ensure_single_primary_bank_account();

-- Add a function to get primary bank account for an agent
CREATE OR REPLACE FUNCTION get_agent_primary_bank_account(p_agent_id UUID)
RETURNS TABLE (
    id UUID,
    bank_name VARCHAR(100),
    branch_address TEXT,
    ifsc_code VARCHAR(11),
    account_holder_name VARCHAR(100),
    account_type VARCHAR(20),
    is_verified BOOLEAN,
    verified_at TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        abd.id,
        abd.bank_name,
        abd.branch_address,
        abd.ifsc_code,
        abd.account_holder_name,
        abd.account_type,
        abd.is_verified,
        abd.verified_at
    FROM agent_bank_details abd
    WHERE abd.agent_id = p_agent_id
    AND abd.is_primary = TRUE
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions (adjust based on your roles)
GRANT SELECT, INSERT, UPDATE ON agent_bank_details TO authenticated;
GRANT SELECT ON agent_bank_details TO anon;
GRANT ALL ON agent_bank_details TO service_role;