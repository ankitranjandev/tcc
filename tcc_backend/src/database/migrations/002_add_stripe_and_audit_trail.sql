-- Add Stripe customer ID to users table
ALTER TABLE users
ADD COLUMN IF NOT EXISTS stripe_customer_id VARCHAR(255) UNIQUE;

CREATE INDEX IF NOT EXISTS idx_users_stripe_customer ON users(stripe_customer_id);

-- Add Stripe payment intent ID to transactions table
ALTER TABLE transactions
ADD COLUMN IF NOT EXISTS stripe_payment_intent_id VARCHAR(255) UNIQUE,
ADD COLUMN IF NOT EXISTS payment_gateway_response JSONB;

CREATE INDEX IF NOT EXISTS idx_transactions_stripe_payment_intent ON transactions(stripe_payment_intent_id);
CREATE INDEX IF NOT EXISTS idx_transactions_payment_gateway_response ON transactions USING GIN(payment_gateway_response);

-- Create wallet audit trail table for manual balance adjustments
CREATE TABLE IF NOT EXISTS wallet_audit_trail (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    admin_id UUID NOT NULL REFERENCES users(id),
    action_type VARCHAR(50) NOT NULL CHECK (action_type IN ('MANUAL_CREDIT', 'MANUAL_DEBIT', 'BALANCE_CORRECTION', 'REFUND')),
    amount DECIMAL(15, 2) NOT NULL,
    balance_before DECIMAL(15, 2) NOT NULL,
    balance_after DECIMAL(15, 2) NOT NULL,
    reason TEXT NOT NULL,
    notes TEXT,
    transaction_id VARCHAR(50),
    ip_address VARCHAR(45),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_trail_user ON wallet_audit_trail(user_id);
CREATE INDEX idx_audit_trail_admin ON wallet_audit_trail(admin_id);
CREATE INDEX idx_audit_trail_action_type ON wallet_audit_trail(action_type);
CREATE INDEX idx_audit_trail_created_at ON wallet_audit_trail(created_at);
CREATE INDEX idx_audit_trail_transaction ON wallet_audit_trail(transaction_id);

-- Add comment to document the audit trail table
COMMENT ON TABLE wallet_audit_trail IS 'Tracks all manual wallet balance adjustments made by administrators';
COMMENT ON COLUMN wallet_audit_trail.action_type IS 'Type of manual adjustment: MANUAL_CREDIT, MANUAL_DEBIT, BALANCE_CORRECTION, or REFUND';
COMMENT ON COLUMN wallet_audit_trail.balance_before IS 'Wallet balance before the adjustment';
COMMENT ON COLUMN wallet_audit_trail.balance_after IS 'Wallet balance after the adjustment';
COMMENT ON COLUMN wallet_audit_trail.reason IS 'Required reason for the adjustment';
COMMENT ON COLUMN wallet_audit_trail.notes IS 'Optional additional notes about the adjustment';
