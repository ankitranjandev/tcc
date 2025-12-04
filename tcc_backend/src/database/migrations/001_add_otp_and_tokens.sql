-- Add OTP table
CREATE TABLE IF NOT EXISTS otps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(20) NOT NULL,
    country_code VARCHAR(5) NOT NULL,
    otp VARCHAR(10) NOT NULL,
    purpose VARCHAR(20) NOT NULL CHECK (purpose IN ('REGISTRATION', 'LOGIN', 'PHONE_CHANGE', 'PASSWORD_RESET', 'WITHDRAWAL', 'TRANSFER')),
    is_verified BOOLEAN DEFAULT FALSE,
    attempts INT DEFAULT 0,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_otps_phone ON otps(phone, country_code);
CREATE INDEX idx_otps_purpose ON otps(purpose);
CREATE INDEX idx_otps_expires_at ON otps(expires_at);

-- Add refresh tokens table
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token ON refresh_tokens(token);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);
