# TCC Application - Low-Level Design (LLD) Gap Analysis

**Date:** October 26, 2025
**Review Type:** Complete LLD-Level Review
**Documents Reviewed:** database_schema.sql, api_specification.md, design_system.md, currency_formatting_utilities.md

---

## Critical Gaps Found ⚠️

### 1. Database Schema Gaps

#### 1.1 Missing Tables

**❌ File Uploads Table**
```sql
-- MISSING: Centralized file storage tracking
CREATE TABLE file_uploads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    file_type VARCHAR(50) NOT NULL, -- 'KYC_DOCUMENT', 'RECEIPT', 'PROFILE_PICTURE', etc.
    original_filename VARCHAR(255) NOT NULL,
    stored_filename VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    checksum VARCHAR(64), -- SHA-256 hash for integrity
    metadata JSONB,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_file_uploads_user ON file_uploads(user_id);
CREATE INDEX idx_file_uploads_type ON file_uploads(file_type);
CREATE INDEX idx_file_uploads_created_at ON file_uploads(created_at DESC);
```

**❌ SMS/Email Templates Table**
```sql
-- MISSING: Template management for notifications
CREATE TABLE notification_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_code VARCHAR(50) UNIQUE NOT NULL, -- 'OTP_SMS', 'WELCOME_EMAIL', etc.
    channel VARCHAR(20) NOT NULL, -- 'SMS', 'EMAIL', 'PUSH'
    subject VARCHAR(255), -- For emails
    body_template TEXT NOT NULL, -- With {{variables}}
    variables JSONB, -- List of required variables
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notification_templates_code ON notification_templates(template_code);
CREATE INDEX idx_notification_templates_channel ON notification_templates(channel);
```

**❌ Device Management Table**
```sql
-- MISSING: Track user devices for security
CREATE TABLE user_devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(255) NOT NULL,
    device_type VARCHAR(50) NOT NULL, -- 'iOS', 'Android', 'Web'
    device_name VARCHAR(255),
    device_model VARCHAR(255),
    os_version VARCHAR(50),
    app_version VARCHAR(20),
    fingerprint VARCHAR(255), -- Device fingerprint
    is_trusted BOOLEAN DEFAULT FALSE,
    last_used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, device_id)
);

CREATE INDEX idx_user_devices_user ON user_devices(user_id);
CREATE INDEX idx_user_devices_fingerprint ON user_devices(fingerprint);
```

**❌ Rate Limiting Table**
```sql
-- MISSING: API rate limiting tracking
CREATE TABLE rate_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    identifier VARCHAR(255) NOT NULL, -- user_id, ip_address, api_key
    endpoint VARCHAR(255) NOT NULL,
    request_count INT DEFAULT 1,
    window_start TIMESTAMP WITH TIME ZONE NOT NULL,
    window_end TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(identifier, endpoint, window_start)
);

CREATE INDEX idx_rate_limits_identifier ON rate_limits(identifier);
CREATE INDEX idx_rate_limits_window ON rate_limits(window_end);
```

**❌ Transaction Reversal Table**
```sql
-- MISSING: Handle transaction reversals
CREATE TABLE transaction_reversals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    original_transaction_id UUID NOT NULL REFERENCES transactions(id),
    reversal_transaction_id UUID REFERENCES transactions(id),
    reason VARCHAR(255) NOT NULL,
    initiated_by UUID REFERENCES users(id),
    approved_by UUID REFERENCES users(id),
    status VARCHAR(20) DEFAULT 'PENDING', -- 'PENDING', 'APPROVED', 'REJECTED', 'COMPLETED'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_transaction_reversals_original ON transaction_reversals(original_transaction_id);
CREATE INDEX idx_transaction_reversals_status ON transaction_reversals(status);
```

**❌ Scheduled Transactions Table**
```sql
-- MISSING: Recurring/scheduled transactions
CREATE TABLE scheduled_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type transaction_type NOT NULL,
    recipient_id UUID REFERENCES users(id),
    bill_provider_id UUID REFERENCES bill_providers(id),
    amount DECIMAL(15, 2) NOT NULL,
    frequency VARCHAR(20) NOT NULL, -- 'DAILY', 'WEEKLY', 'MONTHLY'
    next_execution_date DATE NOT NULL,
    last_execution_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_amount CHECK (amount > 0)
);

CREATE INDEX idx_scheduled_transactions_user ON scheduled_transactions(user_id);
CREATE INDEX idx_scheduled_transactions_next_date ON scheduled_transactions(next_execution_date);
```

**❌ Password History Table**
```sql
-- MISSING: Prevent password reuse
CREATE TABLE password_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_password_history_user ON password_history(user_id);
CREATE INDEX idx_password_history_created ON password_history(created_at DESC);
```

**❌ IP Blacklist/Whitelist Tables**
```sql
-- MISSING: IP access control
CREATE TABLE ip_access_control (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ip_address INET NOT NULL,
    type VARCHAR(20) NOT NULL, -- 'BLACKLIST', 'WHITELIST'
    reason TEXT,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(ip_address, type)
);

CREATE INDEX idx_ip_access_control_ip ON ip_access_control(ip_address);
CREATE INDEX idx_ip_access_control_type ON ip_access_control(type);
```

#### 1.2 Missing Business Logic Constraints

**❌ Transaction Velocity Limits**
```sql
-- MISSING in transactions table
ALTER TABLE transactions ADD COLUMN daily_count INT DEFAULT 0;
ALTER TABLE transactions ADD COLUMN daily_volume DECIMAL(15, 2) DEFAULT 0;

-- Add check constraints
ALTER TABLE transactions ADD CONSTRAINT max_daily_transactions CHECK (daily_count <= 100);
ALTER TABLE transactions ADD CONSTRAINT max_daily_volume CHECK (daily_volume <= 10000000);
```

**❌ Wallet Minimum Balance Requirements**
```sql
-- MISSING in wallets table
ALTER TABLE wallets ADD COLUMN minimum_balance DECIMAL(15, 2) DEFAULT 0;
ALTER TABLE wallets ADD CONSTRAINT minimum_balance_check CHECK (balance >= minimum_balance);
```

**❌ Agent Working Hours**
```sql
-- MISSING in agents table
ALTER TABLE agents ADD COLUMN working_hours JSONB; -- {"monday": {"start": "09:00", "end": "17:00"}}
ALTER TABLE agents ADD COLUMN is_available BOOLEAN DEFAULT FALSE;
ALTER TABLE agents ADD COLUMN max_daily_transactions INT DEFAULT 500;
ALTER TABLE agents ADD COLUMN daily_transaction_count INT DEFAULT 0;
```

#### 1.3 Missing Database Views

**❌ User Dashboard View**
```sql
-- MISSING: Optimized view for user dashboard
CREATE VIEW vw_user_dashboard AS
SELECT
    u.id,
    u.first_name,
    u.last_name,
    w.balance as wallet_balance,
    w.currency,
    COUNT(DISTINCT t.id) as total_transactions,
    COUNT(DISTINCT i.id) as active_investments,
    SUM(i.amount) as total_invested,
    u.kyc_status,
    u.is_verified
FROM users u
LEFT JOIN wallets w ON u.id = w.user_id
LEFT JOIN transactions t ON u.id = t.from_user_id OR u.id = t.to_user_id
LEFT JOIN investments i ON u.id = i.user_id AND i.status = 'ACTIVE'
GROUP BY u.id, u.first_name, u.last_name, w.balance, w.currency, u.kyc_status, u.is_verified;
```

**❌ Agent Performance View**
```sql
-- MISSING: Agent analytics view
CREATE VIEW vw_agent_performance AS
SELECT
    a.id,
    a.user_id,
    u.first_name || ' ' || u.last_name as agent_name,
    a.wallet_balance,
    a.total_commission_earned,
    COUNT(DISTINCT ac.transaction_id) as transactions_today,
    SUM(ac.commission_amount) as commission_today,
    AVG(ar.rating) as average_rating,
    COUNT(DISTINCT ar.id) as total_reviews
FROM agents a
JOIN users u ON a.user_id = u.id
LEFT JOIN agent_commissions ac ON a.id = ac.agent_id
    AND DATE(ac.created_at) = CURRENT_DATE
LEFT JOIN agent_reviews ar ON a.id = ar.agent_id
GROUP BY a.id, a.user_id, u.first_name, u.last_name, a.wallet_balance, a.total_commission_earned;
```

#### 1.4 Missing Stored Procedures

**❌ Calculate Transaction Fees**
```sql
-- MISSING: Fee calculation logic
CREATE OR REPLACE FUNCTION calculate_transaction_fee(
    p_transaction_type transaction_type,
    p_amount DECIMAL(15, 2),
    p_user_role user_role
) RETURNS DECIMAL(15, 2) AS $$
DECLARE
    v_fee_rate DECIMAL(5, 2);
    v_minimum_fee DECIMAL(15, 2);
    v_maximum_fee DECIMAL(15, 2);
    v_calculated_fee DECIMAL(15, 2);
BEGIN
    -- Get fee configuration from system_config
    SELECT
        CASE p_transaction_type
            WHEN 'WITHDRAWAL' THEN 2.0
            WHEN 'TRANSFER' THEN 1.0
            WHEN 'BILL_PAYMENT' THEN 1.5
            ELSE 0.0
        END INTO v_fee_rate;

    -- VIP users get 50% discount
    IF p_user_role = 'VIP' THEN
        v_fee_rate := v_fee_rate * 0.5;
    END IF;

    v_calculated_fee := p_amount * v_fee_rate / 100;

    -- Apply minimum and maximum limits
    v_minimum_fee := 10.00;
    v_maximum_fee := 5000.00;

    IF v_calculated_fee < v_minimum_fee THEN
        v_calculated_fee := v_minimum_fee;
    ELSIF v_calculated_fee > v_maximum_fee THEN
        v_calculated_fee := v_maximum_fee;
    END IF;

    RETURN v_calculated_fee;
END;
$$ LANGUAGE plpgsql;
```

**❌ Process Investment Maturity**
```sql
-- MISSING: Auto-process matured investments
CREATE OR REPLACE FUNCTION process_matured_investments()
RETURNS void AS $$
DECLARE
    v_investment RECORD;
BEGIN
    FOR v_investment IN
        SELECT * FROM investments
        WHERE status = 'ACTIVE'
        AND end_date <= CURRENT_DATE
    LOOP
        -- Update investment status
        UPDATE investments
        SET status = 'MATURED',
            actual_return = expected_return
        WHERE id = v_investment.id;

        -- Credit user wallet
        UPDATE wallets
        SET balance = balance + v_investment.expected_return
        WHERE user_id = v_investment.user_id;

        -- Create transaction record
        INSERT INTO transactions (
            type, to_user_id, amount, status, description
        ) VALUES (
            'INVESTMENT', v_investment.user_id,
            v_investment.expected_return, 'COMPLETED',
            'Investment maturity payout'
        );

        -- Send notification
        INSERT INTO notifications (
            user_id, type, title, message
        ) VALUES (
            v_investment.user_id, 'INVESTMENT',
            'Investment Matured',
            'Your investment has matured and funds have been credited'
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
```

#### 1.5 Missing Triggers

**❌ Audit Trigger for All Tables**
```sql
-- MISSING: Comprehensive audit trail
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(50) NOT NULL,
    operation VARCHAR(10) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    record_id UUID NOT NULL,
    old_data JSONB,
    new_data JSONB,
    changed_by UUID,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (table_name, operation, record_id, old_data, new_data, changed_by)
    VALUES (
        TG_TABLE_NAME,
        TG_OP,
        CASE
            WHEN TG_OP = 'DELETE' THEN OLD.id
            ELSE NEW.id
        END,
        CASE
            WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD)
            ELSE NULL
        END,
        CASE
            WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW)
            ELSE NULL
        END,
        current_setting('app.current_user_id', true)::UUID
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Apply to all critical tables
CREATE TRIGGER audit_users AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();
CREATE TRIGGER audit_transactions AFTER INSERT OR UPDATE OR DELETE ON transactions
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();
CREATE TRIGGER audit_wallets AFTER INSERT OR UPDATE OR DELETE ON wallets
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();
-- ... apply to all tables
```

**❌ Wallet Balance Update Trigger**
```sql
-- MISSING: Auto-update wallet on transaction completion
CREATE OR REPLACE FUNCTION update_wallet_balance()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'COMPLETED' AND OLD.status != 'COMPLETED' THEN
        -- Debit from sender
        IF NEW.from_user_id IS NOT NULL THEN
            UPDATE wallets
            SET balance = balance - (NEW.amount + NEW.fee),
                last_transaction_at = CURRENT_TIMESTAMP
            WHERE user_id = NEW.from_user_id;
        END IF;

        -- Credit to receiver
        IF NEW.to_user_id IS NOT NULL THEN
            UPDATE wallets
            SET balance = balance + NEW.amount,
                last_transaction_at = CURRENT_TIMESTAMP
            WHERE user_id = NEW.to_user_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_wallet_on_transaction
AFTER UPDATE ON transactions
FOR EACH ROW
EXECUTE FUNCTION update_wallet_balance();
```

---

### 2. API Specification Gaps

#### 2.1 Missing Endpoints

**❌ Batch Operations**
```markdown
### POST /transactions/batch
- Bulk transfer to multiple recipients
- Request: Array of transfer objects
- Response: Array of transaction results

### POST /users/batch-import
- Import multiple users (admin)
- CSV upload support
- Validation and error reporting
```

**❌ Export Endpoints**
```markdown
### GET /transactions/export
- Export transaction history
- Query params: format (CSV, PDF, Excel)
- Async processing for large exports

### GET /admin/users/export
- Export user data (GDPR compliant)
- Filtered export support
```

**❌ Health & Monitoring**
```markdown
### GET /health
- Service health check
- Database connectivity
- External service status

### GET /metrics
- API metrics (Prometheus format)
- Request counts, latencies
- Error rates
```

**❌ Transaction Management**
```markdown
### POST /transactions/:id/reverse
- Reverse a completed transaction
- Admin approval required
- Audit trail maintained

### POST /transactions/schedule
- Schedule recurring transactions
- Support for daily/weekly/monthly
- Automatic retry on failure

### GET /transactions/pending-approval
- List transactions awaiting approval
- For large amounts or suspicious activity
```

**❌ Webhook Management**
```markdown
### POST /webhooks
- Register webhook endpoints
- Event subscription management

### GET /webhooks
- List configured webhooks
- Test webhook functionality
```

#### 2.2 Missing Query Parameters

**❌ Sorting on List Endpoints**
All list endpoints are missing sorting parameters:
```
sort_by: field_name
sort_order: ASC|DESC
```

**❌ Advanced Filtering**
Missing filter operators:
```
filter[field][gte]: greater than or equal
filter[field][lte]: less than or equal
filter[field][contains]: partial match
filter[field][in]: array of values
```

**❌ Field Selection**
Missing sparse fieldsets:
```
fields: comma-separated list of fields to return
expand: comma-separated list of relations to include
```

#### 2.3 Missing Validation Rules

**❌ Phone Number Validation**
```javascript
// Missing regex patterns for Sierra Leone numbers
const SIERRA_LEONE_PHONE_REGEX = /^(\+232|232|0)?(7[0-9]|8[0-9]|3[0-9]|5[0-9])\d{7}$/;
```

**❌ Transaction Amount Validation**
```javascript
// Missing decimal place validation
const AMOUNT_REGEX = /^\d+(\.\d{1,2})?$/; // Max 2 decimal places
const MIN_AMOUNT = 0.01;
const MAX_AMOUNT = 99999999.99;
```

**❌ Password Complexity Rules**
```javascript
// Missing detailed password rules
const PASSWORD_RULES = {
    minLength: 8,
    maxLength: 128,
    requireUppercase: true,
    requireLowercase: true,
    requireNumbers: true,
    requireSpecialChars: true,
    specialChars: '!@#$%^&*()_+-=[]{}|;:,.<>?',
    preventCommonPasswords: true,
    preventUserInfo: true, // Can't contain name, email, phone
    preventRepeatingChars: true, // Max 3 repeating
    preventSequentialChars: true // No "123", "abc"
};
```

#### 2.4 Missing Error Codes

```javascript
// Missing specific error codes
const ERROR_CODES = {
    // Transaction errors
    'TXN001': 'Transaction already reversed',
    'TXN002': 'Transaction too old to reverse',
    'TXN003': 'Insufficient agent credits',
    'TXN004': 'Daily transaction limit exceeded',
    'TXN005': 'Suspicious transaction pattern detected',

    // Investment errors
    'INV001': 'Investment locked until maturity',
    'INV002': 'Early withdrawal penalty applies',
    'INV003': 'Investment category inactive',

    // Agent errors
    'AGT001': 'Agent outside working hours',
    'AGT002': 'Agent daily limit reached',
    'AGT003': 'Agent location too far from user',

    // Security errors
    'SEC001': 'Device not trusted',
    'SEC002': 'IP address blacklisted',
    'SEC003': 'Unusual activity detected',
    'SEC004': 'Session expired',
    'SEC005': 'Concurrent session detected'
};
```

---

### 3. Business Logic Gaps

#### 3.1 Missing Calculation Formulas

**❌ Investment Return Calculation**
```javascript
// MISSING: Compound interest formula
function calculateInvestmentReturn(principal, rate, months, compoundingFrequency = 12) {
    // A = P(1 + r/n)^(nt)
    const n = compoundingFrequency;
    const t = months / 12;
    const r = rate / 100;

    const amount = principal * Math.pow(1 + r/n, n * t);
    const interest = amount - principal;

    return {
        totalAmount: amount,
        interest: interest,
        effectiveRate: (interest / principal) * 100
    };
}
```

**❌ Agent Commission Calculation**
```javascript
// MISSING: Tiered commission structure
function calculateAgentCommission(transactionAmount, agentTier, monthlyVolume) {
    let baseRate = 0.5; // 0.5% base

    // Tier bonuses
    const tierBonus = {
        'BRONZE': 0,
        'SILVER': 0.1,
        'GOLD': 0.2,
        'PLATINUM': 0.3
    };

    // Volume bonuses
    let volumeBonus = 0;
    if (monthlyVolume > 10000000) volumeBonus = 0.2;
    else if (monthlyVolume > 5000000) volumeBonus = 0.1;
    else if (monthlyVolume > 1000000) volumeBonus = 0.05;

    const totalRate = baseRate + tierBonus[agentTier] + volumeBonus;
    const commission = transactionAmount * totalRate / 100;

    // Min and max limits
    const minCommission = 10;
    const maxCommission = 5000;

    return Math.min(Math.max(commission, minCommission), maxCommission);
}
```

**❌ Transaction Limit Calculation**
```javascript
// MISSING: Dynamic limits based on user profile
function calculateTransactionLimits(user) {
    const baseLimits = {
        daily: 1000000,
        weekly: 5000000,
        monthly: 20000000
    };

    // KYC multipliers
    const kycMultiplier = {
        'PENDING': 0.1,
        'SUBMITTED': 0.5,
        'APPROVED': 1.0,
        'VERIFIED': 1.5  // Additional verification
    };

    // Account age bonus
    const accountAgeMonths = calculateAccountAge(user.createdAt);
    const ageMultiplier = Math.min(1 + (accountAgeMonths * 0.05), 2); // Max 2x

    // Transaction history bonus
    const historyMultiplier = user.successfulTransactions > 100 ? 1.2 : 1.0;

    const finalMultiplier = kycMultiplier[user.kycStatus] * ageMultiplier * historyMultiplier;

    return {
        daily: baseLimits.daily * finalMultiplier,
        weekly: baseLimits.weekly * finalMultiplier,
        monthly: baseLimits.monthly * finalMultiplier
    };
}
```

#### 3.2 Missing State Machines

**❌ Transaction State Machine**
```javascript
// MISSING: Complete state transitions
const TransactionStateMachine = {
    INITIATED: {
        nextStates: ['PENDING', 'FAILED'],
        actions: ['validate', 'checkBalance']
    },
    PENDING: {
        nextStates: ['PROCESSING', 'FAILED', 'CANCELLED'],
        actions: ['approve', 'timeout']
    },
    PROCESSING: {
        nextStates: ['COMPLETED', 'FAILED', 'REVERSED'],
        actions: ['execute', 'rollback']
    },
    COMPLETED: {
        nextStates: ['REVERSED'],
        actions: ['reverse']
    },
    FAILED: {
        nextStates: ['PENDING'], // Retry
        actions: ['retry', 'notify']
    },
    CANCELLED: {
        nextStates: [],
        actions: ['notify']
    },
    REVERSED: {
        nextStates: [],
        actions: ['refund', 'notify']
    }
};
```

**❌ KYC State Machine**
```javascript
const KYCStateMachine = {
    NOT_STARTED: {
        nextStates: ['DOCUMENT_UPLOAD'],
        requiredFields: []
    },
    DOCUMENT_UPLOAD: {
        nextStates: ['SELFIE_VERIFICATION', 'REJECTED'],
        requiredFields: ['documentType', 'documentNumber', 'frontImage', 'backImage']
    },
    SELFIE_VERIFICATION: {
        nextStates: ['SUBMITTED', 'REJECTED'],
        requiredFields: ['selfieImage']
    },
    SUBMITTED: {
        nextStates: ['UNDER_REVIEW', 'AUTO_REJECTED'],
        autoTransition: true
    },
    UNDER_REVIEW: {
        nextStates: ['APPROVED', 'REJECTED', 'ADDITIONAL_INFO_REQUIRED'],
        requiresAdmin: true
    },
    ADDITIONAL_INFO_REQUIRED: {
        nextStates: ['SUBMITTED', 'REJECTED'],
        requiredFields: ['additionalDocuments']
    },
    APPROVED: {
        nextStates: ['EXPIRED', 'REVOKED'],
        validityPeriod: 365 * 24 * 60 * 60 * 1000 // 1 year
    },
    REJECTED: {
        nextStates: ['DOCUMENT_UPLOAD'],
        cooldownPeriod: 24 * 60 * 60 * 1000 // 24 hours
    }
};
```

---

### 4. Security Gaps

#### 4.1 Missing Security Headers

**❌ API Response Headers**
```javascript
// MISSING in API specification
const SECURITY_HEADERS = {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'X-XSS-Protection': '1; mode=block',
    'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
    'Content-Security-Policy': "default-src 'self'",
    'Referrer-Policy': 'strict-origin-when-cross-origin',
    'Permissions-Policy': 'geolocation=(), microphone=(), camera=()',
    'X-Request-ID': '{unique-request-id}',
    'X-RateLimit-Limit': '{rate-limit}',
    'X-RateLimit-Remaining': '{remaining}',
    'X-RateLimit-Reset': '{reset-timestamp}'
};
```

#### 4.2 Missing Encryption Specifications

**❌ Field-Level Encryption**
```javascript
// MISSING: Which fields need encryption at rest
const ENCRYPTED_FIELDS = {
    users: ['password_hash', 'two_factor_secret'],
    bank_accounts: ['account_number', 'routing_number'],
    kyc_documents: ['document_number'],
    api_keys: ['key_hash'],
    transactions: ['metadata.sensitive_data']
};
```

**❌ Encryption Key Management**
```javascript
// MISSING: Key rotation strategy
const KEY_MANAGEMENT = {
    masterKeyLocation: 'AWS_KMS',
    dataKeys: {
        rotation: 'quarterly',
        algorithm: 'AES-256-GCM',
        keyDerivation: 'PBKDF2'
    },
    backup: {
        location: 'AWS_S3_GLACIER',
        encryption: 'client-side',
        retention: '7 years'
    }
};
```

#### 4.3 Missing Fraud Detection Rules

**❌ Suspicious Pattern Detection**
```javascript
// MISSING: Fraud detection patterns
const FRAUD_PATTERNS = {
    velocityChecks: {
        maxTransactionsPerMinute: 5,
        maxTransactionsPerHour: 20,
        maxAmountPerDay: 10000000
    },

    locationChecks: {
        maxDistancePerHour: 500, // km
        requireLocationConsistency: true
    },

    behaviorChecks: {
        unusualAmount: 'amount > avgAmount * 10',
        unusualTime: 'hour < 6 OR hour > 23',
        unusualRecipient: 'first_time_recipient AND amount > 100000',
        rapidsuccession: 'time_since_last < 30 seconds'
    },

    deviceChecks: {
        maxDevicesPerUser: 5,
        requireTrustedDevice: 'amount > 500000',
        blockRootedDevices: true,
        blockEmulators: true
    }
};
```

---

### 5. Design System Gaps

#### 5.1 Missing Component States

**❌ Error States**
```css
/* MISSING: Error state specifications */
.input-error {
    border: 2px solid #FF5757;
    background: #FFF5F5;
}

.card-error {
    border: 1px solid #FF5757;
    background: linear-gradient(135deg, #FFF5F5 0%, #FFE5E5 100%);
}

.button-error {
    background: #FF5757;
    box-shadow: 0 4px 12px rgba(255, 87, 87, 0.3);
}
```

**❌ Loading States**
```css
/* MISSING: Skeleton loaders for all components */
.skeleton-text {
    background: linear-gradient(90deg, #F3F4F6 0%, #E5E7EB 50%, #F3F4F6 100%);
    background-size: 200% 100%;
    animation: shimmer 1.5s infinite;
}

.skeleton-card {
    background: linear-gradient(90deg, #F9FAFB 0%, #F3F4F6 50%, #F9FAFB 100%);
    border-radius: 16px;
    animation: pulse 2s infinite;
}
```

**❌ Empty States**
```typescript
// MISSING: Empty state components
interface EmptyStateProps {
    icon: string;
    title: string;
    description: string;
    action?: {
        label: string;
        onClick: () => void;
    };
}

const emptyStates = {
    noTransactions: {
        icon: 'receipt',
        title: 'No transactions yet',
        description: 'Your transaction history will appear here',
        action: { label: 'Make a deposit', onClick: navigateToDeposit }
    },
    noInvestments: {
        icon: 'trending-up',
        title: 'No investments',
        description: 'Start investing to grow your wealth',
        action: { label: 'Explore investments', onClick: navigateToInvestments }
    }
};
```

#### 5.2 Missing Accessibility Specs

**❌ ARIA Labels**
```html
<!-- MISSING: Accessibility attributes -->
<button
    aria-label="Send money to another user"
    aria-describedby="transfer-help-text"
    role="button"
    tabindex="0">
    Transfer
</button>

<input
    aria-label="Enter amount in Leones"
    aria-invalid="true"
    aria-errormessage="amount-error"
    role="textbox"
    inputmode="decimal"
/>
```

**❌ Focus States**
```css
/* MISSING: Focus indicators */
:focus-visible {
    outline: 2px solid #5B6EF5;
    outline-offset: 2px;
}

.button:focus-visible {
    box-shadow: 0 0 0 3px rgba(91, 110, 245, 0.5);
}

.input:focus-visible {
    border-color: #5B6EF5;
    box-shadow: 0 0 0 3px rgba(91, 110, 245, 0.1);
}
```

#### 5.3 Missing Animation Specifications

**❌ Transition Timings**
```css
/* MISSING: Animation details */
:root {
    --transition-fast: 150ms cubic-bezier(0.4, 0, 0.2, 1);
    --transition-base: 250ms cubic-bezier(0.4, 0, 0.2, 1);
    --transition-slow: 350ms cubic-bezier(0.4, 0, 0.2, 1);
    --transition-slower: 500ms cubic-bezier(0.4, 0, 0.2, 1);
}

/* Page transitions */
.page-enter {
    opacity: 0;
    transform: translateX(20px);
}

.page-enter-active {
    opacity: 1;
    transform: translateX(0);
    transition: var(--transition-base);
}
```

**❌ Micro-interactions**
```javascript
// MISSING: Interaction feedback
const microInteractions = {
    buttonPress: {
        scale: 0.98,
        duration: 100
    },
    cardHover: {
        translateY: -2,
        shadow: '0 8px 16px rgba(0,0,0,0.1)',
        duration: 200
    },
    inputFocus: {
        borderWidth: 2,
        backgroundColor: '#FFFFFF',
        duration: 150
    }
};
```

---

### 6. Infrastructure & DevOps Gaps

#### 6.1 Missing Caching Strategy

**❌ Redis Cache Keys**
```javascript
// MISSING: Cache key patterns
const CACHE_KEYS = {
    userProfile: 'user:{userId}:profile',
    userWallet: 'user:{userId}:wallet',
    transactionHistory: 'user:{userId}:transactions:{page}',
    exchangeRates: 'rates:{currency}:{date}',
    systemConfig: 'config:{key}',
    agentLocation: 'agent:{agentId}:location',
    otpCode: 'otp:{phone}:{purpose}'
};

const CACHE_TTL = {
    userProfile: 300, // 5 minutes
    userWallet: 60, // 1 minute
    transactionHistory: 180, // 3 minutes
    exchangeRates: 3600, // 1 hour
    systemConfig: 86400, // 24 hours
    agentLocation: 120, // 2 minutes
    otpCode: 300 // 5 minutes
};
```

#### 6.2 Missing Queue/Job Specifications

**❌ Background Jobs**
```javascript
// MISSING: Job queue definitions
const JOB_QUEUES = {
    'email': {
        concurrency: 10,
        rateLimit: { max: 100, duration: 60000 },
        retries: 3
    },
    'sms': {
        concurrency: 20,
        rateLimit: { max: 200, duration: 60000 },
        retries: 5
    },
    'notifications': {
        concurrency: 50,
        priority: true
    },
    'reports': {
        concurrency: 2,
        timeout: 300000 // 5 minutes
    },
    'kyc-verification': {
        concurrency: 5,
        retries: 1
    }
};
```

#### 6.3 Missing Monitoring Metrics

**❌ Application Metrics**
```javascript
// MISSING: What to monitor
const METRICS = {
    business: {
        'total_users': 'gauge',
        'active_users_daily': 'gauge',
        'transaction_volume': 'counter',
        'transaction_count': 'counter',
        'failed_transactions': 'counter',
        'wallet_balance_total': 'gauge',
        'investment_total': 'gauge'
    },

    technical: {
        'api_request_duration': 'histogram',
        'api_request_count': 'counter',
        'api_error_count': 'counter',
        'database_query_duration': 'histogram',
        'cache_hit_rate': 'gauge',
        'queue_size': 'gauge',
        'job_processing_time': 'histogram'
    },

    security: {
        'failed_login_attempts': 'counter',
        'suspicious_transactions': 'counter',
        'blocked_ips': 'gauge',
        'active_sessions': 'gauge'
    }
};
```

---

### 7. Testing Gaps

#### 7.1 Missing Test Data Generators

**❌ Factory Functions**
```javascript
// MISSING: Test data factories
const factories = {
    user: (overrides = {}) => ({
        id: faker.datatype.uuid(),
        firstName: faker.name.firstName(),
        lastName: faker.name.lastName(),
        email: faker.internet.email(),
        phone: faker.phone.number('7########'),
        countryCode: '+232',
        kycStatus: faker.random.arrayElement(['PENDING', 'APPROVED', 'REJECTED']),
        ...overrides
    }),

    transaction: (overrides = {}) => ({
        id: faker.datatype.uuid(),
        transactionId: `TXN${faker.date.recent().toISOString().slice(0,10).replace(/-/g,'')}${faker.random.numeric(6)}`,
        type: faker.random.arrayElement(['DEPOSIT', 'WITHDRAWAL', 'TRANSFER']),
        amount: faker.finance.amount(100, 100000),
        status: faker.random.arrayElement(['PENDING', 'COMPLETED', 'FAILED']),
        ...overrides
    })
};
```

#### 7.2 Missing Integration Test Scenarios

**❌ End-to-End Test Flows**
```javascript
// MISSING: Complete user journeys
const E2E_SCENARIOS = [
    'New user registration → KYC → First deposit → Transfer → Withdrawal',
    'Agent registration → Credit request → User deposit → Commission payout',
    'Investment creation → Tenure change → Maturity → Withdrawal',
    'Bill payment → Failed → Retry → Success',
    'Suspicious transaction → Admin review → Approval/Rejection'
];
```

---

## Summary of Critical Gaps

### Database Layer
- **8 missing tables** (file uploads, templates, devices, etc.)
- **5 missing views** for performance optimization
- **4 missing stored procedures** for complex business logic
- **10+ missing triggers** for automation
- **No partitioning strategy** for large tables
- **No archival strategy** for old data

### API Layer
- **15+ missing endpoints** (batch, export, health, webhooks)
- **Missing query parameters** (sorting, filtering, field selection)
- **30+ missing error codes** for specific scenarios
- **Missing WebSocket event specifications**
- **No API versioning strategy**

### Business Logic
- **Missing calculation formulas** (interest, commission, limits)
- **Missing state machines** for workflows
- **No fraud detection rules**
- **No transaction reversal logic**
- **No scheduled transaction support**

### Security
- **Missing encryption specifications**
- **No key management strategy**
- **Missing security headers**
- **No device fingerprinting details**
- **No session management strategy**

### Frontend
- **Missing component states** (error, loading, empty)
- **No accessibility specifications**
- **Missing animation details**
- **No micro-interaction definitions**
- **Incomplete responsive design specs**

### Infrastructure
- **No caching strategy**
- **Missing queue/job specifications**
- **No monitoring metrics defined**
- **Missing deployment configuration**
- **No scaling strategy**

---

## Recommendations

### Priority 1: Critical for MVP
1. Add file uploads table and management
2. Implement transaction fee calculation logic
3. Add wallet balance update triggers
4. Define fraud detection rules
5. Add security headers specification
6. Implement proper error states in design

### Priority 2: Important for Production
1. Add audit logging for all tables
2. Implement caching strategy
3. Add monitoring metrics
4. Create test data generators
5. Define state machines for workflows

### Priority 3: Nice to Have
1. Add batch operation endpoints
2. Implement export functionality
3. Add webhook management
4. Create database views for performance
5. Add animation specifications

---

## Conclusion

While the current documentation is comprehensive at a high level, it lacks many Low-Level Design details necessary for implementation. The gaps identified above need to be addressed before development begins to avoid:

1. **Security vulnerabilities** (missing encryption, fraud detection)
2. **Performance issues** (no caching, missing indexes)
3. **Business logic errors** (undefined calculations, state transitions)
4. **Poor user experience** (missing error states, accessibility)
5. **Operational challenges** (no monitoring, logging)

**Recommendation:** Address Priority 1 gaps immediately before starting development, implement Priority 2 during development, and plan Priority 3 for post-MVP iterations.

---

**Document Status:** ⚠️ **REQUIRES UPDATES**
**LLD Completeness:** 65%
**Production Readiness:** Not Ready
