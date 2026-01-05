--
-- PostgreSQL database dump
--

\restrict 7ubOiXdiHcI1vudSmRxIC07jmv1cu0gIN62jrkfv3fOpgNOiexUBamGXgSpW4bN

-- Dumped from database version 14.20 (Homebrew)
-- Dumped by pg_dump version 14.20 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: bill_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.bill_type AS ENUM (
    'WATER',
    'ELECTRICITY',
    'DSTV',
    'INTERNET',
    'MOBILE',
    'OTHER'
);


--
-- Name: deposit_source; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.deposit_source AS ENUM (
    'BANK_DEPOSIT',
    'AGENT',
    'AIRTEL_MONEY',
    'INTERNET_BANKING',
    'ORANGE_MONEY'
);


--
-- Name: document_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.document_type AS ENUM (
    'NATIONAL_ID',
    'PASSPORT',
    'DRIVERS_LICENSE',
    'VOTER_CARD',
    'BANK_RECEIPT',
    'AGREEMENT',
    'INSURANCE_POLICY'
);


--
-- Name: investment_category; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.investment_category AS ENUM (
    'AGRICULTURE',
    'EDUCATION',
    'MINERALS'
);


--
-- Name: investment_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.investment_status AS ENUM (
    'ACTIVE',
    'MATURED',
    'WITHDRAWN',
    'CANCELLED'
);


--
-- Name: kyc_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.kyc_status AS ENUM (
    'PENDING',
    'SUBMITTED',
    'APPROVED',
    'REJECTED'
);


--
-- Name: notification_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.notification_type AS ENUM (
    'DEPOSIT',
    'WITHDRAWAL',
    'TRANSFER',
    'BILL_PAYMENT',
    'INVESTMENT',
    'KYC',
    'SECURITY',
    'ANNOUNCEMENT',
    'VOTE'
);


--
-- Name: payment_method; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.payment_method AS ENUM (
    'BANK_TRANSFER',
    'MOBILE_MONEY',
    'AGENT',
    'BANK_RECEIPT'
);


--
-- Name: poll_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.poll_status AS ENUM (
    'DRAFT',
    'ACTIVE',
    'PAUSED',
    'CLOSED'
);


--
-- Name: transaction_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.transaction_status AS ENUM (
    'PENDING',
    'PROCESSING',
    'COMPLETED',
    'FAILED',
    'CANCELLED'
);


--
-- Name: transaction_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.transaction_type AS ENUM (
    'DEPOSIT',
    'WITHDRAWAL',
    'TRANSFER',
    'BILL_PAYMENT',
    'INVESTMENT',
    'VOTE',
    'COMMISSION',
    'AGENT_CREDIT'
);


--
-- Name: user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_role AS ENUM (
    'USER',
    'AGENT',
    'ADMIN',
    'SUPER_ADMIN'
);


--
-- Name: audit_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.audit_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_old_data JSONB;
    v_new_data JSONB;
    v_changed_fields TEXT[];
BEGIN
    -- Prepare old and new data
    IF TG_OP = 'DELETE' THEN
        v_old_data := to_jsonb(OLD);
        v_new_data := NULL;
    ELSIF TG_OP = 'UPDATE' THEN
        v_old_data := to_jsonb(OLD);
        v_new_data := to_jsonb(NEW);
        -- Calculate changed fields
        SELECT ARRAY_AGG(key) INTO v_changed_fields
        FROM jsonb_each(v_old_data) o
        FULL OUTER JOIN jsonb_each(v_new_data) n USING (key)
        WHERE o.value IS DISTINCT FROM n.value;
    ELSE -- INSERT
        v_old_data := NULL;
        v_new_data := to_jsonb(NEW);
    END IF;

    -- Insert audit log
    INSERT INTO audit_log (
        table_name, operation, record_id, user_id,
        old_data, new_data, changed_fields, ip_address
    ) VALUES (
        TG_TABLE_NAME,
        TG_OP,
        CASE
            WHEN TG_OP = 'DELETE' THEN OLD.id
            ELSE NEW.id
        END,
        current_setting('app.current_user_id', true)::UUID,
        v_old_data,
        v_new_data,
        v_changed_fields,
        current_setting('app.client_ip', true)::INET
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;


--
-- Name: auto_end_elections(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.auto_end_elections() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE elections
    SET status = 'ended',
        ended_at = CURRENT_TIMESTAMP
    WHERE status = 'active'
    AND end_time <= CURRENT_TIMESTAMP;
END;
$$;


--
-- Name: calculate_agent_commission(numeric, uuid, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_agent_commission(p_transaction_amount numeric, p_agent_id uuid, p_transaction_type character varying) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_base_rate DECIMAL(5, 2) := 0.5;
    v_tier_bonus DECIMAL(5, 2) := 0;
    v_volume_bonus DECIMAL(5, 2) := 0;
    v_total_rate DECIMAL(5, 2);
    v_commission DECIMAL(15, 2);
    v_monthly_volume DECIMAL(15, 2);
    v_agent_rating DECIMAL(3, 2);
BEGIN
    -- Get agent's monthly volume
    SELECT COALESCE(SUM(commission_amount), 0) INTO v_monthly_volume
    FROM agent_commissions
    WHERE agent_id = p_agent_id
    AND created_at >= DATE_TRUNC('month', CURRENT_DATE);

    -- Get agent's average rating
    SELECT AVG(rating) INTO v_agent_rating
    FROM agent_reviews
    WHERE agent_id = p_agent_id;

    -- Volume-based tier bonus
    IF v_monthly_volume > 100000 THEN
        v_tier_bonus := 0.3; -- Platinum tier
    ELSIF v_monthly_volume > 50000 THEN
        v_tier_bonus := 0.2; -- Gold tier
    ELSIF v_monthly_volume > 20000 THEN
        v_tier_bonus := 0.1; -- Silver tier
    ELSE
        v_tier_bonus := 0; -- Bronze tier
    END IF;

    -- Rating bonus
    IF v_agent_rating >= 4.5 THEN
        v_volume_bonus := v_volume_bonus + 0.1;
    END IF;

    -- Transaction type bonus
    IF p_transaction_type = 'DEPOSIT' THEN
        v_base_rate := v_base_rate + 0.1; -- Higher rate for deposits
    END IF;

    -- Calculate total rate
    v_total_rate := v_base_rate + v_tier_bonus + v_volume_bonus;

    -- Calculate commission
    v_commission := p_transaction_amount * v_total_rate / 100;

    -- Apply min/max limits
    IF v_commission < 10 THEN
        v_commission := 10; -- Minimum commission
    ELSIF v_commission > 5000 THEN
        v_commission := 5000; -- Maximum commission
    END IF;

    RETURN v_commission;
END;
$$;


--
-- Name: calculate_transaction_fee(public.transaction_type, numeric, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_transaction_fee(p_transaction_type public.transaction_type, p_amount numeric, p_user_id uuid) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_fee_rate DECIMAL(5, 2);
    v_minimum_fee DECIMAL(15, 2);
    v_maximum_fee DECIMAL(15, 2);
    v_calculated_fee DECIMAL(15, 2);
    v_user_kyc_status kyc_status;
    v_user_role user_role;
    v_monthly_volume DECIMAL(15, 2);
BEGIN
    -- Get user details
    SELECT kyc_status, role INTO v_user_kyc_status, v_user_role
    FROM users WHERE id = p_user_id;

    -- Get monthly volume for volume discounts
    SELECT COALESCE(SUM(amount), 0) INTO v_monthly_volume
    FROM transactions
    WHERE from_user_id = p_user_id
    AND created_at >= DATE_TRUNC('month', CURRENT_DATE)
    AND status = 'COMPLETED';

    -- Base fee rates by transaction type
    v_fee_rate := CASE p_transaction_type
        WHEN 'WITHDRAWAL' THEN 2.0
        WHEN 'TRANSFER' THEN 1.0
        WHEN 'BILL_PAYMENT' THEN 1.5
        WHEN 'DEPOSIT' THEN 0.0
        ELSE 0.5
    END;

    -- Apply KYC discount
    IF v_user_kyc_status = 'APPROVED' THEN
        v_fee_rate := v_fee_rate * 0.9; -- 10% discount for KYC approved
    END IF;

    -- Apply volume discount
    IF v_monthly_volume > 10000000 THEN
        v_fee_rate := v_fee_rate * 0.7; -- 30% discount for high volume
    ELSIF v_monthly_volume > 5000000 THEN
        v_fee_rate := v_fee_rate * 0.85; -- 15% discount
    ELSIF v_monthly_volume > 1000000 THEN
        v_fee_rate := v_fee_rate * 0.95; -- 5% discount
    END IF;

    -- Calculate fee
    v_calculated_fee := p_amount * v_fee_rate / 100;

    -- Apply minimum and maximum limits
    v_minimum_fee := CASE p_transaction_type
        WHEN 'WITHDRAWAL' THEN 50.00
        WHEN 'TRANSFER' THEN 10.00
        WHEN 'BILL_PAYMENT' THEN 25.00
        ELSE 0.00
    END;

    v_maximum_fee := CASE p_transaction_type
        WHEN 'WITHDRAWAL' THEN 5000.00
        WHEN 'TRANSFER' THEN 2000.00
        WHEN 'BILL_PAYMENT' THEN 1000.00
        ELSE 500.00
    END;

    -- Apply limits
    IF v_calculated_fee < v_minimum_fee THEN
        v_calculated_fee := v_minimum_fee;
    ELSIF v_calculated_fee > v_maximum_fee THEN
        v_calculated_fee := v_maximum_fee;
    END IF;

    RETURN v_calculated_fee;
END;
$$;


--
-- Name: check_transaction_velocity(uuid, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_transaction_velocity(p_user_id uuid, p_amount numeric) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_count_1min INT;
    v_count_1hour INT;
    v_count_1day INT;
    v_sum_1day DECIMAL(15, 2);
    v_risk_score INT := 0;
BEGIN
    -- Count transactions in last minute
    SELECT COUNT(*) INTO v_count_1min
    FROM transactions
    WHERE from_user_id = p_user_id
    AND created_at >= CURRENT_TIMESTAMP - INTERVAL '1 minute';

    -- Count transactions in last hour
    SELECT COUNT(*) INTO v_count_1hour
    FROM transactions
    WHERE from_user_id = p_user_id
    AND created_at >= CURRENT_TIMESTAMP - INTERVAL '1 hour';

    -- Count and sum transactions in last day
    SELECT COUNT(*), COALESCE(SUM(amount), 0)
    INTO v_count_1day, v_sum_1day
    FROM transactions
    WHERE from_user_id = p_user_id
    AND created_at >= CURRENT_TIMESTAMP - INTERVAL '1 day';

    -- Check velocity limits
    IF v_count_1min > 3 THEN
        v_risk_score := v_risk_score + 50;
    END IF;

    IF v_count_1hour > 20 THEN
        v_risk_score := v_risk_score + 30;
    END IF;

    IF v_count_1day > 50 THEN
        v_risk_score := v_risk_score + 20;
    END IF;

    IF v_sum_1day + p_amount > 10000000 THEN
        v_risk_score := v_risk_score + 40;
    END IF;

    -- Log if suspicious
    IF v_risk_score > 50 THEN
        INSERT INTO fraud_detection_logs (
            user_id, detection_type, risk_score, details, action_taken
        ) VALUES (
            p_user_id, 'VELOCITY', v_risk_score,
            jsonb_build_object(
                'count_1min', v_count_1min,
                'count_1hour', v_count_1hour,
                'count_1day', v_count_1day,
                'sum_1day', v_sum_1day,
                'current_amount', p_amount
            ),
            CASE WHEN v_risk_score > 80 THEN 'BLOCKED' ELSE 'FLAGGED' END
        );

        RETURN FALSE; -- Transaction should be blocked or flagged
    END IF;

    RETURN TRUE; -- Transaction is safe
END;
$$;


--
-- Name: cleanup_expired_metal_prices(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cleanup_expired_metal_prices() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_deleted_count INT;
BEGIN
    -- Delete cache entries that have been expired for more than 7 days
    DELETE FROM metal_price_cache
    WHERE expires_at < CURRENT_TIMESTAMP - INTERVAL '7 days';

    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;

    RETURN v_deleted_count;
END;
$$;


--
-- Name: FUNCTION cleanup_expired_metal_prices(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.cleanup_expired_metal_prices() IS 'Remove cache entries that have been expired for more than 7 days';


--
-- Name: generate_ticket_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_ticket_id() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_id TEXT;
BEGIN
    new_id := 'TCC' || LPAD(FLOOR(RANDOM() * 99999)::TEXT, 5, '0');
    RETURN new_id;
END;
$$;


--
-- Name: generate_transaction_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_transaction_id() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_id TEXT;
BEGIN
    new_id := 'TXN' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || LPAD(FLOOR(RANDOM() * 999999)::TEXT, 6, '0');
    RETURN new_id;
END;
$$;


--
-- Name: get_cached_metal_price(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_cached_metal_price(p_metal_symbol character varying, p_base_currency character varying) RETURNS TABLE(id uuid, metal_symbol character varying, base_currency character varying, price_per_ounce numeric, price_per_gram numeric, price_per_kilogram numeric, api_timestamp bigint, cached_at timestamp with time zone, expires_at timestamp with time zone, is_expired boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        mpc.id,
        mpc.metal_symbol,
        mpc.base_currency,
        mpc.price_per_ounce,
        mpc.price_per_gram,
        mpc.price_per_kilogram,
        mpc.api_timestamp,
        mpc.cached_at,
        mpc.expires_at,
        CURRENT_TIMESTAMP > mpc.expires_at AS is_expired
    FROM metal_price_cache mpc
    WHERE mpc.metal_symbol = p_metal_symbol
      AND mpc.base_currency = p_base_currency
    ORDER BY mpc.cached_at DESC
    LIMIT 1;
END;
$$;


--
-- Name: FUNCTION get_cached_metal_price(p_metal_symbol character varying, p_base_currency character varying); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.get_cached_metal_price(p_metal_symbol character varying, p_base_currency character varying) IS 'Get a cached metal price if it exists';


--
-- Name: process_matured_investments(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.process_matured_investments() RETURNS TABLE(processed_count integer, total_amount numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_investment RECORD;
    v_count INT := 0;
    v_total DECIMAL(15, 2) := 0;
    v_transaction_id UUID;
BEGIN
    FOR v_investment IN
        SELECT * FROM investments
        WHERE status = 'ACTIVE'
        AND end_date <= CURRENT_DATE
    LOOP
        -- Create credit transaction
        v_transaction_id := uuid_generate_v4();

        INSERT INTO transactions (
            id, type, to_user_id, amount, fee, net_amount, status, description
        ) VALUES (
            v_transaction_id,
            'INVESTMENT',
            v_investment.user_id,
            v_investment.expected_return,
            0,
            v_investment.expected_return,
            'COMPLETED',
            'Investment maturity payout - ' || v_investment.category
        );

        -- Update investment status
        UPDATE investments
        SET status = 'MATURED',
            actual_return = expected_return,
            withdrawal_transaction_id = v_transaction_id,
            withdrawn_at = CURRENT_TIMESTAMP
        WHERE id = v_investment.id;

        -- Update wallet balance
        UPDATE wallets
        SET balance = balance + v_investment.expected_return,
            last_transaction_at = CURRENT_TIMESTAMP
        WHERE user_id = v_investment.user_id;

        -- Create notification
        INSERT INTO notifications (
            user_id, type, title, message, data
        ) VALUES (
            v_investment.user_id,
            'INVESTMENT',
            'Investment Matured!',
            'Your ' || v_investment.category || ' investment of ' ||
            v_investment.amount || ' has matured. ' ||
            v_investment.expected_return || ' has been credited to your wallet.',
            jsonb_build_object(
                'investment_id', v_investment.id,
                'amount', v_investment.amount,
                'return', v_investment.expected_return
            )
        );

        v_count := v_count + 1;
        v_total := v_total + v_investment.expected_return;
    END LOOP;

    RETURN QUERY SELECT v_count, v_total;
END;
$$;


--
-- Name: reset_transaction_limits(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reset_transaction_limits() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Reset daily limits
    UPDATE user_transaction_limits
    SET current_value = 0,
        reset_at = CURRENT_TIMESTAMP + INTERVAL '1 day'
    WHERE limit_type LIKE 'DAILY_%'
    AND reset_at <= CURRENT_TIMESTAMP;

    -- Reset monthly limits
    UPDATE user_transaction_limits
    SET current_value = 0,
        reset_at = DATE_TRUNC('month', CURRENT_TIMESTAMP) + INTERVAL '1 month'
    WHERE limit_type LIKE 'MONTHLY_%'
    AND reset_at <= CURRENT_TIMESTAMP;
END;
$$;


--
-- Name: save_password_history(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.save_password_history() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_password_reuse_count INT := 5; -- Last 5 passwords cannot be reused
BEGIN
    IF NEW.password_hash IS DISTINCT FROM OLD.password_hash THEN
        -- Check if password was used before
        IF EXISTS (
            SELECT 1 FROM password_history
            WHERE user_id = NEW.id
            AND password_hash = NEW.password_hash
            ORDER BY created_at DESC
            LIMIT v_password_reuse_count
        ) THEN
            RAISE EXCEPTION 'Password has been used recently. Please choose a different password.';
        END IF;

        -- Save to history
        INSERT INTO password_history (user_id, password_hash)
        VALUES (NEW.id, NEW.password_hash);

        -- Clean old history (keep only last 10)
        DELETE FROM password_history
        WHERE user_id = NEW.id
        AND id NOT IN (
            SELECT id FROM password_history
            WHERE user_id = NEW.id
            ORDER BY created_at DESC
            LIMIT 10
        );
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: set_ticket_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_ticket_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.ticket_id IS NULL THEN
        NEW.ticket_id := generate_ticket_id();
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: set_transaction_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_transaction_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.transaction_id IS NULL THEN
        NEW.transaction_id := generate_transaction_id();
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: update_election_stats(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_election_stats() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update option vote count
    UPDATE election_options
    SET vote_count = vote_count + 1
    WHERE id = NEW.option_id;

    -- Update election total votes and revenue
    UPDATE elections
    SET total_votes = total_votes + 1,
        total_revenue = total_revenue + NEW.vote_charge
    WHERE id = NEW.election_id;

    RETURN NEW;
END;
$$;


--
-- Name: update_metal_price_cache_timestamp(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_metal_price_cache_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


--
-- Name: update_wallet_balance(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_wallet_balance() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_sender_balance DECIMAL(15, 2);
    v_receiver_balance DECIMAL(15, 2);
BEGIN
    -- Only process when transaction becomes completed
    IF NEW.status = 'COMPLETED' AND OLD.status != 'COMPLETED' THEN

        -- Start atomic transaction
        IF NEW.from_user_id IS NOT NULL THEN
            -- Lock sender wallet and check balance
            SELECT balance INTO v_sender_balance
            FROM wallets
            WHERE user_id = NEW.from_user_id
            FOR UPDATE;

            -- Verify sufficient balance
            IF v_sender_balance < (NEW.amount + NEW.fee) THEN
                RAISE EXCEPTION 'Insufficient balance for transaction';
            END IF;

            -- Debit sender
            UPDATE wallets
            SET balance = balance - (NEW.amount + NEW.fee),
                last_transaction_at = CURRENT_TIMESTAMP
            WHERE user_id = NEW.from_user_id;
        END IF;

        -- Credit receiver
        IF NEW.to_user_id IS NOT NULL THEN
            UPDATE wallets
            SET balance = balance + NEW.amount,
                last_transaction_at = CURRENT_TIMESTAMP
            WHERE user_id = NEW.to_user_id;
        END IF;

        -- Update transaction limits
        UPDATE user_transaction_limits
        SET current_value = current_value + NEW.amount,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = NEW.from_user_id
        AND limit_type = 'DAILY_VOLUME'
        AND reset_at > CURRENT_TIMESTAMP;

    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: upsert_metal_price(character varying, character varying, numeric, numeric, numeric, bigint, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.upsert_metal_price(p_metal_symbol character varying, p_base_currency character varying, p_price_per_ounce numeric, p_price_per_gram numeric, p_price_per_kilogram numeric, p_api_timestamp bigint, p_ttl_seconds integer DEFAULT 86400) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id UUID;
    v_expires_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Calculate expiration time
    v_expires_at := CURRENT_TIMESTAMP + (p_ttl_seconds || ' seconds')::INTERVAL;

    -- Insert or update the cache entry
    INSERT INTO metal_price_cache (
        metal_symbol,
        base_currency,
        price_per_ounce,
        price_per_gram,
        price_per_kilogram,
        api_timestamp,
        cached_at,
        expires_at
    ) VALUES (
        p_metal_symbol,
        p_base_currency,
        p_price_per_ounce,
        p_price_per_gram,
        p_price_per_kilogram,
        p_api_timestamp,
        CURRENT_TIMESTAMP,
        v_expires_at
    )
    ON CONFLICT (metal_symbol, base_currency)
    DO UPDATE SET
        price_per_ounce = EXCLUDED.price_per_ounce,
        price_per_gram = EXCLUDED.price_per_gram,
        price_per_kilogram = EXCLUDED.price_per_kilogram,
        api_timestamp = EXCLUDED.api_timestamp,
        cached_at = CURRENT_TIMESTAMP,
        expires_at = v_expires_at,
        updated_at = CURRENT_TIMESTAMP
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$;


--
-- Name: FUNCTION upsert_metal_price(p_metal_symbol character varying, p_base_currency character varying, p_price_per_ounce numeric, p_price_per_gram numeric, p_price_per_kilogram numeric, p_api_timestamp bigint, p_ttl_seconds integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.upsert_metal_price(p_metal_symbol character varying, p_base_currency character varying, p_price_per_ounce numeric, p_price_per_gram numeric, p_price_per_kilogram numeric, p_api_timestamp bigint, p_ttl_seconds integer) IS 'Insert or update a metal price in the cache';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admin_audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_audit_logs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    admin_id uuid NOT NULL,
    action character varying(100) NOT NULL,
    entity_type character varying(50),
    entity_id uuid,
    changes jsonb,
    ip_address inet,
    user_agent text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: admins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admins (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    admin_role public.user_role DEFAULT 'ADMIN'::public.user_role NOT NULL,
    permissions jsonb,
    created_by uuid,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_admin_role CHECK ((admin_role = ANY (ARRAY['ADMIN'::public.user_role, 'SUPER_ADMIN'::public.user_role])))
);


--
-- Name: agent_commissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_commissions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    agent_id uuid NOT NULL,
    transaction_id uuid NOT NULL,
    commission_amount numeric(15,2) NOT NULL,
    commission_rate numeric(5,2) NOT NULL,
    transaction_type character varying(20) NOT NULL,
    paid boolean DEFAULT false,
    paid_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_commission CHECK ((commission_amount >= (0)::numeric))
);


--
-- Name: TABLE agent_commissions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.agent_commissions IS 'Agent commission tracking per transaction';


--
-- Name: agent_credit_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_credit_requests (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    agent_id uuid NOT NULL,
    amount numeric(15,2) NOT NULL,
    receipt_url text NOT NULL,
    deposit_date date NOT NULL,
    deposit_time time without time zone NOT NULL,
    bank_name character varying(255),
    status public.transaction_status DEFAULT 'PENDING'::public.transaction_status,
    admin_id uuid,
    rejection_reason text,
    approved_at timestamp with time zone,
    rejected_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_amount CHECK ((amount > (0)::numeric))
);


--
-- Name: agent_reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_reviews (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    agent_id uuid NOT NULL,
    user_id uuid NOT NULL,
    transaction_id uuid,
    rating integer NOT NULL,
    comment text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_rating CHECK (((rating >= 1) AND (rating <= 5)))
);


--
-- Name: TABLE agent_reviews; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.agent_reviews IS 'User reviews and ratings for agents';


--
-- Name: agents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agents (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    wallet_balance numeric(15,2) DEFAULT 0.00 NOT NULL,
    active_status boolean DEFAULT false,
    verification_status public.kyc_status DEFAULT 'PENDING'::public.kyc_status NOT NULL,
    location_lat numeric(10,8),
    location_lng numeric(11,8),
    location_address text,
    commission_rate numeric(5,2) DEFAULT 0.00,
    total_commission_earned numeric(15,2) DEFAULT 0.00,
    total_transactions_processed integer DEFAULT 0,
    verified_at timestamp with time zone,
    verified_by uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_wallet_balance CHECK ((wallet_balance >= (0)::numeric)),
    CONSTRAINT valid_commission_rate CHECK (((commission_rate >= (0)::numeric) AND (commission_rate <= (100)::numeric)))
);


--
-- Name: TABLE agents; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.agents IS 'Agent-specific information and wallet';


--
-- Name: api_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_keys (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    key_hash character varying(255) NOT NULL,
    name character varying(100) NOT NULL,
    admin_id uuid,
    partner_name character varying(255),
    permissions jsonb NOT NULL,
    rate_limit integer DEFAULT 100,
    last_used_at timestamp with time zone,
    usage_count integer DEFAULT 0,
    is_active boolean DEFAULT true,
    expires_at timestamp with time zone,
    revoked_at timestamp with time zone,
    revoked_by uuid,
    revoke_reason text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: TABLE api_keys; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.api_keys IS 'API keys for admin and partner integrations';


--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_log (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    table_name character varying(50) NOT NULL,
    operation character varying(10) NOT NULL,
    record_id uuid NOT NULL,
    user_id uuid,
    old_data jsonb,
    new_data jsonb,
    changed_fields text[],
    ip_address inet,
    user_agent text,
    session_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: bank_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bank_accounts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    bank_name character varying(255) NOT NULL,
    branch_address character varying(500),
    account_number character varying(50) NOT NULL,
    account_holder_name character varying(255) NOT NULL,
    swift_code character varying(20),
    routing_number character varying(20),
    is_primary boolean DEFAULT false,
    is_verified boolean DEFAULT false,
    verification_otp character varying(10),
    otp_sent_at timestamp with time zone,
    otp_verified_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: bill_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bill_payments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    provider_id uuid,
    bill_type public.bill_type NOT NULL,
    bill_id character varying(100) NOT NULL,
    bill_holder_name character varying(255),
    amount numeric(15,2) NOT NULL,
    transaction_id uuid NOT NULL,
    provider_transaction_id character varying(255),
    status public.transaction_status DEFAULT 'PENDING'::public.transaction_status,
    receipt_url text,
    processed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_amount CHECK ((amount > (0)::numeric))
);


--
-- Name: bill_providers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bill_providers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    type public.bill_type NOT NULL,
    logo_url text,
    api_endpoint text,
    api_key_encrypted text,
    is_active boolean DEFAULT true,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: election_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.election_options (
    id integer NOT NULL,
    election_id integer NOT NULL,
    option_text text NOT NULL,
    vote_count integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: TABLE election_options; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.election_options IS 'Stores options for each election';


--
-- Name: election_options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.election_options_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: election_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.election_options_id_seq OWNED BY public.election_options.id;


--
-- Name: election_votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.election_votes (
    id integer NOT NULL,
    election_id integer NOT NULL,
    option_id integer NOT NULL,
    user_id uuid NOT NULL,
    vote_charge numeric(10,2) NOT NULL,
    voted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: TABLE election_votes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.election_votes IS 'Stores user votes for elections';


--
-- Name: election_votes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.election_votes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: election_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.election_votes_id_seq OWNED BY public.election_votes.id;


--
-- Name: elections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.elections (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    question text NOT NULL,
    voting_charge numeric(10,2) DEFAULT 0.00 NOT NULL,
    start_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    end_time timestamp without time zone NOT NULL,
    status character varying(50) DEFAULT 'active'::character varying NOT NULL,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    ended_at timestamp without time zone,
    total_votes integer DEFAULT 0,
    total_revenue numeric(12,2) DEFAULT 0.00
);


--
-- Name: TABLE elections; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.elections IS 'Stores election/poll information';


--
-- Name: COLUMN elections.voting_charge; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.elections.voting_charge IS 'Cost in TCC coins to cast a vote';


--
-- Name: COLUMN elections.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.elections.status IS 'Election status: active, ended, paused';


--
-- Name: elections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.elections_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: elections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.elections_id_seq OWNED BY public.elections.id;


--
-- Name: file_uploads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.file_uploads (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    file_type character varying(50) NOT NULL,
    original_filename character varying(255) NOT NULL,
    stored_filename character varying(255) NOT NULL,
    file_url text NOT NULL,
    file_size bigint NOT NULL,
    mime_type character varying(100) NOT NULL,
    checksum character varying(64),
    metadata jsonb,
    is_deleted boolean DEFAULT false,
    deleted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_file_size CHECK (((file_size > 0) AND (file_size <= 10485760)))
);


--
-- Name: fraud_detection_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fraud_detection_logs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    transaction_id uuid,
    detection_type character varying(50) NOT NULL,
    risk_score integer NOT NULL,
    details jsonb NOT NULL,
    action_taken character varying(30),
    reviewed_by uuid,
    reviewed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: investment_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.investment_categories (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name public.investment_category NOT NULL,
    display_name character varying(100) NOT NULL,
    description text,
    sub_categories jsonb,
    icon_url text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: investment_opportunities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.investment_opportunities (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    category_id uuid NOT NULL,
    title character varying(255) NOT NULL,
    description text NOT NULL,
    min_investment numeric(15,2) NOT NULL,
    max_investment numeric(15,2) NOT NULL,
    tenure_months integer NOT NULL,
    return_rate numeric(5,2) NOT NULL,
    total_units integer DEFAULT 0 NOT NULL,
    available_units integer DEFAULT 0 NOT NULL,
    image_url text,
    is_active boolean DEFAULT true,
    display_order integer DEFAULT 0,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_available_units CHECK (((available_units >= 0) AND (available_units <= total_units))),
    CONSTRAINT positive_max_investment CHECK ((max_investment >= min_investment)),
    CONSTRAINT positive_min_investment CHECK ((min_investment > (0)::numeric)),
    CONSTRAINT positive_return_rate CHECK ((return_rate >= (0)::numeric)),
    CONSTRAINT positive_tenure CHECK ((tenure_months > 0)),
    CONSTRAINT positive_total_units CHECK ((total_units >= 0))
);


--
-- Name: investment_returns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.investment_returns (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    investment_id uuid NOT NULL,
    return_date date NOT NULL,
    calculated_amount numeric(15,2) NOT NULL,
    actual_amount numeric(15,2),
    actual_rate numeric(5,2),
    status character varying(20) DEFAULT 'PENDING'::character varying,
    notes text,
    processed_by uuid,
    processed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_calculated CHECK ((calculated_amount >= (0)::numeric))
);


--
-- Name: TABLE investment_returns; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.investment_returns IS 'Manual investment return entry by admin';


--
-- Name: investment_tenure_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.investment_tenure_requests (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    investment_id uuid NOT NULL,
    user_id uuid NOT NULL,
    old_tenure_months integer NOT NULL,
    new_tenure_months integer NOT NULL,
    old_return_rate numeric(5,2) NOT NULL,
    new_return_rate numeric(5,2) NOT NULL,
    status public.transaction_status DEFAULT 'PENDING'::public.transaction_status,
    admin_id uuid,
    rejection_reason text,
    approved_at timestamp with time zone,
    rejected_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: investment_tenures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.investment_tenures (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    category_id uuid NOT NULL,
    duration_months integer NOT NULL,
    return_percentage numeric(5,2) NOT NULL,
    agreement_template_url text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_duration CHECK ((duration_months > 0)),
    CONSTRAINT positive_return CHECK ((return_percentage >= (0)::numeric))
);


--
-- Name: investment_units; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.investment_units (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    category public.investment_category NOT NULL,
    unit_name character varying(50) NOT NULL,
    unit_price numeric(15,2) NOT NULL,
    description text,
    icon_url text,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_price CHECK ((unit_price > (0)::numeric))
);


--
-- Name: TABLE investment_units; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.investment_units IS 'Investment unit pricing (Lot/Plot/Farm from Figma)';


--
-- Name: investments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.investments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    category public.investment_category NOT NULL,
    sub_category character varying(100),
    tenure_id uuid NOT NULL,
    amount numeric(15,2) NOT NULL,
    tenure_months integer NOT NULL,
    return_rate numeric(5,2) NOT NULL,
    expected_return numeric(15,2) NOT NULL,
    actual_return numeric(15,2),
    start_date date NOT NULL,
    end_date date NOT NULL,
    agreement_url text,
    insurance_taken boolean DEFAULT false,
    insurance_cost numeric(15,2),
    status public.investment_status DEFAULT 'ACTIVE'::public.investment_status,
    transaction_id uuid,
    withdrawal_transaction_id uuid,
    withdrawn_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_amount CHECK ((amount > (0)::numeric)),
    CONSTRAINT valid_dates CHECK ((end_date > start_date))
);


--
-- Name: TABLE investments; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.investments IS 'User investment records with returns tracking';


--
-- Name: ip_access_control; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ip_access_control (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    ip_address inet NOT NULL,
    ip_range_start inet,
    ip_range_end inet,
    type character varying(20) NOT NULL,
    reason text,
    severity character varying(20) DEFAULT 'MEDIUM'::character varying,
    expires_at timestamp with time zone,
    created_by uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: kyc_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.kyc_documents (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    document_type public.document_type NOT NULL,
    document_url text NOT NULL,
    document_number character varying(100),
    status public.kyc_status DEFAULT 'SUBMITTED'::public.kyc_status,
    rejection_reason text,
    verified_by uuid,
    verified_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: metal_price_cache; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.metal_price_cache (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    metal_symbol character varying(10) NOT NULL,
    base_currency character varying(3) NOT NULL,
    price_per_ounce numeric(20,6) NOT NULL,
    price_per_gram numeric(20,6) NOT NULL,
    price_per_kilogram numeric(20,6) NOT NULL,
    api_timestamp bigint NOT NULL,
    cached_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: TABLE metal_price_cache; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.metal_price_cache IS 'Persistent cache for metal prices from external API to minimize API calls';


--
-- Name: COLUMN metal_price_cache.metal_symbol; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.metal_price_cache.metal_symbol IS 'Metal symbol (e.g., XAU for Gold, XAG for Silver, XPT for Platinum)';


--
-- Name: COLUMN metal_price_cache.base_currency; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.metal_price_cache.base_currency IS 'Base currency for the price (e.g., SLL, USD)';


--
-- Name: COLUMN metal_price_cache.price_per_ounce; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.metal_price_cache.price_per_ounce IS 'Price per troy ounce (31.1034768 grams)';


--
-- Name: COLUMN metal_price_cache.price_per_gram; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.metal_price_cache.price_per_gram IS 'Price per gram';


--
-- Name: COLUMN metal_price_cache.price_per_kilogram; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.metal_price_cache.price_per_kilogram IS 'Price per kilogram';


--
-- Name: COLUMN metal_price_cache.api_timestamp; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.metal_price_cache.api_timestamp IS 'Unix timestamp from the API response';


--
-- Name: COLUMN metal_price_cache.expires_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.metal_price_cache.expires_at IS 'When this cache entry expires';


--
-- Name: notification_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_preferences (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    push_enabled boolean DEFAULT true,
    email_enabled boolean DEFAULT true,
    sms_enabled boolean DEFAULT false,
    notification_types jsonb DEFAULT '{"KYC": true, "VOTE": false, "DEPOSIT": true, "SECURITY": true, "TRANSFER": true, "INVESTMENT": true, "WITHDRAWAL": true, "ANNOUNCEMENT": true, "BILL_PAYMENT": true}'::jsonb,
    quiet_hours_start time without time zone,
    quiet_hours_end time without time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: TABLE notification_preferences; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.notification_preferences IS 'User notification preferences and quiet hours';


--
-- Name: notification_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_templates (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    template_code character varying(50) NOT NULL,
    channel character varying(20) NOT NULL,
    subject character varying(255),
    body_template text NOT NULL,
    variables jsonb,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    type public.notification_type NOT NULL,
    title character varying(255) NOT NULL,
    message text NOT NULL,
    data jsonb,
    is_read boolean DEFAULT false,
    read_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: otp_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.otp_codes (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    phone character varying(20),
    email character varying(255),
    code character varying(10) NOT NULL,
    purpose character varying(50) NOT NULL,
    attempts integer DEFAULT 0,
    is_verified boolean DEFAULT false,
    expires_at timestamp with time zone NOT NULL,
    verified_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT max_attempts CHECK ((attempts <= 3))
);


--
-- Name: otps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.otps (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    phone character varying(20) NOT NULL,
    country_code character varying(5) NOT NULL,
    otp character varying(10) NOT NULL,
    purpose character varying(20) NOT NULL,
    is_verified boolean DEFAULT false,
    attempts integer DEFAULT 0,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT otps_purpose_check CHECK (((purpose)::text = ANY ((ARRAY['REGISTRATION'::character varying, 'LOGIN'::character varying, 'PHONE_CHANGE'::character varying, 'PASSWORD_RESET'::character varying, 'WITHDRAWAL'::character varying, 'TRANSFER'::character varying])::text[])))
);


--
-- Name: password_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.password_history (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    password_hash character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: polls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.polls (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying(255) NOT NULL,
    question text NOT NULL,
    options jsonb NOT NULL,
    voting_charge numeric(15,2) NOT NULL,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone NOT NULL,
    status public.poll_status DEFAULT 'DRAFT'::public.poll_status,
    created_by_admin_id uuid NOT NULL,
    total_votes integer DEFAULT 0,
    total_revenue numeric(15,2) DEFAULT 0.00,
    results jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_charge CHECK ((voting_charge >= (0)::numeric)),
    CONSTRAINT valid_time_range CHECK ((end_time > start_time))
);


--
-- Name: TABLE polls; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.polls IS 'E-voting polls created by admins';


--
-- Name: push_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.push_tokens (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    token text NOT NULL,
    platform character varying(20) NOT NULL,
    device_id character varying(255),
    is_active boolean DEFAULT true,
    last_used_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: rate_limits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rate_limits (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    identifier character varying(255) NOT NULL,
    endpoint character varying(255) NOT NULL,
    request_count integer DEFAULT 1,
    window_start timestamp with time zone NOT NULL,
    window_end timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: referrals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.referrals (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    referrer_id uuid NOT NULL,
    referred_id uuid NOT NULL,
    reward_amount numeric(15,2) DEFAULT 0.00,
    reward_type character varying(20) DEFAULT 'COINS'::character varying,
    status character varying(20) DEFAULT 'PENDING'::character varying,
    conditions_met boolean DEFAULT false,
    conditions jsonb,
    paid_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: TABLE referrals; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.referrals IS 'Referral rewards tracking system';


--
-- Name: refresh_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.refresh_tokens (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    token text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: scheduled_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scheduled_transactions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    type public.transaction_type NOT NULL,
    recipient_id uuid,
    bill_provider_id uuid,
    amount numeric(15,2) NOT NULL,
    frequency character varying(20) NOT NULL,
    frequency_interval integer DEFAULT 1,
    next_execution_date date NOT NULL,
    last_execution_date date,
    total_executions integer DEFAULT 0,
    max_executions integer,
    is_active boolean DEFAULT true,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_amount CHECK ((amount > (0)::numeric)),
    CONSTRAINT valid_frequency_interval CHECK ((frequency_interval > 0))
);


--
-- Name: security_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.security_events (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    event_type character varying(50) NOT NULL,
    severity character varying(20) NOT NULL,
    description text,
    ip_address inet,
    device_info jsonb,
    location character varying(255),
    metadata jsonb,
    resolved boolean DEFAULT false,
    resolved_by uuid,
    resolved_at timestamp with time zone,
    resolution_notes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: TABLE security_events; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.security_events IS 'Security and suspicious activity tracking';


--
-- Name: support_tickets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.support_tickets (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    ticket_id character varying(20) NOT NULL,
    user_id uuid,
    email character varying(255) NOT NULL,
    subject character varying(500) NOT NULL,
    message text NOT NULL,
    attachments jsonb,
    status character varying(20) DEFAULT 'OPEN'::character varying,
    priority character varying(20) DEFAULT 'NORMAL'::character varying,
    assigned_to uuid,
    resolved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: system_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_config (
    key character varying(100) NOT NULL,
    value text NOT NULL,
    category character varying(50) NOT NULL,
    data_type character varying(20) NOT NULL,
    description text,
    updated_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: COLUMN system_config.value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.system_config.value IS 'All values stored as TEXT, cast based on data_type';


--
-- Name: transaction_reversals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transaction_reversals (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    original_transaction_id uuid NOT NULL,
    reversal_transaction_id uuid,
    reason character varying(255) NOT NULL,
    reversal_type character varying(20) DEFAULT 'FULL'::character varying,
    reversal_amount numeric(15,2),
    initiated_by uuid,
    approved_by uuid,
    status character varying(20) DEFAULT 'PENDING'::character varying,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    completed_at timestamp with time zone,
    CONSTRAINT positive_amount CHECK ((reversal_amount > (0)::numeric))
);


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transactions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    transaction_id character varying(50) NOT NULL,
    type public.transaction_type NOT NULL,
    from_user_id uuid,
    to_user_id uuid,
    amount numeric(15,2) NOT NULL,
    fee numeric(15,2) DEFAULT 0.00,
    net_amount numeric(15,2) NOT NULL,
    status public.transaction_status DEFAULT 'PENDING'::public.transaction_status NOT NULL,
    payment_method public.payment_method,
    deposit_source public.deposit_source,
    reference character varying(255),
    description text,
    metadata jsonb,
    ip_address inet,
    user_agent text,
    processed_at timestamp with time zone,
    failed_at timestamp with time zone,
    failure_reason text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    stripe_payment_intent_id character varying(255),
    payment_gateway_response jsonb,
    CONSTRAINT positive_amount CHECK ((amount > (0)::numeric)),
    CONSTRAINT positive_fee CHECK ((fee >= (0)::numeric))
);


--
-- Name: TABLE transactions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.transactions IS 'All financial transactions in the system';


--
-- Name: user_devices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_devices (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    device_id character varying(255) NOT NULL,
    device_type character varying(50) NOT NULL,
    device_name character varying(255),
    device_model character varying(255),
    os_version character varying(50),
    app_version character varying(20),
    fingerprint character varying(255),
    is_trusted boolean DEFAULT false,
    is_blocked boolean DEFAULT false,
    trust_score integer DEFAULT 0,
    last_used_at timestamp with time zone,
    last_location character varying(255),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_sessions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    token_hash character varying(255) NOT NULL,
    refresh_token_hash character varying(255),
    device_info jsonb,
    ip_address inet,
    location character varying(255),
    is_active boolean DEFAULT true,
    last_activity_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: TABLE user_sessions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.user_sessions IS 'Active user sessions with JWT tokens';


--
-- Name: user_transaction_limits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_transaction_limits (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    limit_type character varying(30) NOT NULL,
    limit_value numeric(15,2) NOT NULL,
    current_value numeric(15,2) DEFAULT 0,
    reset_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    role public.user_role DEFAULT 'USER'::public.user_role NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    email character varying(255) NOT NULL,
    phone character varying(20) NOT NULL,
    country_code character varying(5) DEFAULT '+232'::character varying NOT NULL,
    password_hash character varying(255) NOT NULL,
    profile_picture_url text,
    kyc_status public.kyc_status DEFAULT 'PENDING'::public.kyc_status NOT NULL,
    is_active boolean DEFAULT true,
    is_verified boolean DEFAULT false,
    email_verified boolean DEFAULT false,
    phone_verified boolean DEFAULT false,
    last_login_at timestamp with time zone,
    password_changed_at timestamp with time zone,
    failed_login_attempts integer DEFAULT 0,
    locked_until timestamp with time zone,
    two_factor_enabled boolean DEFAULT false,
    two_factor_secret character varying(255),
    deletion_requested_at timestamp with time zone,
    deletion_scheduled_for timestamp with time zone,
    referral_code character varying(10),
    referred_by uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    stripe_customer_id character varying(255)
);


--
-- Name: TABLE users; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.users IS 'Core users table for all user types (USER, AGENT, ADMIN)';


--
-- Name: v_current_metal_prices; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_current_metal_prices AS
 SELECT mpc.id,
    mpc.metal_symbol,
    mpc.base_currency,
    mpc.price_per_ounce,
    mpc.price_per_gram,
    mpc.price_per_kilogram,
    mpc.api_timestamp,
    mpc.cached_at,
    mpc.expires_at,
        CASE
            WHEN (CURRENT_TIMESTAMP > mpc.expires_at) THEN true
            ELSE false
        END AS is_expired,
    EXTRACT(epoch FROM (CURRENT_TIMESTAMP - mpc.cached_at)) AS seconds_since_cached,
    EXTRACT(epoch FROM (mpc.expires_at - CURRENT_TIMESTAMP)) AS seconds_until_expiry
   FROM public.metal_price_cache mpc
  WHERE (CURRENT_TIMESTAMP <= (mpc.expires_at + '7 days'::interval))
  ORDER BY mpc.metal_symbol, mpc.base_currency, mpc.cached_at DESC;


--
-- Name: votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.votes (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    poll_id uuid NOT NULL,
    user_id uuid NOT NULL,
    selected_option character varying(255) NOT NULL,
    amount_paid numeric(15,2) NOT NULL,
    transaction_id uuid NOT NULL,
    voted_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: TABLE votes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.votes IS 'User votes on polls (non-anonymous)';


--
-- Name: vw_agent_performance; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.vw_agent_performance AS
 SELECT a.id,
    a.user_id,
    (((u.first_name)::text || ' '::text) || (u.last_name)::text) AS agent_name,
    a.wallet_balance,
    a.active_status,
    a.total_commission_earned,
    a.total_transactions_processed,
    count(DISTINCT date(ac.created_at)) AS days_active,
    count(DISTINCT ac.transaction_id) FILTER (WHERE (date(ac.created_at) = CURRENT_DATE)) AS transactions_today,
    COALESCE(sum(ac.commission_amount) FILTER (WHERE (date(ac.created_at) = CURRENT_DATE)), (0)::numeric) AS commission_today,
    COALESCE(avg(ar.rating), (0)::numeric) AS average_rating,
    count(DISTINCT ar.id) AS total_reviews,
    a.location_lat,
    a.location_lng,
    a.location_address
   FROM (((public.agents a
     JOIN public.users u ON ((a.user_id = u.id)))
     LEFT JOIN public.agent_commissions ac ON ((a.id = ac.agent_id)))
     LEFT JOIN public.agent_reviews ar ON ((a.id = ar.agent_id)))
  GROUP BY a.id, a.user_id, u.first_name, u.last_name, a.wallet_balance, a.active_status, a.total_commission_earned, a.total_transactions_processed, a.location_lat, a.location_lng, a.location_address
  WITH NO DATA;


--
-- Name: wallets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wallets (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    balance numeric(15,2) DEFAULT 0.00 NOT NULL,
    currency character varying(3) DEFAULT 'SLL'::character varying NOT NULL,
    last_transaction_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_balance CHECK ((balance >= (0)::numeric))
);


--
-- Name: TABLE wallets; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.wallets IS 'User wallet balances in Sierra Leonean Leone (SLL)';


--
-- Name: vw_user_dashboard; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.vw_user_dashboard AS
 SELECT u.id,
    u.first_name,
    u.last_name,
    u.email,
    u.phone,
    u.kyc_status,
    u.is_verified,
    w.balance AS wallet_balance,
    w.currency,
    count(DISTINCT t.id) AS total_transactions,
    count(DISTINCT
        CASE
            WHEN (date(t.created_at) = CURRENT_DATE) THEN t.id
            ELSE NULL::uuid
        END) AS transactions_today,
    count(DISTINCT i.id) AS active_investments,
    COALESCE(sum(i.amount), (0)::numeric) AS total_invested,
    COALESCE(sum(i.expected_return), (0)::numeric) AS expected_returns
   FROM (((public.users u
     LEFT JOIN public.wallets w ON ((u.id = w.user_id)))
     LEFT JOIN public.transactions t ON ((((u.id = t.from_user_id) OR (u.id = t.to_user_id)) AND (t.status = 'COMPLETED'::public.transaction_status))))
     LEFT JOIN public.investments i ON (((u.id = i.user_id) AND (i.status = 'ACTIVE'::public.investment_status))))
  WHERE (u.role = 'USER'::public.user_role)
  GROUP BY u.id, u.first_name, u.last_name, u.email, u.phone, u.kyc_status, u.is_verified, w.balance, w.currency
  WITH NO DATA;


--
-- Name: wallet_audit_trail; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wallet_audit_trail (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    admin_id uuid NOT NULL,
    action_type character varying(50) NOT NULL,
    amount numeric(15,2) NOT NULL,
    balance_before numeric(15,2) NOT NULL,
    balance_after numeric(15,2) NOT NULL,
    reason text NOT NULL,
    notes text,
    transaction_id character varying(50),
    ip_address character varying(45),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT wallet_audit_trail_action_type_check CHECK (((action_type)::text = ANY ((ARRAY['MANUAL_CREDIT'::character varying, 'MANUAL_DEBIT'::character varying, 'BALANCE_CORRECTION'::character varying, 'REFUND'::character varying])::text[])))
);


--
-- Name: TABLE wallet_audit_trail; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.wallet_audit_trail IS 'Tracks all manual wallet balance adjustments made by administrators';


--
-- Name: COLUMN wallet_audit_trail.action_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wallet_audit_trail.action_type IS 'Type of manual adjustment: MANUAL_CREDIT, MANUAL_DEBIT, BALANCE_CORRECTION, or REFUND';


--
-- Name: COLUMN wallet_audit_trail.balance_before; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wallet_audit_trail.balance_before IS 'Wallet balance before the adjustment';


--
-- Name: COLUMN wallet_audit_trail.balance_after; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wallet_audit_trail.balance_after IS 'Wallet balance after the adjustment';


--
-- Name: COLUMN wallet_audit_trail.reason; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wallet_audit_trail.reason IS 'Required reason for the adjustment';


--
-- Name: COLUMN wallet_audit_trail.notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wallet_audit_trail.notes IS 'Optional additional notes about the adjustment';


--
-- Name: withdrawal_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.withdrawal_requests (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    amount numeric(15,2) NOT NULL,
    fee numeric(15,2) NOT NULL,
    net_amount numeric(15,2) NOT NULL,
    withdrawal_type character varying(20) NOT NULL,
    investment_id uuid,
    destination character varying(20) NOT NULL,
    bank_account_id uuid,
    mobile_money_number character varying(20),
    status public.transaction_status DEFAULT 'PENDING'::public.transaction_status,
    admin_id uuid,
    rejection_reason text,
    transaction_id uuid,
    approved_at timestamp with time zone,
    rejected_at timestamp with time zone,
    processed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_amount CHECK ((amount > (0)::numeric))
);


--
-- Name: election_options id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.election_options ALTER COLUMN id SET DEFAULT nextval('public.election_options_id_seq'::regclass);


--
-- Name: election_votes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.election_votes ALTER COLUMN id SET DEFAULT nextval('public.election_votes_id_seq'::regclass);


--
-- Name: elections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.elections ALTER COLUMN id SET DEFAULT nextval('public.elections_id_seq'::regclass);


--
-- Data for Name: admin_audit_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.admin_audit_logs (id, admin_id, action, entity_type, entity_id, changes, ip_address, user_agent, created_at) FROM stdin;
c430d92a-accc-4117-b233-b5e7b24a60bf	af223b34-da3f-44a6-bcd6-938034b46d50	APPROVE_KYC	KYC_DOCUMENT	f6cc90cb-b06e-431f-9327-9a5382ee6b3c	{"status": "APPROVED", "user_id": "6b864809-fb5a-4a1f-a95e-edf87b7eeb5c", "rejection_reason": "KYC approved by admin"}	\N	\N	2025-12-20 17:02:40.2427+05:30
985308f9-a0a0-49b1-bb50-fa1e1dba349b	af223b34-da3f-44a6-bcd6-938034b46d50	REJECT_KYC	KYC_DOCUMENT	164c759b-e7da-4e60-8d8a-593961dda633	{"status": "REJECTED", "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "rejection_reason": "Document appears invalid or tampered"}	\N	\N	2025-12-20 17:03:01.067975+05:30
0056e443-9b38-4349-b6ee-3168d7004da4	af223b34-da3f-44a6-bcd6-938034b46d50	APPROVE_KYC	KYC_DOCUMENT	0e6d3bb2-8232-47b3-b455-0962cc123375	{"status": "APPROVED", "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "rejection_reason": "KYC approved by admin"}	\N	\N	2025-12-20 21:41:59.838666+05:30
d25abf04-f1d4-4131-82e3-5cb1160c28dd	af223b34-da3f-44a6-bcd6-938034b46d50	REJECT_KYC	KYC_DOCUMENT	8e635e1f-0aa5-4210-a526-4cd7488c9c34	{"status": "REJECTED", "user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "rejection_reason": "Photo does not match document"}	\N	\N	2025-12-20 23:46:43.364045+05:30
a5c2b958-b188-456b-ae49-beac29e1de74	af223b34-da3f-44a6-bcd6-938034b46d50	APPROVE_KYC	KYC_DOCUMENT	34f4fa18-4cf5-456f-b3ad-c7aa90e3fb05	{"status": "APPROVED", "user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "rejection_reason": "KYC approved by admin"}	\N	\N	2025-12-20 23:48:42.866779+05:30
246f2eca-3402-4165-a29b-d2bc168fcd99	af223b34-da3f-44a6-bcd6-938034b46d50	APPROVE_KYC	KYC_DOCUMENT	b96ad895-49cc-4e0c-9282-c64b341a3f9b	{"status": "APPROVED", "user_id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "rejection_reason": "KYC approved by admin"}	\N	\N	2026-01-02 14:40:29.385817+05:30
\.


--
-- Data for Name: admins; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.admins (id, user_id, admin_role, permissions, created_by, is_active, created_at, updated_at) FROM stdin;
0d37851e-9bb4-479c-9374-1f127e3e9f55	892f1e8c-993a-4016-8099-398d8dcd66a1	SUPER_ADMIN	\N	\N	t	2025-12-18 18:12:24.834201+05:30	2025-12-18 18:12:24.834201+05:30
\.


--
-- Data for Name: agent_commissions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.agent_commissions (id, agent_id, transaction_id, commission_amount, commission_rate, transaction_type, paid, paid_at, created_at) FROM stdin;
\.


--
-- Data for Name: agent_credit_requests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.agent_credit_requests (id, agent_id, amount, receipt_url, deposit_date, deposit_time, bank_name, status, admin_id, rejection_reason, approved_at, rejected_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: agent_reviews; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.agent_reviews (id, agent_id, user_id, transaction_id, rating, comment, created_at) FROM stdin;
\.


--
-- Data for Name: agents; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.agents (id, user_id, wallet_balance, active_status, verification_status, location_lat, location_lng, location_address, commission_rate, total_commission_earned, total_transactions_processed, verified_at, verified_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: api_keys; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.api_keys (id, key_hash, name, admin_id, partner_name, permissions, rate_limit, last_used_at, usage_count, is_active, expires_at, revoked_at, revoked_by, revoke_reason, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_log (id, table_name, operation, record_id, user_id, old_data, new_data, changed_fields, ip_address, user_agent, session_id, created_at) FROM stdin;
acc1f83b-dbc6-4cdf-b865-a8883d8eed7a	users	INSERT	af223b34-da3f-44a6-bcd6-938034b46d50	\N	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-18T18:26:56.881408+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": null, "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	\N	\N	\N	\N	2025-12-18 18:26:56.881408+05:30
4eb631b0-de14-4091-9355-5b82662383ba	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-18T18:26:56.881408+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": null, "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-18T18:27:23.192226+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-18T18:27:23.192226+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-18 18:27:23.192226+05:30
69a502e1-7596-4cc4-bdda-b13d88ccd7a4	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-18T18:27:23.192226+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-18T18:27:23.192226+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-18T18:33:23.110562+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-18T18:33:23.110562+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-18 18:33:23.110562+05:30
da9d7285-eca8-4b23-96e6-6de7f6fbc00d	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-18T18:33:23.110562+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-18T18:33:23.110562+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-18T18:34:22.7683+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-18T18:34:22.7683+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-18 18:34:22.7683+05:30
74cb74fa-86a9-4f3a-bb43-d3cd004b486d	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-18T18:34:22.7683+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-18T18:34:22.7683+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-19T15:21:39.380491+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T15:21:39.380491+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-19 15:21:39.380491+05:30
dbac9a65-29cc-4f69-a82b-33cf2f450b83	users	INSERT	1880ea25-a5bf-4c10-8b2e-e7ff1728445b	\N	\N	{"id": "1880ea25-a5bf-4c10-8b2e-e7ff1728445b", "role": "USER", "email": "tc@tcc.com", "phone": "9876543210", "is_active": true, "last_name": "Test", "created_at": "2025-12-19T15:22:22.250196+05:30", "first_name": "Test", "kyc_status": "PENDING", "updated_at": "2025-12-19T15:22:22.250196+05:30", "is_verified": false, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": null, "password_hash": "$2b$10$//GgSRxf4e3DGWO4ZQjJyOBv6.Uc3ftQQIFJsiz3gJHJAw7NugDai", "referral_code": "MI87JQJC", "email_verified": false, "phone_verified": false, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	\N	\N	\N	\N	2025-12-19 15:22:22.250196+05:30
49ee88ff-3214-4718-bc91-e5f999814134	wallets	INSERT	eb199c7a-77ab-4a14-863f-63592424652c	\N	\N	{"id": "eb199c7a-77ab-4a14-863f-63592424652c", "balance": 0.00, "user_id": "1880ea25-a5bf-4c10-8b2e-e7ff1728445b", "currency": "SLL", "created_at": "2025-12-19T15:22:22.265731+05:30", "updated_at": "2025-12-19T15:22:22.265731+05:30", "last_transaction_at": null}	\N	\N	\N	\N	2025-12-19 15:22:22.265731+05:30
4f460571-1fca-4f50-a945-dbbfae3df7ae	users	UPDATE	1880ea25-a5bf-4c10-8b2e-e7ff1728445b	\N	{"id": "1880ea25-a5bf-4c10-8b2e-e7ff1728445b", "role": "USER", "email": "tc@tcc.com", "phone": "9876543210", "is_active": true, "last_name": "Test", "created_at": "2025-12-19T15:22:22.250196+05:30", "first_name": "Test", "kyc_status": "PENDING", "updated_at": "2025-12-19T15:22:22.250196+05:30", "is_verified": false, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": null, "password_hash": "$2b$10$//GgSRxf4e3DGWO4ZQjJyOBv6.Uc3ftQQIFJsiz3gJHJAw7NugDai", "referral_code": "MI87JQJC", "email_verified": false, "phone_verified": false, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "1880ea25-a5bf-4c10-8b2e-e7ff1728445b", "role": "USER", "email": "tc@tcc.com", "phone": "9876543210", "is_active": true, "last_name": "Test", "created_at": "2025-12-19T15:22:22.250196+05:30", "first_name": "Test", "kyc_status": "PENDING", "updated_at": "2025-12-19T15:22:28.043574+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T15:22:28.043574+05:30", "password_hash": "$2b$10$//GgSRxf4e3DGWO4ZQjJyOBv6.Uc3ftQQIFJsiz3gJHJAw7NugDai", "referral_code": "MI87JQJC", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,is_verified,last_login_at,phone_verified}	\N	\N	\N	2025-12-19 15:22:28.043574+05:30
2e6ca435-7dff-4853-95a0-e397d217b282	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-19T15:21:39.380491+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T15:21:39.380491+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-19T22:25:10.688666+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T22:25:10.688666+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-19 22:25:10.688666+05:30
6cd8a775-f52f-40b6-aa11-466627a40549	users	INSERT	15a46f44-4094-4b25-a4d3-51a3f682a4b9	\N	\N	{"id": "15a46f44-4094-4b25-a4d3-51a3f682a4b9", "role": "USER", "email": "tc2@tcc.com", "phone": "9876543211", "is_active": true, "last_name": "test2", "created_at": "2025-12-19T22:26:41.502956+05:30", "first_name": "test2", "kyc_status": "PENDING", "updated_at": "2025-12-19T22:26:41.502956+05:30", "is_verified": false, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": null, "password_hash": "$2b$10$Pe4PprcWOP/YkyAr7FnJy.UflEesu9ARZm2HwuLY6g2oYZMtohryO", "referral_code": "5I7QKT57", "email_verified": false, "phone_verified": false, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	\N	\N	\N	\N	2025-12-19 22:26:41.502956+05:30
b3a423d4-a5fa-47c3-8c02-b0b9cf00902d	wallets	INSERT	14b1fbaf-ca1f-4749-849d-42e0d45a7420	\N	\N	{"id": "14b1fbaf-ca1f-4749-849d-42e0d45a7420", "balance": 0.00, "user_id": "15a46f44-4094-4b25-a4d3-51a3f682a4b9", "currency": "SLL", "created_at": "2025-12-19T22:26:41.50751+05:30", "updated_at": "2025-12-19T22:26:41.50751+05:30", "last_transaction_at": null}	\N	\N	\N	\N	2025-12-19 22:26:41.50751+05:30
390bb9f2-d9b7-49da-9258-29d801c3401e	users	UPDATE	15a46f44-4094-4b25-a4d3-51a3f682a4b9	\N	{"id": "15a46f44-4094-4b25-a4d3-51a3f682a4b9", "role": "USER", "email": "tc2@tcc.com", "phone": "9876543211", "is_active": true, "last_name": "test2", "created_at": "2025-12-19T22:26:41.502956+05:30", "first_name": "test2", "kyc_status": "PENDING", "updated_at": "2025-12-19T22:26:41.502956+05:30", "is_verified": false, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": null, "password_hash": "$2b$10$Pe4PprcWOP/YkyAr7FnJy.UflEesu9ARZm2HwuLY6g2oYZMtohryO", "referral_code": "5I7QKT57", "email_verified": false, "phone_verified": false, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "15a46f44-4094-4b25-a4d3-51a3f682a4b9", "role": "USER", "email": "tc2@tcc.com", "phone": "9876543211", "is_active": true, "last_name": "test2", "created_at": "2025-12-19T22:26:41.502956+05:30", "first_name": "test2", "kyc_status": "PENDING", "updated_at": "2025-12-19T22:26:50.374461+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T22:26:50.374461+05:30", "password_hash": "$2b$10$Pe4PprcWOP/YkyAr7FnJy.UflEesu9ARZm2HwuLY6g2oYZMtohryO", "referral_code": "5I7QKT57", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,is_verified,last_login_at,phone_verified}	\N	\N	\N	2025-12-19 22:26:50.374461+05:30
30b90e80-7bf4-4945-89a7-724ed0d44b07	wallets	INSERT	c0cbdf1a-f592-4bec-9dd0-7708eb2c1278	\N	\N	{"id": "c0cbdf1a-f592-4bec-9dd0-7708eb2c1278", "balance": 0.00, "user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "currency": "SLL", "created_at": "2025-12-20T23:40:21.230675+05:30", "updated_at": "2025-12-20T23:40:21.230675+05:30", "last_transaction_at": null}	\N	\N	\N	\N	2025-12-20 23:40:21.230675+05:30
d2a00a83-7305-4c2f-a926-0ed0d843e47e	users	INSERT	43f2c95b-4fe8-4481-aa42-77125cef5d1f	\N	\N	{"id": "43f2c95b-4fe8-4481-aa42-77125cef5d1f", "role": "USER", "email": "t1@tcc.com", "phone": "9876543213", "is_active": true, "last_name": "test", "created_at": "2025-12-19T22:31:27.903088+05:30", "first_name": "test", "kyc_status": "PENDING", "updated_at": "2025-12-19T22:31:27.903088+05:30", "is_verified": false, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": null, "password_hash": "$2b$10$JP0AgEzScstcK7MryFb2P.qUZ3YMR.gGj/5KPEpT7FZK9NYtLJscm", "referral_code": "6O0JJY1X", "email_verified": false, "phone_verified": false, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	\N	\N	\N	\N	2025-12-19 22:31:27.903088+05:30
0fc93bdb-2a36-4b9f-97ec-40191e27588c	wallets	INSERT	b82201e3-1ca9-4ca6-ad64-278cd0e73b38	\N	\N	{"id": "b82201e3-1ca9-4ca6-ad64-278cd0e73b38", "balance": 0.00, "user_id": "43f2c95b-4fe8-4481-aa42-77125cef5d1f", "currency": "SLL", "created_at": "2025-12-19T22:31:27.911276+05:30", "updated_at": "2025-12-19T22:31:27.911276+05:30", "last_transaction_at": null}	\N	\N	\N	\N	2025-12-19 22:31:27.911276+05:30
60c5c595-a696-4343-aee1-63c9d1b64ff7	users	UPDATE	43f2c95b-4fe8-4481-aa42-77125cef5d1f	\N	{"id": "43f2c95b-4fe8-4481-aa42-77125cef5d1f", "role": "USER", "email": "t1@tcc.com", "phone": "9876543213", "is_active": true, "last_name": "test", "created_at": "2025-12-19T22:31:27.903088+05:30", "first_name": "test", "kyc_status": "PENDING", "updated_at": "2025-12-19T22:31:27.903088+05:30", "is_verified": false, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": null, "password_hash": "$2b$10$JP0AgEzScstcK7MryFb2P.qUZ3YMR.gGj/5KPEpT7FZK9NYtLJscm", "referral_code": "6O0JJY1X", "email_verified": false, "phone_verified": false, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "43f2c95b-4fe8-4481-aa42-77125cef5d1f", "role": "USER", "email": "t1@tcc.com", "phone": "9876543213", "is_active": true, "last_name": "test", "created_at": "2025-12-19T22:31:27.903088+05:30", "first_name": "test", "kyc_status": "PENDING", "updated_at": "2025-12-19T22:31:38.650209+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T22:31:38.650209+05:30", "password_hash": "$2b$10$JP0AgEzScstcK7MryFb2P.qUZ3YMR.gGj/5KPEpT7FZK9NYtLJscm", "referral_code": "6O0JJY1X", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,is_verified,last_login_at,phone_verified}	\N	\N	\N	2025-12-19 22:31:38.650209+05:30
11fb4a6b-4de2-4126-926a-f90e0eab3063	users	INSERT	42fa68c5-e80b-4100-9aad-c28300e33fff	\N	\N	{"id": "42fa68c5-e80b-4100-9aad-c28300e33fff", "role": "USER", "email": "t2@tcc.com", "phone": "9876543214", "is_active": true, "last_name": "t2", "created_at": "2025-12-19T22:33:43.697063+05:30", "first_name": "t2", "kyc_status": "PENDING", "updated_at": "2025-12-19T22:33:43.697063+05:30", "is_verified": false, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": null, "password_hash": "$2b$10$dq6FRxzeaZzi5G81Ez.njev3Y1cUbOsxWxX0ogavTajUseGLNv6eu", "referral_code": "50X6G2MH", "email_verified": false, "phone_verified": false, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	\N	\N	\N	\N	2025-12-19 22:33:43.697063+05:30
2eb75c39-0d94-4b6d-85a7-610f3ebbf5bd	wallets	INSERT	5841df58-ae1e-449f-b800-1b8947f0577c	\N	\N	{"id": "5841df58-ae1e-449f-b800-1b8947f0577c", "balance": 0.00, "user_id": "42fa68c5-e80b-4100-9aad-c28300e33fff", "currency": "SLL", "created_at": "2025-12-19T22:33:43.703066+05:30", "updated_at": "2025-12-19T22:33:43.703066+05:30", "last_transaction_at": null}	\N	\N	\N	\N	2025-12-19 22:33:43.703066+05:30
6712e46d-3057-42da-8481-ad01529fc9ec	users	UPDATE	42fa68c5-e80b-4100-9aad-c28300e33fff	\N	{"id": "42fa68c5-e80b-4100-9aad-c28300e33fff", "role": "USER", "email": "t2@tcc.com", "phone": "9876543214", "is_active": true, "last_name": "t2", "created_at": "2025-12-19T22:33:43.697063+05:30", "first_name": "t2", "kyc_status": "PENDING", "updated_at": "2025-12-19T22:33:43.697063+05:30", "is_verified": false, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": null, "password_hash": "$2b$10$dq6FRxzeaZzi5G81Ez.njev3Y1cUbOsxWxX0ogavTajUseGLNv6eu", "referral_code": "50X6G2MH", "email_verified": false, "phone_verified": false, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "42fa68c5-e80b-4100-9aad-c28300e33fff", "role": "USER", "email": "t2@tcc.com", "phone": "9876543214", "is_active": true, "last_name": "t2", "created_at": "2025-12-19T22:33:43.697063+05:30", "first_name": "t2", "kyc_status": "PENDING", "updated_at": "2025-12-19T22:35:04.620394+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T22:35:04.620394+05:30", "password_hash": "$2b$10$dq6FRxzeaZzi5G81Ez.njev3Y1cUbOsxWxX0ogavTajUseGLNv6eu", "referral_code": "50X6G2MH", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,is_verified,last_login_at,phone_verified}	\N	\N	\N	2025-12-19 22:35:04.620394+05:30
10a47bed-ebbd-4b96-ba93-f2e1b9c027d0	users	INSERT	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "PENDING", "updated_at": "2025-12-19T23:27:35.393285+05:30", "is_verified": false, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": null, "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": false, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	\N	\N	\N	\N	2025-12-19 23:27:35.393285+05:30
8ebc1977-f698-4810-bfb3-096e7de8d3ca	wallets	INSERT	18bee39e-ad39-499c-9495-d7416d7a8d7e	\N	\N	{"id": "18bee39e-ad39-499c-9495-d7416d7a8d7e", "balance": 0.00, "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "currency": "SLL", "created_at": "2025-12-19T23:27:35.419864+05:30", "updated_at": "2025-12-19T23:27:35.419864+05:30", "last_transaction_at": null}	\N	\N	\N	\N	2025-12-19 23:27:35.419864+05:30
3c538282-e149-4451-b3e5-cc7b9b1dfd0c	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "PENDING", "updated_at": "2025-12-19T23:27:35.393285+05:30", "is_verified": false, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": null, "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": false, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "PENDING", "updated_at": "2025-12-19T23:27:47.765003+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T23:27:47.765003+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,is_verified,last_login_at,phone_verified}	\N	\N	\N	2025-12-19 23:27:47.765003+05:30
27d500e6-d24b-4668-87aa-94b56e97d27d	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "PENDING", "updated_at": "2025-12-19T23:27:47.765003+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T23:27:47.765003+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-19T23:28:14.435353+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T23:27:47.765003+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{kyc_status,updated_at}	\N	\N	\N	2025-12-19 23:28:14.435353+05:30
891bb025-9c0e-46a1-9d39-a47d1c4e7566	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-19T22:25:10.688666+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T22:25:10.688666+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-20T00:07:00.589677+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T00:07:00.589677+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-20 00:07:00.589677+05:30
a4e8654c-53f3-425e-8a1d-907c1b54bb03	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-20T00:07:00.589677+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T00:07:00.589677+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-20T00:26:54.214239+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T00:26:54.214239+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-20 00:26:54.214239+05:30
fe4dcf01-c7c7-4da3-a9ef-5144c4edf782	users	UPDATE	15a46f44-4094-4b25-a4d3-51a3f682a4b9	\N	{"id": "15a46f44-4094-4b25-a4d3-51a3f682a4b9", "role": "USER", "email": "tc2@tcc.com", "phone": "9876543211", "is_active": true, "last_name": "test2", "created_at": "2025-12-19T22:26:41.502956+05:30", "first_name": "test2", "kyc_status": "PENDING", "updated_at": "2025-12-19T22:26:50.374461+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T22:26:50.374461+05:30", "password_hash": "$2b$10$Pe4PprcWOP/YkyAr7FnJy.UflEesu9ARZm2HwuLY6g2oYZMtohryO", "referral_code": "5I7QKT57", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "15a46f44-4094-4b25-a4d3-51a3f682a4b9", "role": "USER", "email": "tc2@tcc.com", "phone": "9876543211", "is_active": true, "last_name": "test2", "created_at": "2025-12-19T22:26:41.502956+05:30", "first_name": "test2", "kyc_status": "PENDING", "updated_at": "2025-12-20T00:35:06.853868+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T22:26:50.374461+05:30", "password_hash": "$2b$10$Pe4PprcWOP/YkyAr7FnJy.UflEesu9ARZm2HwuLY6g2oYZMtohryO", "referral_code": "5I7QKT57", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at}	\N	\N	\N	2025-12-20 00:35:06.853868+05:30
15e14a75-643d-4a77-86e6-ee3f49057a3c	users	UPDATE	15a46f44-4094-4b25-a4d3-51a3f682a4b9	\N	{"id": "15a46f44-4094-4b25-a4d3-51a3f682a4b9", "role": "USER", "email": "tc2@tcc.com", "phone": "9876543211", "is_active": true, "last_name": "test2", "created_at": "2025-12-19T22:26:41.502956+05:30", "first_name": "test2", "kyc_status": "PENDING", "updated_at": "2025-12-20T00:35:06.853868+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T22:26:50.374461+05:30", "password_hash": "$2b$10$Pe4PprcWOP/YkyAr7FnJy.UflEesu9ARZm2HwuLY6g2oYZMtohryO", "referral_code": "5I7QKT57", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "15a46f44-4094-4b25-a4d3-51a3f682a4b9", "role": "USER", "email": "tc2@tcc.com", "phone": "9876543211", "is_active": true, "last_name": "test2", "created_at": "2025-12-19T22:26:41.502956+05:30", "first_name": "test2", "kyc_status": "PENDING", "updated_at": "2025-12-20T00:50:45.472909+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T22:26:50.374461+05:30", "password_hash": "$2b$10$Pe4PprcWOP/YkyAr7FnJy.UflEesu9ARZm2HwuLY6g2oYZMtohryO", "referral_code": "5I7QKT57", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at}	\N	\N	\N	2025-12-20 00:50:45.472909+05:30
4bb1a41d-b96e-49a4-b03a-7543b8d93fbc	transactions	INSERT	c9bc125f-b358-4d78-90d3-6e5119b723f3	\N	\N	{"id": "c9bc125f-b358-4d78-90d3-6e5119b723f3", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgBAaFU6W2alheK2mAWYCQQ"}, "failed_at": null, "reference": null, "created_at": "2025-12-20T02:55:03.707002+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-20T02:55:03.707002+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251220212526", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SgBAaFU6W2alheK2mAWYCQQ"}	\N	\N	\N	\N	2025-12-20 02:55:03.707002+05:30
88c1fa34-754b-4f96-aa31-a2d7762e10c0	users	UPDATE	15a46f44-4094-4b25-a4d3-51a3f682a4b9	\N	{"id": "15a46f44-4094-4b25-a4d3-51a3f682a4b9", "role": "USER", "email": "tc2@tcc.com", "phone": "9876543211", "is_active": true, "last_name": "test2", "created_at": "2025-12-19T22:26:41.502956+05:30", "first_name": "test2", "kyc_status": "PENDING", "updated_at": "2025-12-20T00:50:45.472909+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T22:26:50.374461+05:30", "password_hash": "$2b$10$Pe4PprcWOP/YkyAr7FnJy.UflEesu9ARZm2HwuLY6g2oYZMtohryO", "referral_code": "5I7QKT57", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "15a46f44-4094-4b25-a4d3-51a3f682a4b9", "role": "USER", "email": "tc2@tcc.com", "phone": "9876543211", "is_active": true, "last_name": "test2", "created_at": "2025-12-19T22:26:41.502956+05:30", "first_name": "test2", "kyc_status": "PENDING", "updated_at": "2025-12-20T00:50:47.481826+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T22:26:50.374461+05:30", "password_hash": "$2b$10$Pe4PprcWOP/YkyAr7FnJy.UflEesu9ARZm2HwuLY6g2oYZMtohryO", "referral_code": "5I7QKT57", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at}	\N	\N	\N	2025-12-20 00:50:47.481826+05:30
c5997702-2160-4ebe-8692-1145fc052e70	users	UPDATE	1880ea25-a5bf-4c10-8b2e-e7ff1728445b	\N	{"id": "1880ea25-a5bf-4c10-8b2e-e7ff1728445b", "role": "USER", "email": "tc@tcc.com", "phone": "9876543210", "is_active": true, "last_name": "Test", "created_at": "2025-12-19T15:22:22.250196+05:30", "first_name": "Test", "kyc_status": "PENDING", "updated_at": "2025-12-19T15:22:28.043574+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T15:22:28.043574+05:30", "password_hash": "$2b$10$//GgSRxf4e3DGWO4ZQjJyOBv6.Uc3ftQQIFJsiz3gJHJAw7NugDai", "referral_code": "MI87JQJC", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "1880ea25-a5bf-4c10-8b2e-e7ff1728445b", "role": "USER", "email": "tc@tcc.com", "phone": "9876543210", "is_active": true, "last_name": "Test", "created_at": "2025-12-19T15:22:22.250196+05:30", "first_name": "Test", "kyc_status": "PENDING", "updated_at": "2025-12-20T00:50:55.413358+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T15:22:28.043574+05:30", "password_hash": "$2b$10$//GgSRxf4e3DGWO4ZQjJyOBv6.Uc3ftQQIFJsiz3gJHJAw7NugDai", "referral_code": "MI87JQJC", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at}	\N	\N	\N	2025-12-20 00:50:55.413358+05:30
cd62af2a-a5c3-4e0b-9fc5-918eaabb2a3f	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-20T00:26:54.214239+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T00:26:54.214239+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-20T00:52:47.532001+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T00:52:47.532001+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-20 00:52:47.532001+05:30
4b79d6f8-c130-47ae-9871-484431ed1d58	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-19T23:28:14.435353+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T23:27:47.765003+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T00:52:57.403474+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T23:27:47.765003+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at}	\N	\N	\N	2025-12-20 00:52:57.403474+05:30
9ba96dc3-6440-4fb6-ba02-7b9338f67a4a	transactions	UPDATE	ba5b7d98-7059-4496-871f-d0e784155551	\N	{"id": "ba5b7d98-7059-4496-871f-d0e784155551", "fee": 0.00, "type": "DEPOSIT", "amount": 5000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgUCfFU6W2alheK0WSlW80h"}, "failed_at": null, "reference": null, "created_at": "2025-12-20T23:14:28.860063+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 5000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-20T23:14:28.860063+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251220877328", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SgUCfFU6W2alheK0WSlW80h"}	{"id": "ba5b7d98-7059-4496-871f-d0e784155551", "fee": 0.00, "type": "DEPOSIT", "amount": 5000.00, "status": "COMPLETED", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgUCfFU6W2alheK0WSlW80h"}, "failed_at": null, "reference": null, "created_at": "2025-12-20T23:14:28.860063+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 5000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-20T23:15:42.299032+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": "2025-12-20T23:15:42.299032+05:30", "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251220877328", "payment_gateway_response": {"id": "pi_3SgUCfFU6W2alheK0WSlW80h", "amount": 500000, "object": "payment_intent", "review": null, "source": null, "status": "succeeded", "created": 1766252669, "currency": "usd", "customer": "cus_TdRqd1D0i7ZGBL", "livemode": false, "metadata": {"type": "wallet_deposit", "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "transaction_id": "TXN20251220877328"}, "shipping": null, "processing": null, "application": null, "canceled_at": null, "description": "Wallet deposit for transaction TXN20251220877328", "next_action": null, "on_behalf_of": null, "client_secret": "pi_3SgUCfFU6W2alheK0WSlW80h_secret_EVarS5bQhxZSLPQ5yrkjqDe4g", "latest_charge": "py_3SgUCfFU6W2alheK08Y7xH8c", "receipt_email": null, "transfer_data": null, "amount_details": {"tip": {}}, "capture_method": "automatic_async", "payment_method": "pm_1SgUDiFU6W2alheKTuz9FSZq", "transfer_group": null, "amount_received": 500000, "customer_account": null, "amount_capturable": 0, "last_payment_error": null, "setup_future_usage": null, "cancellation_reason": null, "confirmation_method": "automatic", "payment_method_types": ["card", "klarna", "link", "affirm", "cashapp", "amazon_pay"], "statement_descriptor": null, "application_fee_amount": null, "payment_method_options": {"card": {"network": null, "installments": null, "mandate_options": null, "request_three_d_secure": "automatic"}, "link": {"persistent_token": null}, "affirm": {}, "klarna": {"preferred_locale": null}, "cashapp": {}, "amazon_pay": {"express_checkout_element_session_id": null}}, "automatic_payment_methods": {"enabled": true, "allow_redirects": "always"}, "statement_descriptor_suffix": null, "excluded_payment_method_types": null, "payment_method_configuration_details": {"id": "pmc_1Sf11kFU6W2alheK0rGIa7ih", "parent": null}}, "stripe_payment_intent_id": "pi_3SgUCfFU6W2alheK0WSlW80h"}	{status,updated_at,processed_at,payment_gateway_response}	\N	\N	\N	2025-12-20 23:15:42.299032+05:30
a37cca1a-478c-49ea-bec8-da70fd952605	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T00:52:57.403474+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T23:27:47.765003+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T00:52:59.25339+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T23:27:47.765003+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at}	\N	\N	\N	2025-12-20 00:52:59.25339+05:30
70569e29-d583-411f-8ad8-0b5c96e93428	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T00:52:59.25339+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T23:27:47.765003+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T00:52:59.687433+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T23:27:47.765003+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at}	\N	\N	\N	2025-12-20 00:52:59.687433+05:30
68e3d0d8-3262-4332-9284-9dca451ba760	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T00:52:59.687433+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T23:27:47.765003+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T00:53:30.8826+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T23:27:47.765003+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at}	\N	\N	\N	2025-12-20 00:53:30.8826+05:30
50365431-a780-4b76-9b43-da95a6eeb2d4	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T00:53:30.8826+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T23:27:47.765003+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T02:18:26.571+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T23:27:47.765003+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at}	\N	\N	\N	2025-12-20 02:18:26.571+05:30
6ae6dca8-c689-451c-a77a-e47fdc3b4ebf	wallets	UPDATE	18bee39e-ad39-499c-9495-d7416d7a8d7e	\N	{"id": "18bee39e-ad39-499c-9495-d7416d7a8d7e", "balance": 0.00, "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "currency": "SLL", "created_at": "2025-12-19T23:27:35.419864+05:30", "updated_at": "2025-12-19T23:27:35.419864+05:30", "last_transaction_at": null}	{"id": "18bee39e-ad39-499c-9495-d7416d7a8d7e", "balance": 5000.00, "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "currency": "SLL", "created_at": "2025-12-19T23:27:35.419864+05:30", "updated_at": "2025-12-20T23:15:42.299032+05:30", "last_transaction_at": "2025-12-20T23:15:42.299032+05:30"}	{balance,updated_at,last_transaction_at}	\N	\N	\N	2025-12-20 23:15:42.299032+05:30
ca1784bc-7937-449e-9c17-ab8806c96d3c	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T02:18:26.571+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T23:27:47.765003+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T02:21:28.335145+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T23:27:47.765003+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at}	\N	\N	\N	2025-12-20 02:21:28.335145+05:30
bed0e308-35ae-459c-b865-125c9934cd60	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T02:21:28.335145+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T23:27:47.765003+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T02:29:55.414699+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T02:29:55.414699+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-20 02:29:55.414699+05:30
0577b43d-daf7-400d-acf1-419a42016acf	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T02:29:55.414699+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T02:29:55.414699+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T02:41:12.879298+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T02:29:55.414699+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,stripe_customer_id}	\N	\N	\N	2025-12-20 02:41:12.879298+05:30
27e82001-930f-4868-939a-801c204474fc	transactions	INSERT	cbbaa30d-ec74-43b0-9d79-164009ede753	\N	\N	{"id": "cbbaa30d-ec74-43b0-9d79-164009ede753", "fee": 0.00, "type": "DEPOSIT", "amount": 5000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgB0OFU6W2alheK143Wh2Co"}, "failed_at": null, "reference": null, "created_at": "2025-12-20T02:44:31.739968+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 5000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-20T02:44:31.739968+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251220496194", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SgB0OFU6W2alheK143Wh2Co"}	\N	\N	\N	\N	2025-12-20 02:44:31.739968+05:30
4527f82e-0333-4b77-93ab-ff155617d86f	transactions	INSERT	15ba9b69-33f9-4d6b-9ace-d7c87851c444	\N	\N	{"id": "15ba9b69-33f9-4d6b-9ace-d7c87851c444", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgB6SFU6W2alheK2HvNI2BW"}, "failed_at": null, "reference": null, "created_at": "2025-12-20T02:50:47.571881+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-20T02:50:47.571881+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251220796792", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SgB6SFU6W2alheK2HvNI2BW"}	\N	\N	\N	\N	2025-12-20 02:50:47.571881+05:30
10927dfc-e490-439f-ae87-8814d017ff01	transactions	INSERT	fbcdf221-f025-4dc8-b733-0a371631a4ae	\N	\N	{"id": "fbcdf221-f025-4dc8-b733-0a371631a4ae", "fee": 0.00, "type": "DEPOSIT", "amount": 5000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgB9PFU6W2alheK0Bj4miDO"}, "failed_at": null, "reference": null, "created_at": "2025-12-20T02:53:50.710051+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 5000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-20T02:53:50.710051+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251220828502", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SgB9PFU6W2alheK0Bj4miDO"}	\N	\N	\N	\N	2025-12-20 02:53:50.710051+05:30
d4feeef8-098e-4837-b959-3e33431c2ee3	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T02:41:12.879298+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T02:29:55.414699+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T11:22:19.13124+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T11:22:19.13124+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-20 11:22:19.13124+05:30
025167c8-b99d-4ba5-b52f-5ac806d8ab65	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-20T00:52:47.532001+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T00:52:47.532001+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-20T11:44:08.611144+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T11:44:08.611144+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-20 11:44:08.611144+05:30
5425a324-af3e-4842-b8a8-b9f1408bc923	transactions	INSERT	b9826215-a617-43ce-81fc-3feb89fe405a	\N	\N	{"id": "b9826215-a617-43ce-81fc-3feb89fe405a", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgJTjFU6W2alheK04kq6Txc"}, "failed_at": null, "reference": null, "created_at": "2025-12-20T11:47:23.005085+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-20T11:47:23.005085+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251220841845", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SgJTjFU6W2alheK04kq6Txc"}	\N	\N	\N	\N	2025-12-20 11:47:23.005085+05:30
5bf7d6e7-611a-49fe-a460-2345a3607fdc	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-20T11:44:08.611144+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T11:44:08.611144+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-20T11:52:17.194289+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T11:52:17.194289+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-20 11:52:17.194289+05:30
1f2a6cb8-d2da-46d9-b0d4-cc6166825455	users	INSERT	6b864809-fb5a-4a1f-a95e-edf87b7eeb5c	\N	\N	{"id": "6b864809-fb5a-4a1f-a95e-edf87b7eeb5c", "role": "USER", "email": "sc@tcc.com", "phone": "9874654326", "is_active": true, "last_name": "Sachin", "created_at": "2025-12-20T12:41:17.907469+05:30", "first_name": "Sachin", "kyc_status": "PENDING", "updated_at": "2025-12-20T12:41:17.907469+05:30", "is_verified": false, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": null, "password_hash": "$2b$10$WtQeSHT5Kj4FLVfnPgVbH.OP2f04HBM2Vt7rjC8sD5JyAbGG7VQzi", "referral_code": "7QAKQMZS", "email_verified": false, "phone_verified": false, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	\N	\N	\N	\N	2025-12-20 12:41:17.907469+05:30
c8ec6a2d-1d6b-471f-9f8a-289a76a9b1f8	wallets	INSERT	0d005204-f0c0-4085-b073-9d3ffa148b1d	\N	\N	{"id": "0d005204-f0c0-4085-b073-9d3ffa148b1d", "balance": 0.00, "user_id": "6b864809-fb5a-4a1f-a95e-edf87b7eeb5c", "currency": "SLL", "created_at": "2025-12-20T12:41:17.937744+05:30", "updated_at": "2025-12-20T12:41:17.937744+05:30", "last_transaction_at": null}	\N	\N	\N	\N	2025-12-20 12:41:17.937744+05:30
dc265bd7-8da5-458d-beab-81650492d230	users	UPDATE	6b864809-fb5a-4a1f-a95e-edf87b7eeb5c	\N	{"id": "6b864809-fb5a-4a1f-a95e-edf87b7eeb5c", "role": "USER", "email": "sc@tcc.com", "phone": "9874654326", "is_active": true, "last_name": "Sachin", "created_at": "2025-12-20T12:41:17.907469+05:30", "first_name": "Sachin", "kyc_status": "PENDING", "updated_at": "2025-12-20T12:41:17.907469+05:30", "is_verified": false, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": null, "password_hash": "$2b$10$WtQeSHT5Kj4FLVfnPgVbH.OP2f04HBM2Vt7rjC8sD5JyAbGG7VQzi", "referral_code": "7QAKQMZS", "email_verified": false, "phone_verified": false, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "6b864809-fb5a-4a1f-a95e-edf87b7eeb5c", "role": "USER", "email": "sc@tcc.com", "phone": "9874654326", "is_active": true, "last_name": "Sachin", "created_at": "2025-12-20T12:41:17.907469+05:30", "first_name": "Sachin", "kyc_status": "PENDING", "updated_at": "2025-12-20T12:41:33.569188+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T12:41:33.569188+05:30", "password_hash": "$2b$10$WtQeSHT5Kj4FLVfnPgVbH.OP2f04HBM2Vt7rjC8sD5JyAbGG7VQzi", "referral_code": "7QAKQMZS", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,is_verified,last_login_at,phone_verified}	\N	\N	\N	2025-12-20 12:41:33.569188+05:30
79f6c607-0599-4c23-86ae-437ae58f59fe	users	UPDATE	6b864809-fb5a-4a1f-a95e-edf87b7eeb5c	\N	{"id": "6b864809-fb5a-4a1f-a95e-edf87b7eeb5c", "role": "USER", "email": "sc@tcc.com", "phone": "9874654326", "is_active": true, "last_name": "Sachin", "created_at": "2025-12-20T12:41:17.907469+05:30", "first_name": "Sachin", "kyc_status": "PENDING", "updated_at": "2025-12-20T12:41:33.569188+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T12:41:33.569188+05:30", "password_hash": "$2b$10$WtQeSHT5Kj4FLVfnPgVbH.OP2f04HBM2Vt7rjC8sD5JyAbGG7VQzi", "referral_code": "7QAKQMZS", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "6b864809-fb5a-4a1f-a95e-edf87b7eeb5c", "role": "USER", "email": "sc@tcc.com", "phone": "9874654326", "is_active": true, "last_name": "Sachin", "created_at": "2025-12-20T12:41:17.907469+05:30", "first_name": "Sachin", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T12:42:10.248081+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T12:41:33.569188+05:30", "password_hash": "$2b$10$WtQeSHT5Kj4FLVfnPgVbH.OP2f04HBM2Vt7rjC8sD5JyAbGG7VQzi", "referral_code": "7QAKQMZS", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{kyc_status,updated_at}	\N	\N	\N	2025-12-20 12:42:10.248081+05:30
1cc57c74-56aa-4d7a-9714-d7efc476176b	users	UPDATE	6b864809-fb5a-4a1f-a95e-edf87b7eeb5c	\N	{"id": "6b864809-fb5a-4a1f-a95e-edf87b7eeb5c", "role": "USER", "email": "sc@tcc.com", "phone": "9874654326", "is_active": true, "last_name": "Sachin", "created_at": "2025-12-20T12:41:17.907469+05:30", "first_name": "Sachin", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T12:42:10.248081+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T12:41:33.569188+05:30", "password_hash": "$2b$10$WtQeSHT5Kj4FLVfnPgVbH.OP2f04HBM2Vt7rjC8sD5JyAbGG7VQzi", "referral_code": "7QAKQMZS", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "6b864809-fb5a-4a1f-a95e-edf87b7eeb5c", "role": "USER", "email": "sc@tcc.com", "phone": "9874654326", "is_active": true, "last_name": "Sachin", "created_at": "2025-12-20T12:41:17.907469+05:30", "first_name": "Sachin", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T12:44:56.197725+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T12:41:33.569188+05:30", "password_hash": "$2b$10$WtQeSHT5Kj4FLVfnPgVbH.OP2f04HBM2Vt7rjC8sD5JyAbGG7VQzi", "referral_code": "7QAKQMZS", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdbaXPCzdHoRVV", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,stripe_customer_id}	\N	\N	\N	2025-12-20 12:44:56.197725+05:30
8d2f5fcf-8b81-49a7-a01e-db015b981b99	transactions	INSERT	9c8a8cab-dc4c-47d9-8544-bf5b2e52317b	\N	\N	{"id": "9c8a8cab-dc4c-47d9-8544-bf5b2e52317b", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgKNQFU6W2alheK1dEHXU8q"}, "failed_at": null, "reference": null, "created_at": "2025-12-20T12:44:56.208476+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "6b864809-fb5a-4a1f-a95e-edf87b7eeb5c", "updated_at": "2025-12-20T12:44:56.208476+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251220656959", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SgKNQFU6W2alheK1dEHXU8q"}	\N	\N	\N	\N	2025-12-20 12:44:56.208476+05:30
89aa4a45-8256-41cf-a764-b1d663b7e7da	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-20T11:52:17.194289+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T11:52:17.194289+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-20T14:11:39.349491+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T14:11:39.349491+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-20 14:11:39.349491+05:30
97a75043-f83a-44a7-8a35-d590ebf3a548	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-20T14:11:39.349491+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T14:11:39.349491+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-20T15:39:49.671156+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T15:39:49.671156+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-20 15:39:49.671156+05:30
8ef93ee2-1ae5-464a-8c04-db5f02b1af6e	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T11:22:19.13124+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T11:22:19.13124+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T15:49:24.29749+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T15:49:24.29749+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-20 15:49:24.29749+05:30
68b5346f-dfc6-4391-ac3c-c71546008332	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-20T15:39:49.671156+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T15:39:49.671156+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-20T16:52:25.498098+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T16:52:25.498098+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-20 16:52:25.498098+05:30
81a154da-a756-424a-a28e-98b683d507ca	users	UPDATE	6b864809-fb5a-4a1f-a95e-edf87b7eeb5c	\N	{"id": "6b864809-fb5a-4a1f-a95e-edf87b7eeb5c", "role": "USER", "email": "sc@tcc.com", "phone": "9874654326", "is_active": true, "last_name": "Sachin", "created_at": "2025-12-20T12:41:17.907469+05:30", "first_name": "Sachin", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T12:44:56.197725+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T12:41:33.569188+05:30", "password_hash": "$2b$10$WtQeSHT5Kj4FLVfnPgVbH.OP2f04HBM2Vt7rjC8sD5JyAbGG7VQzi", "referral_code": "7QAKQMZS", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdbaXPCzdHoRVV", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "6b864809-fb5a-4a1f-a95e-edf87b7eeb5c", "role": "USER", "email": "sc@tcc.com", "phone": "9874654326", "is_active": true, "last_name": "Sachin", "created_at": "2025-12-20T12:41:17.907469+05:30", "first_name": "Sachin", "kyc_status": "APPROVED", "updated_at": "2025-12-20T17:02:40.2427+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T12:41:33.569188+05:30", "password_hash": "$2b$10$WtQeSHT5Kj4FLVfnPgVbH.OP2f04HBM2Vt7rjC8sD5JyAbGG7VQzi", "referral_code": "7QAKQMZS", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdbaXPCzdHoRVV", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{kyc_status,updated_at}	\N	\N	\N	2025-12-20 17:02:40.2427+05:30
8acecd7b-c21b-4ff9-b8e6-77871f3ed761	wallets	UPDATE	18bee39e-ad39-499c-9495-d7416d7a8d7e	\N	{"id": "18bee39e-ad39-499c-9495-d7416d7a8d7e", "balance": 5000.00, "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "currency": "SLL", "created_at": "2025-12-19T23:27:35.419864+05:30", "updated_at": "2025-12-20T23:15:42.299032+05:30", "last_transaction_at": "2025-12-20T23:15:42.299032+05:30"}	{"id": "18bee39e-ad39-499c-9495-d7416d7a8d7e", "balance": 10000.00, "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "currency": "SLL", "created_at": "2025-12-19T23:27:35.419864+05:30", "updated_at": "2025-12-20T23:15:42.299032+05:30", "last_transaction_at": "2025-12-20T23:15:42.299032+05:30"}	{balance}	\N	\N	\N	2025-12-20 23:15:42.299032+05:30
71fee595-4bae-4b9d-a46e-6ecaee297387	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T15:49:24.29749+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T15:49:24.29749+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "REJECTED", "updated_at": "2025-12-20T17:03:01.067975+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T15:49:24.29749+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{kyc_status,updated_at}	\N	\N	\N	2025-12-20 17:03:01.067975+05:30
26aedde4-bdfc-4c30-bbe4-77d2b3174f57	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "REJECTED", "updated_at": "2025-12-20T17:03:01.067975+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T15:49:24.29749+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "REJECTED", "updated_at": "2025-12-20T17:08:13.061877+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T17:08:13.061877+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-20 17:08:13.061877+05:30
f546303a-00b2-4479-9666-8fff88c8ba27	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "REJECTED", "updated_at": "2025-12-20T17:08:13.061877+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T17:08:13.061877+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "REJECTED", "updated_at": "2025-12-20T17:19:14.976721+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T17:19:14.976721+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-20 17:19:14.976721+05:30
1b633173-a53e-4bce-832f-2572e05b15c1	transactions	INSERT	abdc8355-93ed-4f9d-874d-706679eb0a19	\N	\N	{"id": "abdc8355-93ed-4f9d-874d-706679eb0a19", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgOksFU6W2alheK1cWUh0HV"}, "failed_at": null, "reference": null, "created_at": "2025-12-20T17:25:26.271234+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-20T17:25:26.271234+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251220430438", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SgOksFU6W2alheK1cWUh0HV"}	\N	\N	\N	\N	2025-12-20 17:25:26.271234+05:30
0d3b419c-a939-42e0-ad57-b598410b4896	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-20T16:52:25.498098+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T16:52:25.498098+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-20T20:26:10.463427+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T20:26:10.463427+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-20 20:26:10.463427+05:30
56f3ec77-4df0-411c-bdf9-c0e05ea4f1c3	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "REJECTED", "updated_at": "2025-12-20T17:19:14.976721+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T17:19:14.976721+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T17:29:37.07915+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T17:19:14.976721+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{kyc_status,updated_at}	\N	\N	\N	2025-12-20 17:29:37.07915+05:30
090e677c-6e25-44c4-aec4-612b491daf41	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T17:29:37.07915+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T17:19:14.976721+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T17:33:02.134461+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T17:33:02.134461+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-20 17:33:02.134461+05:30
d0d4b7cc-22af-4b1c-83f8-48282f680509	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T17:33:02.134461+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T17:33:02.134461+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T18:34:21.924134+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T18:34:21.924134+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-20 18:34:21.924134+05:30
7d53d03a-0172-4cb4-bda2-4e20f0218c2d	transactions	INSERT	9d785e38-2bba-4c79-9029-d864b34614cf	\N	\N	{"id": "9d785e38-2bba-4c79-9029-d864b34614cf", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgPz3FU6W2alheK0J95Rbbt"}, "failed_at": null, "reference": null, "created_at": "2025-12-20T18:44:09.049454+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-20T18:44:09.049454+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251220839001", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SgPz3FU6W2alheK0J95Rbbt"}	\N	\N	\N	\N	2025-12-20 18:44:09.049454+05:30
440af1e2-4fab-4be9-ad80-f6ede92b9702	transactions	INSERT	20a842d9-7326-40f2-b891-5cc0421ac046	\N	\N	{"id": "20a842d9-7326-40f2-b891-5cc0421ac046", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgQ79FU6W2alheK2whcSeu9"}, "failed_at": null, "reference": null, "created_at": "2025-12-20T18:52:30.74457+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-20T18:52:30.74457+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251220823739", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SgQ79FU6W2alheK2whcSeu9"}	\N	\N	\N	\N	2025-12-20 18:52:30.74457+05:30
b05e2eed-1b56-4463-a5ae-08311d3e1e3f	users	INSERT	8c6b2a0e-9b12-49db-8a5f-8dcb58572d72	\N	\N	{"id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "role": "USER", "email": "sh@tcc.com", "phone": "9876543216", "is_active": true, "last_name": "Test", "created_at": "2025-12-20T23:40:21.217414+05:30", "first_name": "Shashank", "kyc_status": "PENDING", "updated_at": "2025-12-20T23:40:21.217414+05:30", "is_verified": false, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": null, "password_hash": "$2b$10$rnMGhNFz4hBQDqUmcbiBlO47qzrgETF11pJ2niLJPoRW7EwJeMhEi", "referral_code": "4QHXP44K", "email_verified": false, "phone_verified": false, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	\N	\N	\N	\N	2025-12-20 23:40:21.217414+05:30
d2312457-fffa-4f6c-8bb0-dc756ca9f9ab	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T18:34:21.924134+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T18:34:21.924134+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T20:46:09.018518+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T20:46:09.018518+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-20 20:46:09.018518+05:30
deff6826-d00d-42c2-9dba-4d3b367bb013	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-20T20:26:10.463427+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T20:26:10.463427+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-20T21:35:08.802198+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T21:35:08.802198+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-20 21:35:08.802198+05:30
9e9b3c6a-0d21-4b0f-a101-f8013ee2df60	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T20:46:09.018518+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T20:46:09.018518+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-20T21:41:59.838666+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T20:46:09.018518+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{kyc_status,updated_at}	\N	\N	\N	2025-12-20 21:41:59.838666+05:30
452ba5e2-9491-4e6a-900d-ebafc96a203b	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-20T21:41:59.838666+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T20:46:09.018518+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-20T22:01:14.854084+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T22:01:14.854084+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-20 22:01:14.854084+05:30
6e737113-040b-4cfa-abca-5b1ee44c7691	transactions	INSERT	24d14952-1bd5-4329-b56d-130adaf3feb2	\N	\N	{"id": "24d14952-1bd5-4329-b56d-130adaf3feb2", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgT48FU6W2alheK0J0MZCZ3"}, "failed_at": null, "reference": null, "created_at": "2025-12-20T22:01:35.991015+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-20T22:01:35.991015+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251220441415", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SgT48FU6W2alheK0J0MZCZ3"}	\N	\N	\N	\N	2025-12-20 22:01:35.991015+05:30
b5a51cff-ff48-43be-a49e-15455221b821	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-20T21:35:08.802198+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T21:35:08.802198+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-20T22:33:02.936209+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T22:33:02.936209+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-20 22:33:02.936209+05:30
0eb15475-a378-4e99-b75d-cdde4d274d57	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-20T22:01:14.854084+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T22:01:14.854084+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-20T22:55:12.153826+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T22:55:12.153826+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-20 22:55:12.153826+05:30
b99d6713-7fc6-486a-97f2-fcb8e21cfb62	transactions	INSERT	bb113d54-c898-4c34-ae2e-1c6ac4211c52	\N	\N	{"id": "bb113d54-c898-4c34-ae2e-1c6ac4211c52", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgTu9FU6W2alheK1F2QmI6i"}, "failed_at": null, "reference": null, "created_at": "2025-12-20T22:55:21.05097+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-20T22:55:21.05097+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251220509304", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SgTu9FU6W2alheK1F2QmI6i"}	\N	\N	\N	\N	2025-12-20 22:55:21.05097+05:30
2bc719fc-44c3-40d8-a6e5-29ca3d87d498	transactions	INSERT	079f4028-5fec-455e-a14a-b7291fb8e21b	\N	\N	{"id": "079f4028-5fec-455e-a14a-b7291fb8e21b", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgU42FU6W2alheK18wXO0CW"}, "failed_at": null, "reference": null, "created_at": "2025-12-20T23:05:33.861477+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-20T23:05:33.861477+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251220112997", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SgU42FU6W2alheK18wXO0CW"}	\N	\N	\N	\N	2025-12-20 23:05:33.861477+05:30
917c08e2-f0ad-47f1-8b2f-96867267cfe6	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-20T22:55:12.153826+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T22:55:12.153826+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-20T23:14:21.921729+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T23:14:21.921729+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-20 23:14:21.921729+05:30
9231a4ed-b225-40c2-945f-fc2c67fc995c	transactions	INSERT	ba5b7d98-7059-4496-871f-d0e784155551	\N	\N	{"id": "ba5b7d98-7059-4496-871f-d0e784155551", "fee": 0.00, "type": "DEPOSIT", "amount": 5000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgUCfFU6W2alheK0WSlW80h"}, "failed_at": null, "reference": null, "created_at": "2025-12-20T23:14:28.860063+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 5000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-20T23:14:28.860063+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251220877328", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SgUCfFU6W2alheK0WSlW80h"}	\N	\N	\N	\N	2025-12-20 23:14:28.860063+05:30
36fdeaae-2dd3-40c3-af6e-57f94d71c2cc	users	UPDATE	8c6b2a0e-9b12-49db-8a5f-8dcb58572d72	\N	{"id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "role": "USER", "email": "sh@tcc.com", "phone": "9876543216", "is_active": true, "last_name": "Test", "created_at": "2025-12-20T23:40:21.217414+05:30", "first_name": "Shashank", "kyc_status": "PENDING", "updated_at": "2025-12-20T23:40:21.217414+05:30", "is_verified": false, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": null, "password_hash": "$2b$10$rnMGhNFz4hBQDqUmcbiBlO47qzrgETF11pJ2niLJPoRW7EwJeMhEi", "referral_code": "4QHXP44K", "email_verified": false, "phone_verified": false, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "role": "USER", "email": "sh@tcc.com", "phone": "9876543216", "is_active": true, "last_name": "Test", "created_at": "2025-12-20T23:40:21.217414+05:30", "first_name": "Shashank", "kyc_status": "PENDING", "updated_at": "2025-12-20T23:40:28.359477+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T23:40:28.359477+05:30", "password_hash": "$2b$10$rnMGhNFz4hBQDqUmcbiBlO47qzrgETF11pJ2niLJPoRW7EwJeMhEi", "referral_code": "4QHXP44K", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,is_verified,last_login_at,phone_verified}	\N	\N	\N	2025-12-20 23:40:28.359477+05:30
5da1c9fa-2e8a-423e-bbf5-5ab273efb5ab	users	UPDATE	8c6b2a0e-9b12-49db-8a5f-8dcb58572d72	\N	{"id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "role": "USER", "email": "sh@tcc.com", "phone": "9876543216", "is_active": true, "last_name": "Test", "created_at": "2025-12-20T23:40:21.217414+05:30", "first_name": "Shashank", "kyc_status": "PENDING", "updated_at": "2025-12-20T23:40:28.359477+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T23:40:28.359477+05:30", "password_hash": "$2b$10$rnMGhNFz4hBQDqUmcbiBlO47qzrgETF11pJ2niLJPoRW7EwJeMhEi", "referral_code": "4QHXP44K", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "role": "USER", "email": "sh@tcc.com", "phone": "9876543216", "is_active": true, "last_name": "Test", "created_at": "2025-12-20T23:40:21.217414+05:30", "first_name": "Shashank", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T23:43:25.668591+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T23:40:28.359477+05:30", "password_hash": "$2b$10$rnMGhNFz4hBQDqUmcbiBlO47qzrgETF11pJ2niLJPoRW7EwJeMhEi", "referral_code": "4QHXP44K", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{kyc_status,updated_at}	\N	\N	\N	2025-12-20 23:43:25.668591+05:30
d042b263-8c13-47a5-b95a-90222f513712	users	UPDATE	8c6b2a0e-9b12-49db-8a5f-8dcb58572d72	\N	{"id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "role": "USER", "email": "sh@tcc.com", "phone": "9876543216", "is_active": true, "last_name": "Test", "created_at": "2025-12-20T23:40:21.217414+05:30", "first_name": "Shashank", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T23:43:25.668591+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T23:40:28.359477+05:30", "password_hash": "$2b$10$rnMGhNFz4hBQDqUmcbiBlO47qzrgETF11pJ2niLJPoRW7EwJeMhEi", "referral_code": "4QHXP44K", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "role": "USER", "email": "sh@tcc.com", "phone": "9876543216", "is_active": true, "last_name": "Test", "created_at": "2025-12-20T23:40:21.217414+05:30", "first_name": "Shashank", "kyc_status": "REJECTED", "updated_at": "2025-12-20T23:46:43.364045+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T23:40:28.359477+05:30", "password_hash": "$2b$10$rnMGhNFz4hBQDqUmcbiBlO47qzrgETF11pJ2niLJPoRW7EwJeMhEi", "referral_code": "4QHXP44K", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{kyc_status,updated_at}	\N	\N	\N	2025-12-20 23:46:43.364045+05:30
c717f2fd-ae8f-45a2-ba5e-508438732f92	users	UPDATE	8c6b2a0e-9b12-49db-8a5f-8dcb58572d72	\N	{"id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "role": "USER", "email": "sh@tcc.com", "phone": "9876543216", "is_active": true, "last_name": "Test", "created_at": "2025-12-20T23:40:21.217414+05:30", "first_name": "Shashank", "kyc_status": "REJECTED", "updated_at": "2025-12-20T23:46:43.364045+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T23:40:28.359477+05:30", "password_hash": "$2b$10$rnMGhNFz4hBQDqUmcbiBlO47qzrgETF11pJ2niLJPoRW7EwJeMhEi", "referral_code": "4QHXP44K", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "role": "USER", "email": "sh@tcc.com", "phone": "9876543216", "is_active": true, "last_name": "Test", "created_at": "2025-12-20T23:40:21.217414+05:30", "first_name": "Shashank", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T23:48:02.314239+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T23:40:28.359477+05:30", "password_hash": "$2b$10$rnMGhNFz4hBQDqUmcbiBlO47qzrgETF11pJ2niLJPoRW7EwJeMhEi", "referral_code": "4QHXP44K", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{kyc_status,updated_at}	\N	\N	\N	2025-12-20 23:48:02.314239+05:30
761c9fa9-c2a6-4785-9b40-656a3d612d42	wallets	UPDATE	18bee39e-ad39-499c-9495-d7416d7a8d7e	\N	{"id": "18bee39e-ad39-499c-9495-d7416d7a8d7e", "balance": 10000.00, "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "currency": "SLL", "created_at": "2025-12-19T23:27:35.419864+05:30", "updated_at": "2025-12-20T23:15:42.299032+05:30", "last_transaction_at": "2025-12-20T23:15:42.299032+05:30"}	{"id": "18bee39e-ad39-499c-9495-d7416d7a8d7e", "balance": 11005.00, "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "currency": "SLL", "created_at": "2025-12-19T23:27:35.419864+05:30", "updated_at": "2025-12-22T19:56:23.675968+05:30", "last_transaction_at": "2025-12-22T19:56:23.675968+05:30"}	{balance,updated_at,last_transaction_at}	\N	\N	\N	2025-12-22 19:56:23.675968+05:30
ebdfa1ee-43ca-4c1d-ad59-0e5e72db9437	users	UPDATE	8c6b2a0e-9b12-49db-8a5f-8dcb58572d72	\N	{"id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "role": "USER", "email": "sh@tcc.com", "phone": "9876543216", "is_active": true, "last_name": "Test", "created_at": "2025-12-20T23:40:21.217414+05:30", "first_name": "Shashank", "kyc_status": "SUBMITTED", "updated_at": "2025-12-20T23:48:02.314239+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T23:40:28.359477+05:30", "password_hash": "$2b$10$rnMGhNFz4hBQDqUmcbiBlO47qzrgETF11pJ2niLJPoRW7EwJeMhEi", "referral_code": "4QHXP44K", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "role": "USER", "email": "sh@tcc.com", "phone": "9876543216", "is_active": true, "last_name": "Test", "created_at": "2025-12-20T23:40:21.217414+05:30", "first_name": "Shashank", "kyc_status": "APPROVED", "updated_at": "2025-12-20T23:48:42.866779+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T23:40:28.359477+05:30", "password_hash": "$2b$10$rnMGhNFz4hBQDqUmcbiBlO47qzrgETF11pJ2niLJPoRW7EwJeMhEi", "referral_code": "4QHXP44K", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{kyc_status,updated_at}	\N	\N	\N	2025-12-20 23:48:42.866779+05:30
ce798bfc-0745-4e87-9b12-8681bdc5615e	users	UPDATE	8c6b2a0e-9b12-49db-8a5f-8dcb58572d72	\N	{"id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "role": "USER", "email": "sh@tcc.com", "phone": "9876543216", "is_active": true, "last_name": "Test", "created_at": "2025-12-20T23:40:21.217414+05:30", "first_name": "Shashank", "kyc_status": "APPROVED", "updated_at": "2025-12-20T23:48:42.866779+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T23:40:28.359477+05:30", "password_hash": "$2b$10$rnMGhNFz4hBQDqUmcbiBlO47qzrgETF11pJ2niLJPoRW7EwJeMhEi", "referral_code": "4QHXP44K", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "role": "USER", "email": "sh@tcc.com", "phone": "9876543216", "is_active": true, "last_name": "Test", "created_at": "2025-12-20T23:40:21.217414+05:30", "first_name": "Shashank", "kyc_status": "APPROVED", "updated_at": "2025-12-20T23:50:34.733616+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T23:40:28.359477+05:30", "password_hash": "$2b$10$rnMGhNFz4hBQDqUmcbiBlO47qzrgETF11pJ2niLJPoRW7EwJeMhEi", "referral_code": "4QHXP44K", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdmKrXUlEg83LB", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,stripe_customer_id}	\N	\N	\N	2025-12-20 23:50:34.733616+05:30
a40c4500-de3f-43fc-9b9b-71cc1e157782	transactions	INSERT	fa3977bf-3f0d-4e0c-b517-da29a18325fd	\N	\N	{"id": "fa3977bf-3f0d-4e0c-b517-da29a18325fd", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgUlbFU6W2alheK1WRzctwD"}, "failed_at": null, "reference": null, "created_at": "2025-12-20T23:50:34.741076+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "updated_at": "2025-12-20T23:50:34.741076+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251220130622", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SgUlbFU6W2alheK1WRzctwD"}	\N	\N	\N	\N	2025-12-20 23:50:34.741076+05:30
6ede4865-ae44-4f5e-ab7d-b77b60b6170a	transactions	UPDATE	fa3977bf-3f0d-4e0c-b517-da29a18325fd	\N	{"id": "fa3977bf-3f0d-4e0c-b517-da29a18325fd", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgUlbFU6W2alheK1WRzctwD"}, "failed_at": null, "reference": null, "created_at": "2025-12-20T23:50:34.741076+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "updated_at": "2025-12-20T23:50:34.741076+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251220130622", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SgUlbFU6W2alheK1WRzctwD"}	{"id": "fa3977bf-3f0d-4e0c-b517-da29a18325fd", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "COMPLETED", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgUlbFU6W2alheK1WRzctwD"}, "failed_at": null, "reference": null, "created_at": "2025-12-20T23:50:34.741076+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "updated_at": "2025-12-20T23:50:49.878194+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": "2025-12-20T23:50:49.878194+05:30", "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251220130622", "payment_gateway_response": {"id": "pi_3SgUlbFU6W2alheK1WRzctwD", "amount": 100000, "object": "payment_intent", "review": null, "source": null, "status": "succeeded", "created": 1766254835, "currency": "usd", "customer": "cus_TdmKrXUlEg83LB", "livemode": false, "metadata": {"type": "wallet_deposit", "user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "transaction_id": "TXN20251220130622"}, "shipping": null, "processing": null, "application": null, "canceled_at": null, "description": "Wallet deposit for transaction TXN20251220130622", "next_action": null, "on_behalf_of": null, "client_secret": "pi_3SgUlbFU6W2alheK1WRzctwD_secret_aMoYHI8h2zR3BguJmMI8sQQZw", "latest_charge": "py_3SgUlbFU6W2alheK108qxsby", "receipt_email": null, "transfer_data": null, "amount_details": {"tip": {}}, "capture_method": "automatic_async", "payment_method": "pm_1SgUlgFU6W2alheK4TwnJRQb", "transfer_group": null, "amount_received": 100000, "customer_account": null, "amount_capturable": 0, "last_payment_error": null, "setup_future_usage": null, "cancellation_reason": null, "confirmation_method": "automatic", "payment_method_types": ["card", "klarna", "link", "affirm", "cashapp", "amazon_pay"], "statement_descriptor": null, "application_fee_amount": null, "payment_method_options": {"card": {"network": null, "installments": null, "mandate_options": null, "request_three_d_secure": "automatic"}, "link": {"persistent_token": null}, "affirm": {}, "klarna": {"preferred_locale": null}, "cashapp": {}, "amazon_pay": {"express_checkout_element_session_id": null}}, "automatic_payment_methods": {"enabled": true, "allow_redirects": "always"}, "statement_descriptor_suffix": null, "excluded_payment_method_types": null, "payment_method_configuration_details": {"id": "pmc_1Sf11kFU6W2alheK0rGIa7ih", "parent": null}}, "stripe_payment_intent_id": "pi_3SgUlbFU6W2alheK1WRzctwD"}	{status,updated_at,processed_at,payment_gateway_response}	\N	\N	\N	2025-12-20 23:50:49.878194+05:30
3f7386b5-2e17-4b1c-a1ea-a5c49b41e271	wallets	UPDATE	c0cbdf1a-f592-4bec-9dd0-7708eb2c1278	\N	{"id": "c0cbdf1a-f592-4bec-9dd0-7708eb2c1278", "balance": 0.00, "user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "currency": "SLL", "created_at": "2025-12-20T23:40:21.230675+05:30", "updated_at": "2025-12-20T23:40:21.230675+05:30", "last_transaction_at": null}	{"id": "c0cbdf1a-f592-4bec-9dd0-7708eb2c1278", "balance": 1000.00, "user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "currency": "SLL", "created_at": "2025-12-20T23:40:21.230675+05:30", "updated_at": "2025-12-20T23:50:49.878194+05:30", "last_transaction_at": "2025-12-20T23:50:49.878194+05:30"}	{balance,updated_at,last_transaction_at}	\N	\N	\N	2025-12-20 23:50:49.878194+05:30
914e83a6-01d3-4c68-b98a-bc91d33d88d2	wallets	UPDATE	c0cbdf1a-f592-4bec-9dd0-7708eb2c1278	\N	{"id": "c0cbdf1a-f592-4bec-9dd0-7708eb2c1278", "balance": 1000.00, "user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "currency": "SLL", "created_at": "2025-12-20T23:40:21.230675+05:30", "updated_at": "2025-12-20T23:50:49.878194+05:30", "last_transaction_at": "2025-12-20T23:50:49.878194+05:30"}	{"id": "c0cbdf1a-f592-4bec-9dd0-7708eb2c1278", "balance": 2000.00, "user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "currency": "SLL", "created_at": "2025-12-20T23:40:21.230675+05:30", "updated_at": "2025-12-20T23:50:49.878194+05:30", "last_transaction_at": "2025-12-20T23:50:49.878194+05:30"}	{balance}	\N	\N	\N	2025-12-20 23:50:49.878194+05:30
a85200ba-06cb-4e7e-9ba0-fbb611147b2c	transactions	INSERT	a198366f-18b4-4d9f-93ef-2374e2b77057	\N	\N	{"id": "a198366f-18b4-4d9f-93ef-2374e2b77057", "fee": 0.00, "type": "DEPOSIT", "amount": 5000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgUmMFU6W2alheK09XeD4Ux"}, "failed_at": null, "reference": null, "created_at": "2025-12-20T23:51:22.441124+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 5000.00, "to_user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "updated_at": "2025-12-20T23:51:22.441124+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251220472333", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SgUmMFU6W2alheK09XeD4Ux"}	\N	\N	\N	\N	2025-12-20 23:51:22.441124+05:30
9ba81c84-d54f-455b-8cb1-7f22e390250e	transactions	UPDATE	a198366f-18b4-4d9f-93ef-2374e2b77057	\N	{"id": "a198366f-18b4-4d9f-93ef-2374e2b77057", "fee": 0.00, "type": "DEPOSIT", "amount": 5000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgUmMFU6W2alheK09XeD4Ux"}, "failed_at": null, "reference": null, "created_at": "2025-12-20T23:51:22.441124+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 5000.00, "to_user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "updated_at": "2025-12-20T23:51:22.441124+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251220472333", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SgUmMFU6W2alheK09XeD4Ux"}	{"id": "a198366f-18b4-4d9f-93ef-2374e2b77057", "fee": 0.00, "type": "DEPOSIT", "amount": 5000.00, "status": "COMPLETED", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgUmMFU6W2alheK09XeD4Ux"}, "failed_at": null, "reference": null, "created_at": "2025-12-20T23:51:22.441124+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 5000.00, "to_user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "updated_at": "2025-12-20T23:51:36.777437+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": "2025-12-20T23:51:36.777437+05:30", "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251220472333", "payment_gateway_response": {"id": "pi_3SgUmMFU6W2alheK09XeD4Ux", "amount": 500000, "object": "payment_intent", "review": null, "source": null, "status": "succeeded", "created": 1766254882, "currency": "usd", "customer": "cus_TdmKrXUlEg83LB", "livemode": false, "metadata": {"type": "wallet_deposit", "user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "transaction_id": "TXN20251220472333"}, "shipping": null, "processing": null, "application": null, "canceled_at": null, "description": "Wallet deposit for transaction TXN20251220472333", "next_action": null, "on_behalf_of": null, "client_secret": "pi_3SgUmMFU6W2alheK09XeD4Ux_secret_K8TMXUnK9gg084hyFrZ0Xt1w5", "latest_charge": "py_3SgUmMFU6W2alheK0RrskA4N", "receipt_email": null, "transfer_data": null, "amount_details": {"tip": {}}, "capture_method": "automatic_async", "payment_method": "pm_1SgUmQFU6W2alheKFXoG8kLu", "transfer_group": null, "amount_received": 500000, "customer_account": null, "amount_capturable": 0, "last_payment_error": null, "setup_future_usage": null, "cancellation_reason": null, "confirmation_method": "automatic", "payment_method_types": ["card", "klarna", "link", "affirm", "cashapp", "amazon_pay"], "statement_descriptor": null, "application_fee_amount": null, "payment_method_options": {"card": {"network": null, "installments": null, "mandate_options": null, "request_three_d_secure": "automatic"}, "link": {"persistent_token": null}, "affirm": {}, "klarna": {"preferred_locale": null}, "cashapp": {}, "amazon_pay": {"express_checkout_element_session_id": null}}, "automatic_payment_methods": {"enabled": true, "allow_redirects": "always"}, "statement_descriptor_suffix": null, "excluded_payment_method_types": null, "payment_method_configuration_details": {"id": "pmc_1Sf11kFU6W2alheK0rGIa7ih", "parent": null}}, "stripe_payment_intent_id": "pi_3SgUmMFU6W2alheK09XeD4Ux"}	{status,updated_at,processed_at,payment_gateway_response}	\N	\N	\N	2025-12-20 23:51:36.777437+05:30
31eb499c-d475-49d6-84b8-ece70c4f7eeb	wallets	UPDATE	c0cbdf1a-f592-4bec-9dd0-7708eb2c1278	\N	{"id": "c0cbdf1a-f592-4bec-9dd0-7708eb2c1278", "balance": 2000.00, "user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "currency": "SLL", "created_at": "2025-12-20T23:40:21.230675+05:30", "updated_at": "2025-12-20T23:50:49.878194+05:30", "last_transaction_at": "2025-12-20T23:50:49.878194+05:30"}	{"id": "c0cbdf1a-f592-4bec-9dd0-7708eb2c1278", "balance": 7000.00, "user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "currency": "SLL", "created_at": "2025-12-20T23:40:21.230675+05:30", "updated_at": "2025-12-20T23:51:36.777437+05:30", "last_transaction_at": "2025-12-20T23:51:36.777437+05:30"}	{balance,updated_at,last_transaction_at}	\N	\N	\N	2025-12-20 23:51:36.777437+05:30
25e755f1-3dcb-4dc3-b229-09f187223937	wallets	UPDATE	c0cbdf1a-f592-4bec-9dd0-7708eb2c1278	\N	{"id": "c0cbdf1a-f592-4bec-9dd0-7708eb2c1278", "balance": 7000.00, "user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "currency": "SLL", "created_at": "2025-12-20T23:40:21.230675+05:30", "updated_at": "2025-12-20T23:51:36.777437+05:30", "last_transaction_at": "2025-12-20T23:51:36.777437+05:30"}	{"id": "c0cbdf1a-f592-4bec-9dd0-7708eb2c1278", "balance": 12000.00, "user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "currency": "SLL", "created_at": "2025-12-20T23:40:21.230675+05:30", "updated_at": "2025-12-20T23:51:36.777437+05:30", "last_transaction_at": "2025-12-20T23:51:36.777437+05:30"}	{balance}	\N	\N	\N	2025-12-20 23:51:36.777437+05:30
f66debda-5538-4147-a2c5-f804e5dae328	transactions	INSERT	a1f8bfd4-560d-4abc-9557-588d367bbc14	\N	\N	{"id": "a1f8bfd4-560d-4abc-9557-588d367bbc14", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgUuIFU6W2alheK2uDdXYmG"}, "failed_at": null, "reference": null, "created_at": "2025-12-20T23:59:33.488611+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "updated_at": "2025-12-20T23:59:33.488611+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251220564247", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SgUuIFU6W2alheK2uDdXYmG"}	\N	\N	\N	\N	2025-12-20 23:59:33.488611+05:30
f4f51ddf-935f-4d2e-82ad-9541117307ad	transactions	INSERT	f71ab014-e81c-450f-85fc-1ab88f23885a	\N	\N	{"id": "f71ab014-e81c-450f-85fc-1ab88f23885a", "fee": 0.00, "type": "DEPOSIT", "amount": 10000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgUusFU6W2alheK1c1HWTpY"}, "failed_at": null, "reference": null, "created_at": "2025-12-21T00:00:09.714776+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 10000.00, "to_user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "updated_at": "2025-12-21T00:00:09.714776+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251221944581", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SgUusFU6W2alheK1c1HWTpY"}	\N	\N	\N	\N	2025-12-21 00:00:09.714776+05:30
53140aa8-aa57-48f0-a617-850efc078657	transactions	UPDATE	f71ab014-e81c-450f-85fc-1ab88f23885a	\N	{"id": "f71ab014-e81c-450f-85fc-1ab88f23885a", "fee": 0.00, "type": "DEPOSIT", "amount": 10000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgUusFU6W2alheK1c1HWTpY"}, "failed_at": null, "reference": null, "created_at": "2025-12-21T00:00:09.714776+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 10000.00, "to_user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "updated_at": "2025-12-21T00:00:09.714776+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251221944581", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SgUusFU6W2alheK1c1HWTpY"}	{"id": "f71ab014-e81c-450f-85fc-1ab88f23885a", "fee": 0.00, "type": "DEPOSIT", "amount": 10000.00, "status": "COMPLETED", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SgUusFU6W2alheK1c1HWTpY"}, "failed_at": null, "reference": null, "created_at": "2025-12-21T00:00:09.714776+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 10000.00, "to_user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "updated_at": "2025-12-21T00:00:30.483263+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": "2025-12-21T00:00:30.483263+05:30", "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251221944581", "payment_gateway_response": {"id": "pi_3SgUusFU6W2alheK1c1HWTpY", "amount": 1000000, "object": "payment_intent", "review": null, "source": null, "status": "succeeded", "created": 1766255410, "currency": "usd", "customer": "cus_TdmKrXUlEg83LB", "livemode": false, "metadata": {"type": "wallet_deposit", "user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "transaction_id": "TXN20251221944581"}, "shipping": null, "processing": null, "application": null, "canceled_at": null, "description": "Wallet deposit for transaction TXN20251221944581", "next_action": null, "on_behalf_of": null, "client_secret": "pi_3SgUusFU6W2alheK1c1HWTpY_secret_4rLgfQQEqWo8SRnZah2pS0Ieb", "latest_charge": "ch_3SgUusFU6W2alheK13eTocZ4", "receipt_email": null, "transfer_data": null, "amount_details": {"tip": {}}, "capture_method": "automatic_async", "payment_method": "pm_1SgUvBFU6W2alheK7haNgtcG", "transfer_group": null, "amount_received": 1000000, "customer_account": null, "amount_capturable": 0, "last_payment_error": null, "setup_future_usage": null, "cancellation_reason": null, "confirmation_method": "automatic", "payment_method_types": ["card", "klarna", "link", "affirm", "cashapp", "amazon_pay"], "statement_descriptor": null, "application_fee_amount": null, "payment_method_options": {"card": {"network": null, "installments": null, "mandate_options": null, "request_three_d_secure": "automatic"}, "link": {"persistent_token": null}, "affirm": {}, "klarna": {"preferred_locale": null}, "cashapp": {}, "amazon_pay": {"express_checkout_element_session_id": null}}, "automatic_payment_methods": {"enabled": true, "allow_redirects": "always"}, "statement_descriptor_suffix": null, "excluded_payment_method_types": null, "payment_method_configuration_details": {"id": "pmc_1Sf11kFU6W2alheK0rGIa7ih", "parent": null}}, "stripe_payment_intent_id": "pi_3SgUusFU6W2alheK1c1HWTpY"}	{status,updated_at,processed_at,payment_gateway_response}	\N	\N	\N	2025-12-21 00:00:30.483263+05:30
313f3886-1cea-4d58-9113-228756224445	wallets	UPDATE	c0cbdf1a-f592-4bec-9dd0-7708eb2c1278	\N	{"id": "c0cbdf1a-f592-4bec-9dd0-7708eb2c1278", "balance": 12000.00, "user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "currency": "SLL", "created_at": "2025-12-20T23:40:21.230675+05:30", "updated_at": "2025-12-20T23:51:36.777437+05:30", "last_transaction_at": "2025-12-20T23:51:36.777437+05:30"}	{"id": "c0cbdf1a-f592-4bec-9dd0-7708eb2c1278", "balance": 22000.00, "user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "currency": "SLL", "created_at": "2025-12-20T23:40:21.230675+05:30", "updated_at": "2025-12-21T00:00:30.483263+05:30", "last_transaction_at": "2025-12-21T00:00:30.483263+05:30"}	{balance,updated_at,last_transaction_at}	\N	\N	\N	2025-12-21 00:00:30.483263+05:30
5c4ee19c-3bf5-46e0-8c87-fd79b5901748	wallets	UPDATE	c0cbdf1a-f592-4bec-9dd0-7708eb2c1278	\N	{"id": "c0cbdf1a-f592-4bec-9dd0-7708eb2c1278", "balance": 22000.00, "user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "currency": "SLL", "created_at": "2025-12-20T23:40:21.230675+05:30", "updated_at": "2025-12-21T00:00:30.483263+05:30", "last_transaction_at": "2025-12-21T00:00:30.483263+05:30"}	{"id": "c0cbdf1a-f592-4bec-9dd0-7708eb2c1278", "balance": 32000.00, "user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "currency": "SLL", "created_at": "2025-12-20T23:40:21.230675+05:30", "updated_at": "2025-12-21T00:00:30.483263+05:30", "last_transaction_at": "2025-12-21T00:00:30.483263+05:30"}	{balance}	\N	\N	\N	2025-12-21 00:00:30.483263+05:30
4d8dbb50-efa7-4ae8-acc7-7ef65c52ae5e	wallets	UPDATE	18bee39e-ad39-499c-9495-d7416d7a8d7e	\N	{"id": "18bee39e-ad39-499c-9495-d7416d7a8d7e", "balance": 11005.00, "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "currency": "SLL", "created_at": "2025-12-19T23:27:35.419864+05:30", "updated_at": "2025-12-22T19:56:23.675968+05:30", "last_transaction_at": "2025-12-22T19:56:23.675968+05:30"}	{"id": "18bee39e-ad39-499c-9495-d7416d7a8d7e", "balance": 12010.00, "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "currency": "SLL", "created_at": "2025-12-19T23:27:35.419864+05:30", "updated_at": "2025-12-22T19:56:23.675968+05:30", "last_transaction_at": "2025-12-22T19:56:23.675968+05:30"}	{balance}	\N	\N	\N	2025-12-22 19:56:23.675968+05:30
42d5f04c-8d5e-4eba-a916-9812efe3527a	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-20T22:33:02.936209+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T22:33:02.936209+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-22T09:51:04.138571+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-22T09:51:04.138571+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-22 09:51:04.138571+05:30
ebf48402-9d7b-4219-b0ca-b4347d2b042a	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-22T09:51:04.138571+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-22T09:51:04.138571+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-22T09:57:26.916075+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-22T09:57:26.916075+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-22 09:57:26.916075+05:30
36af860f-1941-407e-be33-747896646017	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-22T09:57:26.916075+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-22T09:57:26.916075+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-22T15:56:41.485131+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-22T15:56:41.485131+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-22 15:56:41.485131+05:30
80f69e05-e389-49d7-9363-70116b5106cd	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-22T15:56:41.485131+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-22T15:56:41.485131+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-22T15:56:41.485053+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-22T15:56:41.485053+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-22 15:56:41.485053+05:30
2825446b-9074-44ce-a839-113ad961fff0	transactions	INSERT	2e853ba0-3dcf-45fa-819c-bc0a07051669	\N	\N	{"id": "2e853ba0-3dcf-45fa-819c-bc0a07051669", "fee": 0.00, "type": "DEPOSIT", "amount": 5000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3ShWIXFU6W2alheK2CFFMr13"}, "failed_at": null, "reference": null, "created_at": "2025-12-23T19:40:49.21499+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 5000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-23T19:40:49.21499+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251223216667", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3ShWIXFU6W2alheK2CFFMr13"}	\N	\N	\N	\N	2025-12-23 19:40:49.21499+05:30
f1c0f0cb-6074-4438-9e3e-9a7bce635ff8	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-20T23:14:21.921729+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-20T23:14:21.921729+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-22T19:07:09.65618+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-22T19:07:09.65618+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-22 19:07:09.65618+05:30
b2b24efc-b609-4ab1-9297-5d4194ba5cf0	transactions	INSERT	1329af43-b7ad-4378-aa63-5d998e769e86	\N	\N	{"id": "1329af43-b7ad-4378-aa63-5d998e769e86", "fee": 0.00, "type": "DEPOSIT", "amount": 1005.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3Sh9J1FU6W2alheK25RXuvGq"}, "failed_at": null, "reference": null, "created_at": "2025-12-22T19:07:46.976626+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1005.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-22T19:07:46.976626+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251222653976", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3Sh9J1FU6W2alheK25RXuvGq"}	\N	\N	\N	\N	2025-12-22 19:07:46.976626+05:30
c7ca3341-0e01-4970-82d7-a5b27ed14eb0	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-22T15:56:41.485053+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-22T15:56:41.485053+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-22T19:22:11.27552+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-22T19:22:11.27552+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-22 19:22:11.27552+05:30
7ffb9bcb-9729-4a3d-bd57-12e2c242b436	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-22T19:22:11.27552+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-22T19:22:11.27552+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-22T19:36:40.020833+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-22T19:36:40.020833+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-22 19:36:40.020833+05:30
49bdcdef-398f-4e21-9c02-4de5004a7bdc	transactions	UPDATE	1329af43-b7ad-4378-aa63-5d998e769e86	\N	{"id": "1329af43-b7ad-4378-aa63-5d998e769e86", "fee": 0.00, "type": "DEPOSIT", "amount": 1005.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3Sh9J1FU6W2alheK25RXuvGq"}, "failed_at": null, "reference": null, "created_at": "2025-12-22T19:07:46.976626+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1005.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-22T19:07:46.976626+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251222653976", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3Sh9J1FU6W2alheK25RXuvGq"}	{"id": "1329af43-b7ad-4378-aa63-5d998e769e86", "fee": 0.00, "type": "DEPOSIT", "amount": 1005.00, "status": "COMPLETED", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3Sh9J1FU6W2alheK25RXuvGq"}, "failed_at": null, "reference": null, "created_at": "2025-12-22T19:07:46.976626+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1005.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-22T19:56:23.675968+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": "2025-12-22T19:56:23.675968+05:30", "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251222653976", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3Sh9J1FU6W2alheK25RXuvGq"}	{status,updated_at,processed_at}	\N	\N	\N	2025-12-22 19:56:23.675968+05:30
36f7e9e7-dbea-4aeb-a645-3604c3ca5bae	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-22T19:36:40.020833+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-22T19:36:40.020833+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-23T13:51:53.754091+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-23T13:51:53.754091+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-23 13:51:53.754091+05:30
9b87f633-dafc-4df3-8802-83c72eb841cd	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-22T19:07:09.65618+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-22T19:07:09.65618+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-23T18:57:19.564956+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-23T18:57:19.564956+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-23 18:57:19.564956+05:30
9bd69f1e-aa68-4f6a-b2b8-c61c1281b954	transactions	INSERT	b132fd84-b31a-4244-a67c-43403b57e903	\N	\N	{"id": "b132fd84-b31a-4244-a67c-43403b57e903", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3ShVcmFU6W2alheK07Aadv57"}, "failed_at": null, "reference": null, "created_at": "2025-12-23T18:57:39.620208+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-23T18:57:39.620208+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251223143972", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3ShVcmFU6W2alheK07Aadv57"}	\N	\N	\N	\N	2025-12-23 18:57:39.620208+05:30
6aaf8aef-3f29-4dc7-9c4f-f6f868671899	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-23T13:51:53.754091+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-23T13:51:53.754091+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-23T19:00:34.751541+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-23T19:00:34.751541+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-23 19:00:34.751541+05:30
d5d00193-4413-4d5e-b458-4d134cd43c15	transactions	INSERT	71566c7f-a0f0-406c-93f8-db584fea8c7f	\N	\N	{"id": "71566c7f-a0f0-406c-93f8-db584fea8c7f", "fee": 0.00, "type": "DEPOSIT", "amount": 5001.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3ShVgEFU6W2alheK08xfwhnf"}, "failed_at": null, "reference": null, "created_at": "2025-12-23T19:01:13.886484+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 5001.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-23T19:01:13.886484+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251223340124", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3ShVgEFU6W2alheK08xfwhnf"}	\N	\N	\N	\N	2025-12-23 19:01:13.886484+05:30
34b3d76d-b911-4a6a-a08e-9a5e5ddca080	transactions	INSERT	e574bca5-a052-45ad-9e01-fccc59c27dbb	\N	\N	{"id": "e574bca5-a052-45ad-9e01-fccc59c27dbb", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3ShWHmFU6W2alheK1k1dOLlo"}, "failed_at": null, "reference": null, "created_at": "2025-12-23T19:40:02.362874+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-23T19:40:02.362874+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251223134887", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3ShWHmFU6W2alheK1k1dOLlo"}	\N	\N	\N	\N	2025-12-23 19:40:02.362874+05:30
60e14a93-3afa-4894-a6a3-d339df5adbe0	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-23T18:57:19.564956+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-23T18:57:19.564956+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-24T08:28:31.0542+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-24T08:28:31.0542+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-24 08:28:31.0542+05:30
e77804c4-8743-4954-98c1-aa908d70e989	users	UPDATE	1880ea25-a5bf-4c10-8b2e-e7ff1728445b	\N	{"id": "1880ea25-a5bf-4c10-8b2e-e7ff1728445b", "role": "USER", "email": "tc@tcc.com", "phone": "9876543210", "is_active": true, "last_name": "Test", "created_at": "2025-12-19T15:22:22.250196+05:30", "first_name": "Test", "kyc_status": "PENDING", "updated_at": "2025-12-20T00:50:55.413358+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T15:22:28.043574+05:30", "password_hash": "$2b$10$//GgSRxf4e3DGWO4ZQjJyOBv6.Uc3ftQQIFJsiz3gJHJAw7NugDai", "referral_code": "MI87JQJC", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "1880ea25-a5bf-4c10-8b2e-e7ff1728445b", "role": "USER", "email": "tc@tcc.com", "phone": "9876543210", "is_active": true, "last_name": "Test", "created_at": "2025-12-19T15:22:22.250196+05:30", "first_name": "Test", "kyc_status": "PENDING", "updated_at": "2025-12-24T10:32:32.818605+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-24T10:32:32.818605+05:30", "password_hash": "$2b$10$//GgSRxf4e3DGWO4ZQjJyOBv6.Uc3ftQQIFJsiz3gJHJAw7NugDai", "referral_code": "MI87JQJC", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-24 10:32:32.818605+05:30
689b8df7-39fb-4963-beac-0bdd7a846975	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-24T08:28:31.0542+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-24T08:28:31.0542+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-24T15:42:19.888402+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-24T15:42:19.888402+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-24 15:42:19.888402+05:30
d6d467a8-51e1-4b0e-8a4b-120312c0ae36	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-24T15:42:19.888402+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-24T15:42:19.888402+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-24T16:50:56.502677+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-24T16:50:56.502677+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-24 16:50:56.502677+05:30
48489767-af59-41ac-846a-a30279a834fb	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-24T16:50:56.502677+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-24T16:50:56.502677+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-24T18:05:47.796099+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-24T18:05:47.796099+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-24 18:05:47.796099+05:30
6f17a9f8-2123-4c53-b2cb-d0c776b2dc4c	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-24T18:05:47.796099+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-24T18:05:47.796099+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-24T18:20:36.604396+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-24T18:20:36.604396+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-24 18:20:36.604396+05:30
a3ca818e-22b4-4fe8-b510-b3fb954de733	transactions	INSERT	9ada3b78-a84b-4e94-bbcf-07b7f9d75170	\N	\N	{"id": "9ada3b78-a84b-4e94-bbcf-07b7f9d75170", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3ShraoFU6W2alheK0yQCopIf"}, "failed_at": null, "reference": null, "created_at": "2025-12-24T18:25:05.207333+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-24T18:25:05.207333+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251224337607", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3ShraoFU6W2alheK0yQCopIf"}	\N	\N	\N	\N	2025-12-24 18:25:05.207333+05:30
13129cc8-75c4-4e24-911f-5a0842e53bb4	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-24T18:20:36.604396+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-24T18:20:36.604396+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-24T19:21:00.564674+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-24T19:21:00.564674+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-24 19:21:00.564674+05:30
7ebd663f-1f93-464b-96e8-f06a3b044ce9	transactions	INSERT	21a12194-2468-424e-a71a-adcce0e7aab5	\N	\N	{"id": "21a12194-2468-424e-a71a-adcce0e7aab5", "fee": 0.00, "type": "DEPOSIT", "amount": 10001.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3ShsT2FU6W2alheK0HOwHxvw"}, "failed_at": null, "reference": null, "created_at": "2025-12-24T19:21:07.310078+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 10001.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-24T19:21:07.310078+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251224740071", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3ShsT2FU6W2alheK0HOwHxvw"}	\N	\N	\N	\N	2025-12-24 19:21:07.310078+05:30
f3e44d66-237c-4b06-a145-c4c4f312c16a	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-24T19:21:00.564674+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-24T19:21:00.564674+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-24T19:27:42.754166+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-24T19:21:00.564674+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766584662751-fe27b7fbcf3a9ebc.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,profile_picture_url}	\N	\N	\N	2025-12-24 19:27:42.754166+05:30
0b72a1f1-8d1f-42f7-a9a4-a79de42ff385	transactions	INSERT	8ac9fd4c-dceb-4add-8207-b53d93b002b2	\N	\N	{"id": "8ac9fd4c-dceb-4add-8207-b53d93b002b2", "fee": 0.00, "type": "DEPOSIT", "amount": 5000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3ShsnJFU6W2alheK0013lCgQ"}, "failed_at": null, "reference": null, "created_at": "2025-12-24T19:42:05.336912+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 5000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-24T19:42:05.336912+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251224188900", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3ShsnJFU6W2alheK0013lCgQ"}	\N	\N	\N	\N	2025-12-24 19:42:05.336912+05:30
cfd8ed25-9ec9-42cb-b110-2f6549f8d7f3	transactions	INSERT	d76ba9dd-064d-40a7-9d33-2337a60d45d1	\N	\N	{"id": "d76ba9dd-064d-40a7-9d33-2337a60d45d1", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3ShtMvFU6W2alheK0WiPFhMD"}, "failed_at": null, "reference": null, "created_at": "2025-12-24T20:18:53.071007+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-24T20:18:53.071007+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251224620465", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3ShtMvFU6W2alheK0WiPFhMD"}	\N	\N	\N	\N	2025-12-24 20:18:53.071007+05:30
94bcf48a-5ecc-41ae-ac3e-5c42f16a8dd5	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-24T19:27:42.754166+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-24T19:21:00.564674+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766584662751-fe27b7fbcf3a9ebc.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-24T20:24:07.746967+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-24T20:24:07.746967+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766584662751-fe27b7fbcf3a9ebc.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-24 20:24:07.746967+05:30
170e3bdf-ee59-4a78-8ba1-c4ad218ab188	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-24T20:24:07.746967+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-24T20:24:07.746967+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766584662751-fe27b7fbcf3a9ebc.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-25T08:53:52.820714+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-25T08:53:52.820714+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766584662751-fe27b7fbcf3a9ebc.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-25 08:53:52.820714+05:30
2f31945a-989b-46ac-8509-95c805776afe	transactions	INSERT	1bce64d0-0d7e-4095-b12a-0fc20d852dbb	\N	\N	{"id": "1bce64d0-0d7e-4095-b12a-0fc20d852dbb", "fee": 0.00, "type": "DEPOSIT", "amount": 10000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3Si5VnFU6W2alheK1QT2tOjc"}, "failed_at": null, "reference": null, "created_at": "2025-12-25T09:16:50.557105+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 10000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-25T09:16:50.557105+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251225686836", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3Si5VnFU6W2alheK1QT2tOjc"}	\N	\N	\N	\N	2025-12-25 09:16:50.557105+05:30
3227ba0e-06d2-4280-995c-4d2f95b5ec62	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-25T08:53:52.820714+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-25T08:53:52.820714+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766584662751-fe27b7fbcf3a9ebc.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-25T09:40:17.065014+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-25T09:40:17.065014+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766584662751-fe27b7fbcf3a9ebc.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-25 09:40:17.065014+05:30
9e6ce8e1-e1ff-4eda-a3c7-84df5122cc75	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-25T09:40:17.065014+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-25T09:40:17.065014+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766584662751-fe27b7fbcf3a9ebc.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-25T10:05:15.356541+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-25T09:40:17.065014+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766637315351-5e6f23597eb8f920.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,profile_picture_url}	\N	\N	\N	2025-12-25 10:05:15.356541+05:30
486dad93-0307-4932-b239-9abea6ef3877	users	UPDATE	1880ea25-a5bf-4c10-8b2e-e7ff1728445b	\N	{"id": "1880ea25-a5bf-4c10-8b2e-e7ff1728445b", "role": "USER", "email": "tc@tcc.com", "phone": "9876543210", "is_active": true, "last_name": "Test", "created_at": "2025-12-19T15:22:22.250196+05:30", "first_name": "Test", "kyc_status": "PENDING", "updated_at": "2025-12-24T10:32:32.818605+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-24T10:32:32.818605+05:30", "password_hash": "$2b$10$//GgSRxf4e3DGWO4ZQjJyOBv6.Uc3ftQQIFJsiz3gJHJAw7NugDai", "referral_code": "MI87JQJC", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "1880ea25-a5bf-4c10-8b2e-e7ff1728445b", "role": "USER", "email": "tc@tcc.com", "phone": "9876543210", "is_active": true, "last_name": "Test", "created_at": "2025-12-19T15:22:22.250196+05:30", "first_name": "Test", "kyc_status": "PENDING", "updated_at": "2025-12-25T14:18:31.294748+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-25T14:18:31.294748+05:30", "password_hash": "$2b$10$//GgSRxf4e3DGWO4ZQjJyOBv6.Uc3ftQQIFJsiz3gJHJAw7NugDai", "referral_code": "MI87JQJC", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-25 14:18:31.294748+05:30
78e0fc1e-521a-46b0-8e19-a7042e029b9f	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-25T10:05:15.356541+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-25T09:40:17.065014+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766637315351-5e6f23597eb8f920.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-25T15:52:53.1133+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-25T15:52:53.1133+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766637315351-5e6f23597eb8f920.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-25 15:52:53.1133+05:30
12f54d44-c0ec-423c-891b-a06a89c8bb9e	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-25T15:52:53.1133+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-25T15:52:53.1133+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766637315351-5e6f23597eb8f920.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-25T16:26:53.386462+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-25T15:52:53.1133+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766660213370-eea71e983f4f0767.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,profile_picture_url}	\N	\N	\N	2025-12-25 16:26:53.386462+05:30
7284f37b-8c0b-46a8-901d-2fe0a1bbb142	transactions	INSERT	b9b95ca7-e3c8-47c9-81b4-dfc788fe77eb	\N	\N	{"id": "b9b95ca7-e3c8-47c9-81b4-dfc788fe77eb", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SiCEkFU6W2alheK1rrE6vZv"}, "failed_at": null, "reference": null, "created_at": "2025-12-25T16:27:42.196728+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-25T16:27:42.196728+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251225126534", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SiCEkFU6W2alheK1rrE6vZv"}	\N	\N	\N	\N	2025-12-25 16:27:42.196728+05:30
480449e5-e883-4949-9dd9-bc80b2e16d9e	transactions	UPDATE	b9b95ca7-e3c8-47c9-81b4-dfc788fe77eb	\N	{"id": "b9b95ca7-e3c8-47c9-81b4-dfc788fe77eb", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SiCEkFU6W2alheK1rrE6vZv"}, "failed_at": null, "reference": null, "created_at": "2025-12-25T16:27:42.196728+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-25T16:27:42.196728+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251225126534", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SiCEkFU6W2alheK1rrE6vZv"}	{"id": "b9b95ca7-e3c8-47c9-81b4-dfc788fe77eb", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "COMPLETED", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SiCEkFU6W2alheK1rrE6vZv"}, "failed_at": null, "reference": null, "created_at": "2025-12-25T16:27:42.196728+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-25T16:28:04.803707+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": "2025-12-25T16:28:04.803707+05:30", "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251225126534", "payment_gateway_response": {"id": "pi_3SiCEkFU6W2alheK1rrE6vZv", "amount": 100000, "object": "payment_intent", "review": null, "source": null, "status": "succeeded", "created": 1766660262, "currency": "usd", "customer": "cus_TdRqd1D0i7ZGBL", "livemode": false, "metadata": {"type": "wallet_deposit", "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "transaction_id": "TXN20251225126534"}, "shipping": null, "processing": null, "application": null, "canceled_at": null, "description": "Wallet deposit for transaction TXN20251225126534", "next_action": null, "on_behalf_of": null, "client_secret": "pi_3SiCEkFU6W2alheK1rrE6vZv_secret_YbkjfXEXE6lZJSgkpZLlGHqcL", "latest_charge": "ch_3SiCEkFU6W2alheK1qkGEQwz", "receipt_email": null, "transfer_data": null, "amount_details": {"tip": {}}, "capture_method": "automatic_async", "payment_method": "pm_1SiCF2FU6W2alheK3N7vyu3U", "transfer_group": null, "amount_received": 100000, "customer_account": null, "amount_capturable": 0, "last_payment_error": null, "setup_future_usage": null, "cancellation_reason": null, "confirmation_method": "automatic", "payment_method_types": ["card", "klarna", "link", "affirm", "cashapp", "amazon_pay"], "statement_descriptor": null, "application_fee_amount": null, "payment_method_options": {"card": {"network": null, "installments": null, "mandate_options": null, "request_three_d_secure": "automatic"}, "link": {"persistent_token": null}, "affirm": {}, "klarna": {"preferred_locale": null}, "cashapp": {}, "amazon_pay": {"express_checkout_element_session_id": null}}, "automatic_payment_methods": {"enabled": true, "allow_redirects": "always"}, "statement_descriptor_suffix": null, "excluded_payment_method_types": null, "payment_method_configuration_details": {"id": "pmc_1Sf11kFU6W2alheK0rGIa7ih", "parent": null}}, "stripe_payment_intent_id": "pi_3SiCEkFU6W2alheK1rrE6vZv"}	{status,updated_at,processed_at,payment_gateway_response}	\N	\N	\N	2025-12-25 16:28:04.803707+05:30
fe86fd1b-d5ac-461e-b035-ca78ba0df5a7	wallets	UPDATE	18bee39e-ad39-499c-9495-d7416d7a8d7e	\N	{"id": "18bee39e-ad39-499c-9495-d7416d7a8d7e", "balance": 12010.00, "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "currency": "SLL", "created_at": "2025-12-19T23:27:35.419864+05:30", "updated_at": "2025-12-22T19:56:23.675968+05:30", "last_transaction_at": "2025-12-22T19:56:23.675968+05:30"}	{"id": "18bee39e-ad39-499c-9495-d7416d7a8d7e", "balance": 13010.00, "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "currency": "SLL", "created_at": "2025-12-19T23:27:35.419864+05:30", "updated_at": "2025-12-25T16:28:04.803707+05:30", "last_transaction_at": "2025-12-25T16:28:04.803707+05:30"}	{balance,updated_at,last_transaction_at}	\N	\N	\N	2025-12-25 16:28:04.803707+05:30
10b6c5fa-66c8-471d-94ca-1ea9aa05b2e2	wallets	UPDATE	18bee39e-ad39-499c-9495-d7416d7a8d7e	\N	{"id": "18bee39e-ad39-499c-9495-d7416d7a8d7e", "balance": 13010.00, "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "currency": "SLL", "created_at": "2025-12-19T23:27:35.419864+05:30", "updated_at": "2025-12-25T16:28:04.803707+05:30", "last_transaction_at": "2025-12-25T16:28:04.803707+05:30"}	{"id": "18bee39e-ad39-499c-9495-d7416d7a8d7e", "balance": 14010.00, "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "currency": "SLL", "created_at": "2025-12-19T23:27:35.419864+05:30", "updated_at": "2025-12-25T16:28:04.803707+05:30", "last_transaction_at": "2025-12-25T16:28:04.803707+05:30"}	{balance}	\N	\N	\N	2025-12-25 16:28:04.803707+05:30
e6521dea-3e20-4919-a5ba-d6647048d449	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-25T16:26:53.386462+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-25T15:52:53.1133+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766660213370-eea71e983f4f0767.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-25T17:01:33.23312+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-25T17:01:33.23312+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766660213370-eea71e983f4f0767.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-25 17:01:33.23312+05:30
cf5c5409-82d1-4f47-a428-23e67ce916d8	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-25T17:01:33.23312+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-25T17:01:33.23312+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766660213370-eea71e983f4f0767.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-25T17:01:41.282287+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-25T17:01:41.282287+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766660213370-eea71e983f4f0767.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-25 17:01:41.282287+05:30
07bc195c-4dc6-4825-9d96-c09d9ad26cc9	transactions	INSERT	21e417f2-3db9-4508-b3af-4afea833a168	\N	\N	{"id": "21e417f2-3db9-4508-b3af-4afea833a168", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SiCo9FU6W2alheK2M10mmGM"}, "failed_at": null, "reference": null, "created_at": "2025-12-25T17:04:17.405645+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-25T17:04:17.405645+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251225154026", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SiCo9FU6W2alheK2M10mmGM"}	\N	\N	\N	\N	2025-12-25 17:04:17.405645+05:30
0c416570-a501-477e-944a-538d4ea1819c	transactions	UPDATE	21e417f2-3db9-4508-b3af-4afea833a168	\N	{"id": "21e417f2-3db9-4508-b3af-4afea833a168", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SiCo9FU6W2alheK2M10mmGM"}, "failed_at": null, "reference": null, "created_at": "2025-12-25T17:04:17.405645+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-25T17:04:17.405645+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251225154026", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3SiCo9FU6W2alheK2M10mmGM"}	{"id": "21e417f2-3db9-4508-b3af-4afea833a168", "fee": 0.00, "type": "DEPOSIT", "amount": 1000.00, "status": "COMPLETED", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3SiCo9FU6W2alheK2M10mmGM"}, "failed_at": null, "reference": null, "created_at": "2025-12-25T17:04:17.405645+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 1000.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2025-12-25T17:04:36.951452+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": "2025-12-25T17:04:36.951452+05:30", "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20251225154026", "payment_gateway_response": {"id": "pi_3SiCo9FU6W2alheK2M10mmGM", "amount": 100000, "object": "payment_intent", "review": null, "source": null, "status": "succeeded", "created": 1766662457, "currency": "usd", "customer": "cus_TdRqd1D0i7ZGBL", "livemode": false, "metadata": {"type": "wallet_deposit", "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "transaction_id": "TXN20251225154026"}, "shipping": null, "processing": null, "application": null, "canceled_at": null, "description": "Wallet deposit for transaction TXN20251225154026", "next_action": null, "on_behalf_of": null, "client_secret": "pi_3SiCo9FU6W2alheK2M10mmGM_secret_F2sxYo5DdAIzLNHfbVKmuL8Or", "latest_charge": "ch_3SiCo9FU6W2alheK2ChliQ1g", "receipt_email": null, "transfer_data": null, "amount_details": {"tip": {}}, "capture_method": "automatic_async", "payment_method": "pm_1SiCoPFU6W2alheKNAsGOZbO", "transfer_group": null, "amount_received": 100000, "customer_account": null, "amount_capturable": 0, "last_payment_error": null, "setup_future_usage": null, "cancellation_reason": null, "confirmation_method": "automatic", "payment_method_types": ["card", "klarna", "link", "affirm", "cashapp", "amazon_pay"], "statement_descriptor": null, "application_fee_amount": null, "payment_method_options": {"card": {"network": null, "installments": null, "mandate_options": null, "request_three_d_secure": "automatic"}, "link": {"persistent_token": null}, "affirm": {}, "klarna": {"preferred_locale": null}, "cashapp": {}, "amazon_pay": {"express_checkout_element_session_id": null}}, "automatic_payment_methods": {"enabled": true, "allow_redirects": "always"}, "statement_descriptor_suffix": null, "excluded_payment_method_types": null, "payment_method_configuration_details": {"id": "pmc_1Sf11kFU6W2alheK0rGIa7ih", "parent": null}}, "stripe_payment_intent_id": "pi_3SiCo9FU6W2alheK2M10mmGM"}	{status,updated_at,processed_at,payment_gateway_response}	\N	\N	\N	2025-12-25 17:04:36.951452+05:30
3d6b82ed-4571-4839-9ad4-8aa83184f685	wallets	UPDATE	18bee39e-ad39-499c-9495-d7416d7a8d7e	\N	{"id": "18bee39e-ad39-499c-9495-d7416d7a8d7e", "balance": 14010.00, "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "currency": "SLL", "created_at": "2025-12-19T23:27:35.419864+05:30", "updated_at": "2025-12-25T16:28:04.803707+05:30", "last_transaction_at": "2025-12-25T16:28:04.803707+05:30"}	{"id": "18bee39e-ad39-499c-9495-d7416d7a8d7e", "balance": 15010.00, "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "currency": "SLL", "created_at": "2025-12-19T23:27:35.419864+05:30", "updated_at": "2025-12-25T17:04:36.951452+05:30", "last_transaction_at": "2025-12-25T17:04:36.951452+05:30"}	{balance,updated_at,last_transaction_at}	\N	\N	\N	2025-12-25 17:04:36.951452+05:30
0737f7d9-4900-4bd4-8a24-235736f193bf	wallets	UPDATE	18bee39e-ad39-499c-9495-d7416d7a8d7e	\N	{"id": "18bee39e-ad39-499c-9495-d7416d7a8d7e", "balance": 15010.00, "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "currency": "SLL", "created_at": "2025-12-19T23:27:35.419864+05:30", "updated_at": "2025-12-25T17:04:36.951452+05:30", "last_transaction_at": "2025-12-25T17:04:36.951452+05:30"}	{"id": "18bee39e-ad39-499c-9495-d7416d7a8d7e", "balance": 16010.00, "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "currency": "SLL", "created_at": "2025-12-19T23:27:35.419864+05:30", "updated_at": "2025-12-25T17:04:36.951452+05:30", "last_transaction_at": "2025-12-25T17:04:36.951452+05:30"}	{balance}	\N	\N	\N	2025-12-25 17:04:36.951452+05:30
2db91420-9919-4aed-b193-68510ce4dcf3	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-25T17:01:41.282287+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-25T17:01:41.282287+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766660213370-eea71e983f4f0767.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-25T17:18:07.51754+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-25T17:18:07.51754+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766660213370-eea71e983f4f0767.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-25 17:18:07.51754+05:30
82a4db3e-727d-4028-86ff-4e80a011305a	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-25T17:18:07.51754+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-25T17:18:07.51754+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766660213370-eea71e983f4f0767.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-25T18:24:10.561168+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-25T18:24:10.561168+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766660213370-eea71e983f4f0767.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-25 18:24:10.561168+05:30
5fd3f409-57b4-4607-b40a-1e395f3c08ec	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-25T18:24:10.561168+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-25T18:24:10.561168+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766660213370-eea71e983f4f0767.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-25T18:49:42.502484+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-25T18:49:42.502484+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766660213370-eea71e983f4f0767.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-25 18:49:42.502484+05:30
77cce1b6-5273-485f-917b-8d371f09e4f6	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-25T18:49:42.502484+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-25T18:49:42.502484+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766660213370-eea71e983f4f0767.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-31T10:27:54.298369+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-31T10:27:54.298369+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766660213370-eea71e983f4f0767.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2025-12-31 10:27:54.298369+05:30
7c9befb5-4d5a-4e5a-998a-65e0ac636e7b	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2025-12-31T10:27:54.298369+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-31T10:27:54.298369+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766660213370-eea71e983f4f0767.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2026-01-02T14:31:55.796276+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2026-01-02T14:31:55.796276+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766660213370-eea71e983f4f0767.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2026-01-02 14:31:55.796276+05:30
9c49297f-0d5d-4032-a313-222d8c21029e	users	UPDATE	43f2c95b-4fe8-4481-aa42-77125cef5d1f	\N	{"id": "43f2c95b-4fe8-4481-aa42-77125cef5d1f", "role": "USER", "email": "t1@tcc.com", "phone": "9876543213", "is_active": true, "last_name": "test", "created_at": "2025-12-19T22:31:27.903088+05:30", "first_name": "test", "kyc_status": "PENDING", "updated_at": "2025-12-19T22:31:38.650209+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-19T22:31:38.650209+05:30", "password_hash": "$2b$10$JP0AgEzScstcK7MryFb2P.qUZ3YMR.gGj/5KPEpT7FZK9NYtLJscm", "referral_code": "6O0JJY1X", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "43f2c95b-4fe8-4481-aa42-77125cef5d1f", "role": "USER", "email": "t1@tcc.com", "phone": "9876543213", "is_active": true, "last_name": "test", "created_at": "2025-12-19T22:31:27.903088+05:30", "first_name": "test", "kyc_status": "PENDING", "updated_at": "2026-01-02T14:35:19.791961+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2026-01-02T14:35:19.791961+05:30", "password_hash": "$2b$10$JP0AgEzScstcK7MryFb2P.qUZ3YMR.gGj/5KPEpT7FZK9NYtLJscm", "referral_code": "6O0JJY1X", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2026-01-02 14:35:19.791961+05:30
ae4abde2-f168-40ea-86f0-885f5caac6ac	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2026-01-02T14:31:55.796276+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2026-01-02T14:31:55.796276+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766660213370-eea71e983f4f0767.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2026-01-02T14:35:49.060473+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2026-01-02T14:35:49.060473+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766660213370-eea71e983f4f0767.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2026-01-02 14:35:49.060473+05:30
f19cd311-f7fe-46f9-ac95-a70f36aa7e54	users	INSERT	39d53302-9bf3-4e79-95ac-883cae482d9e	\N	\N	{"id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "role": "USER", "email": "shashank@gmail.com", "phone": "9876543225", "is_active": true, "last_name": "Singh", "created_at": "2026-01-02T14:37:35.588186+05:30", "first_name": "Shashank", "kyc_status": "PENDING", "updated_at": "2026-01-02T14:37:35.588186+05:30", "is_verified": false, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": null, "password_hash": "$2b$10$4KK05kTfU0iUsQXCJ5lFHuhYJMIjckrRD7fXrYyL8kn56i80OUktW", "referral_code": "FG609015", "email_verified": false, "phone_verified": false, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	\N	\N	\N	\N	2026-01-02 14:37:35.588186+05:30
a81d71f4-c496-476f-9f15-434b5f38c3be	wallets	INSERT	b31356de-0e1b-4663-abf4-20cc50449b12	\N	\N	{"id": "b31356de-0e1b-4663-abf4-20cc50449b12", "balance": 0.00, "user_id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "currency": "SLL", "created_at": "2026-01-02T14:37:35.604597+05:30", "updated_at": "2026-01-02T14:37:35.604597+05:30", "last_transaction_at": null}	\N	\N	\N	\N	2026-01-02 14:37:35.604597+05:30
b8c8f6f5-e8a7-4953-90f8-a288e0292d93	users	UPDATE	39d53302-9bf3-4e79-95ac-883cae482d9e	\N	{"id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "role": "USER", "email": "shashank@gmail.com", "phone": "9876543225", "is_active": true, "last_name": "Singh", "created_at": "2026-01-02T14:37:35.588186+05:30", "first_name": "Shashank", "kyc_status": "PENDING", "updated_at": "2026-01-02T14:37:35.588186+05:30", "is_verified": false, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": null, "password_hash": "$2b$10$4KK05kTfU0iUsQXCJ5lFHuhYJMIjckrRD7fXrYyL8kn56i80OUktW", "referral_code": "FG609015", "email_verified": false, "phone_verified": false, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "role": "USER", "email": "shashank@gmail.com", "phone": "9876543225", "is_active": true, "last_name": "Singh", "created_at": "2026-01-02T14:37:35.588186+05:30", "first_name": "Shashank", "kyc_status": "PENDING", "updated_at": "2026-01-02T14:37:58.755436+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2026-01-02T14:37:58.755436+05:30", "password_hash": "$2b$10$4KK05kTfU0iUsQXCJ5lFHuhYJMIjckrRD7fXrYyL8kn56i80OUktW", "referral_code": "FG609015", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,is_verified,last_login_at,phone_verified}	\N	\N	\N	2026-01-02 14:37:58.755436+05:30
00e3ead0-fd95-4462-a192-7f57993e45d9	users	UPDATE	39d53302-9bf3-4e79-95ac-883cae482d9e	\N	{"id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "role": "USER", "email": "shashank@gmail.com", "phone": "9876543225", "is_active": true, "last_name": "Singh", "created_at": "2026-01-02T14:37:35.588186+05:30", "first_name": "Shashank", "kyc_status": "PENDING", "updated_at": "2026-01-02T14:37:58.755436+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2026-01-02T14:37:58.755436+05:30", "password_hash": "$2b$10$4KK05kTfU0iUsQXCJ5lFHuhYJMIjckrRD7fXrYyL8kn56i80OUktW", "referral_code": "FG609015", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "role": "USER", "email": "shashank@gmail.com", "phone": "9876543225", "is_active": true, "last_name": "Singh", "created_at": "2026-01-02T14:37:35.588186+05:30", "first_name": "Shashank", "kyc_status": "SUBMITTED", "updated_at": "2026-01-02T14:38:29.911493+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2026-01-02T14:37:58.755436+05:30", "password_hash": "$2b$10$4KK05kTfU0iUsQXCJ5lFHuhYJMIjckrRD7fXrYyL8kn56i80OUktW", "referral_code": "FG609015", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{kyc_status,updated_at}	\N	\N	\N	2026-01-02 14:38:29.911493+05:30
493cfaac-9880-415f-8e15-1ab05c82b303	users	UPDATE	af223b34-da3f-44a6-bcd6-938034b46d50	\N	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2025-12-23T19:00:34.751541+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2025-12-23T19:00:34.751541+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "af223b34-da3f-44a6-bcd6-938034b46d50", "role": "SUPER_ADMIN", "email": "admin@tcc.sl", "phone": "+23276000001", "is_active": true, "last_name": "User", "created_at": "2025-12-18T18:26:56.881408+05:30", "first_name": "Admin", "kyc_status": "APPROVED", "updated_at": "2026-01-02T14:40:04.795536+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2026-01-02T14:40:04.795536+05:30", "password_hash": "$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2", "referral_code": null, "email_verified": true, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2026-01-02 14:40:04.795536+05:30
281c18e7-53b2-4ea1-bb2a-674ea35b5bf4	users	UPDATE	39d53302-9bf3-4e79-95ac-883cae482d9e	\N	{"id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "role": "USER", "email": "shashank@gmail.com", "phone": "9876543225", "is_active": true, "last_name": "Singh", "created_at": "2026-01-02T14:37:35.588186+05:30", "first_name": "Shashank", "kyc_status": "SUBMITTED", "updated_at": "2026-01-02T14:38:29.911493+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2026-01-02T14:37:58.755436+05:30", "password_hash": "$2b$10$4KK05kTfU0iUsQXCJ5lFHuhYJMIjckrRD7fXrYyL8kn56i80OUktW", "referral_code": "FG609015", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "role": "USER", "email": "shashank@gmail.com", "phone": "9876543225", "is_active": true, "last_name": "Singh", "created_at": "2026-01-02T14:37:35.588186+05:30", "first_name": "Shashank", "kyc_status": "APPROVED", "updated_at": "2026-01-02T14:40:29.385817+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2026-01-02T14:37:58.755436+05:30", "password_hash": "$2b$10$4KK05kTfU0iUsQXCJ5lFHuhYJMIjckrRD7fXrYyL8kn56i80OUktW", "referral_code": "FG609015", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{kyc_status,updated_at}	\N	\N	\N	2026-01-02 14:40:29.385817+05:30
58d4ac1a-719a-4060-91b8-3dd2e9086ca5	users	UPDATE	39d53302-9bf3-4e79-95ac-883cae482d9e	\N	{"id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "role": "USER", "email": "shashank@gmail.com", "phone": "9876543225", "is_active": true, "last_name": "Singh", "created_at": "2026-01-02T14:37:35.588186+05:30", "first_name": "Shashank", "kyc_status": "APPROVED", "updated_at": "2026-01-02T14:40:29.385817+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2026-01-02T14:37:58.755436+05:30", "password_hash": "$2b$10$4KK05kTfU0iUsQXCJ5lFHuhYJMIjckrRD7fXrYyL8kn56i80OUktW", "referral_code": "FG609015", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": null, "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "role": "USER", "email": "shashank@gmail.com", "phone": "9876543225", "is_active": true, "last_name": "Singh", "created_at": "2026-01-02T14:37:35.588186+05:30", "first_name": "Shashank", "kyc_status": "APPROVED", "updated_at": "2026-01-02T14:40:53.145675+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2026-01-02T14:37:58.755436+05:30", "password_hash": "$2b$10$4KK05kTfU0iUsQXCJ5lFHuhYJMIjckrRD7fXrYyL8kn56i80OUktW", "referral_code": "FG609015", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TiVOLMNMbI1dyi", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,stripe_customer_id}	\N	\N	\N	2026-01-02 14:40:53.145675+05:30
5098b327-d566-447d-bf98-a4be5b053c04	transactions	INSERT	dc2605d4-ed8e-49a4-9705-067d6b3b3bd2	\N	\N	{"id": "dc2605d4-ed8e-49a4-9705-067d6b3b3bd2", "fee": 0.00, "type": "DEPOSIT", "amount": 10000.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3Sl4NlFU6W2alheK2sw5JEoS"}, "failed_at": null, "reference": null, "created_at": "2026-01-02T14:40:53.154345+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 10000.00, "to_user_id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "updated_at": "2026-01-02T14:40:53.154345+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20260102310787", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3Sl4NlFU6W2alheK2sw5JEoS"}	\N	\N	\N	\N	2026-01-02 14:40:53.154345+05:30
fb70b02c-0eab-48e4-9baf-051b2f4a1ae1	transactions	INSERT	1623e0a5-0dc7-4e9f-9ea0-014d05aa0404	\N	\N	{"id": "1623e0a5-0dc7-4e9f-9ea0-014d05aa0404", "fee": 0.00, "type": "DEPOSIT", "amount": 2500.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3Sl4oCFU6W2alheK2ZDcWvMT"}, "failed_at": null, "reference": null, "created_at": "2026-01-02T15:08:12.208707+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 2500.00, "to_user_id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "updated_at": "2026-01-02T15:08:12.208707+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20260102209426", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3Sl4oCFU6W2alheK2ZDcWvMT"}	\N	\N	\N	\N	2026-01-02 15:08:12.208707+05:30
c9fba672-350f-46f4-890a-e68091ed4607	transactions	INSERT	fa174540-3a1a-453d-b158-7de9da4c1bca	\N	\N	{"id": "fa174540-3a1a-453d-b158-7de9da4c1bca", "fee": 0.00, "type": "DEPOSIT", "amount": 2500.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3Sl4vzFU6W2alheK1jbkBvLZ"}, "failed_at": null, "reference": null, "created_at": "2026-01-02T15:16:14.751454+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 2500.00, "to_user_id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "updated_at": "2026-01-02T15:16:14.751454+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20260102693155", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3Sl4vzFU6W2alheK1jbkBvLZ"}	\N	\N	\N	\N	2026-01-02 15:16:14.751454+05:30
29999329-3dd6-480d-ac12-79f9afce8950	transactions	INSERT	8e66b5a5-b9e9-483a-ab7a-c1153cd4c7ba	\N	\N	{"id": "8e66b5a5-b9e9-483a-ab7a-c1153cd4c7ba", "fee": 0.00, "type": "DEPOSIT", "amount": 2500.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3Sl50OFU6W2alheK25C3Lyo7"}, "failed_at": null, "reference": null, "created_at": "2026-01-02T15:20:47.903172+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 2500.00, "to_user_id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "updated_at": "2026-01-02T15:20:47.903172+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20260102919056", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3Sl50OFU6W2alheK25C3Lyo7"}	\N	\N	\N	\N	2026-01-02 15:20:47.903172+05:30
1c9af386-4d41-4729-94e1-6f5e0cce82ef	users	UPDATE	39d53302-9bf3-4e79-95ac-883cae482d9e	\N	{"id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "role": "USER", "email": "shashank@gmail.com", "phone": "9876543225", "is_active": true, "last_name": "Singh", "created_at": "2026-01-02T14:37:35.588186+05:30", "first_name": "Shashank", "kyc_status": "APPROVED", "updated_at": "2026-01-02T14:40:53.145675+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2026-01-02T14:37:58.755436+05:30", "password_hash": "$2b$10$4KK05kTfU0iUsQXCJ5lFHuhYJMIjckrRD7fXrYyL8kn56i80OUktW", "referral_code": "FG609015", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TiVOLMNMbI1dyi", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "role": "USER", "email": "shashank@gmail.com", "phone": "9876543225", "is_active": true, "last_name": "Singh", "created_at": "2026-01-02T14:37:35.588186+05:30", "first_name": "Shashank", "kyc_status": "APPROVED", "updated_at": "2026-01-02T15:41:10.018938+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2026-01-02T15:41:10.018938+05:30", "password_hash": "$2b$10$4KK05kTfU0iUsQXCJ5lFHuhYJMIjckrRD7fXrYyL8kn56i80OUktW", "referral_code": "FG609015", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TiVOLMNMbI1dyi", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": null, "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2026-01-02 15:41:10.018938+05:30
5cf75394-6ab9-49ac-bac6-4d063e91ad1f	transactions	INSERT	6cee6642-032a-40a2-8baa-e2c511aead1e	\N	\N	{"id": "6cee6642-032a-40a2-8baa-e2c511aead1e", "fee": 0.00, "type": "DEPOSIT", "amount": 2500.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3Sl5KBFU6W2alheK1FfRpXVC"}, "failed_at": null, "reference": null, "created_at": "2026-01-02T15:41:14.855283+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 2500.00, "to_user_id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "updated_at": "2026-01-02T15:41:14.855283+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20260102870229", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3Sl5KBFU6W2alheK1FfRpXVC"}	\N	\N	\N	\N	2026-01-02 15:41:14.855283+05:30
8a44d81a-5109-48b2-a913-b3e4cc5ddba6	transactions	UPDATE	6cee6642-032a-40a2-8baa-e2c511aead1e	\N	{"id": "6cee6642-032a-40a2-8baa-e2c511aead1e", "fee": 0.00, "type": "DEPOSIT", "amount": 2500.00, "status": "PENDING", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3Sl5KBFU6W2alheK1FfRpXVC"}, "failed_at": null, "reference": null, "created_at": "2026-01-02T15:41:14.855283+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 2500.00, "to_user_id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "updated_at": "2026-01-02T15:41:14.855283+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": null, "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20260102870229", "payment_gateway_response": null, "stripe_payment_intent_id": "pi_3Sl5KBFU6W2alheK1FfRpXVC"}	{"id": "6cee6642-032a-40a2-8baa-e2c511aead1e", "fee": 0.00, "type": "DEPOSIT", "amount": 2500.00, "status": "COMPLETED", "metadata": {"paymentGateway": "stripe", "paymentIntentId": "pi_3Sl5KBFU6W2alheK1FfRpXVC"}, "failed_at": null, "reference": null, "created_at": "2026-01-02T15:41:14.855283+05:30", "ip_address": "::ffff:127.0.0.1", "net_amount": 2500.00, "to_user_id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "updated_at": "2026-01-02T15:41:38.276234+05:30", "user_agent": null, "description": null, "from_user_id": null, "processed_at": "2026-01-02T15:41:38.276234+05:30", "deposit_source": "INTERNET_BANKING", "failure_reason": null, "payment_method": "MOBILE_MONEY", "transaction_id": "TXN20260102870229", "payment_gateway_response": {"id": "pi_3Sl5KBFU6W2alheK1FfRpXVC", "amount": 2500, "object": "payment_intent", "review": null, "source": null, "status": "succeeded", "created": 1767348675, "currency": "usd", "customer": "cus_TiVOLMNMbI1dyi", "livemode": false, "metadata": {"type": "wallet_deposit", "user_id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "transaction_id": "TXN20260102870229"}, "shipping": null, "processing": null, "application": null, "canceled_at": null, "description": "Wallet deposit for transaction TXN20260102870229", "next_action": null, "on_behalf_of": null, "client_secret": "pi_3Sl5KBFU6W2alheK1FfRpXVC_secret_9Oc6y5Hzszpon0KWCjvz6aOVx", "latest_charge": "ch_3Sl5KBFU6W2alheK1tYLDc5n", "receipt_email": null, "transfer_data": null, "amount_details": {"tip": {}}, "capture_method": "automatic_async", "payment_method": "pm_1Sl5KTFU6W2alheKZOH0CehG", "transfer_group": null, "amount_received": 2500, "customer_account": null, "amount_capturable": 0, "last_payment_error": null, "setup_future_usage": null, "cancellation_reason": null, "confirmation_method": "automatic", "payment_method_types": ["card", "klarna", "link", "cashapp", "amazon_pay"], "statement_descriptor": null, "application_fee_amount": null, "payment_method_options": {"card": {"network": null, "installments": null, "mandate_options": null, "request_three_d_secure": "automatic"}, "link": {"persistent_token": null}, "klarna": {"preferred_locale": null}, "cashapp": {}, "amazon_pay": {"express_checkout_element_session_id": null}}, "automatic_payment_methods": {"enabled": true, "allow_redirects": "always"}, "statement_descriptor_suffix": null, "excluded_payment_method_types": null, "payment_method_configuration_details": {"id": "pmc_1Sf11kFU6W2alheK0rGIa7ih", "parent": null}}, "stripe_payment_intent_id": "pi_3Sl5KBFU6W2alheK1FfRpXVC"}	{status,updated_at,processed_at,payment_gateway_response}	\N	\N	\N	2026-01-02 15:41:38.276234+05:30
3ce737f5-3e02-4313-a75f-0601ba283023	wallets	UPDATE	b31356de-0e1b-4663-abf4-20cc50449b12	\N	{"id": "b31356de-0e1b-4663-abf4-20cc50449b12", "balance": 0.00, "user_id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "currency": "SLL", "created_at": "2026-01-02T14:37:35.604597+05:30", "updated_at": "2026-01-02T14:37:35.604597+05:30", "last_transaction_at": null}	{"id": "b31356de-0e1b-4663-abf4-20cc50449b12", "balance": 2500.00, "user_id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "currency": "SLL", "created_at": "2026-01-02T14:37:35.604597+05:30", "updated_at": "2026-01-02T15:41:38.276234+05:30", "last_transaction_at": "2026-01-02T15:41:38.276234+05:30"}	{balance,updated_at,last_transaction_at}	\N	\N	\N	2026-01-02 15:41:38.276234+05:30
3d796827-ee3c-4005-922d-53c1ed0404fc	wallets	UPDATE	b31356de-0e1b-4663-abf4-20cc50449b12	\N	{"id": "b31356de-0e1b-4663-abf4-20cc50449b12", "balance": 2500.00, "user_id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "currency": "SLL", "created_at": "2026-01-02T14:37:35.604597+05:30", "updated_at": "2026-01-02T15:41:38.276234+05:30", "last_transaction_at": "2026-01-02T15:41:38.276234+05:30"}	{"id": "b31356de-0e1b-4663-abf4-20cc50449b12", "balance": 5000.00, "user_id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "currency": "SLL", "created_at": "2026-01-02T14:37:35.604597+05:30", "updated_at": "2026-01-02T15:41:38.276234+05:30", "last_transaction_at": "2026-01-02T15:41:38.276234+05:30"}	{balance}	\N	\N	\N	2026-01-02 15:41:38.276234+05:30
a32e966c-9365-46ba-9566-d48a6b50024a	transactions	INSERT	6bbaeb8c-77b6-4a63-a13d-0258421180b6	\N	\N	{"id": "6bbaeb8c-77b6-4a63-a13d-0258421180b6", "fee": 10.00, "type": "TRANSFER", "amount": 152.00, "status": "COMPLETED", "metadata": null, "failed_at": null, "reference": null, "created_at": "2026-01-02T16:34:30.480453+05:30", "ip_address": null, "net_amount": 152.00, "to_user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "updated_at": "2026-01-02T16:34:30.480453+05:30", "user_agent": null, "description": "HELLO", "from_user_id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "processed_at": "2026-01-02T16:34:30.480453+05:30", "deposit_source": null, "failure_reason": null, "payment_method": null, "transaction_id": "TXN20260102442344", "payment_gateway_response": null, "stripe_payment_intent_id": null}	\N	\N	\N	\N	2026-01-02 16:34:30.480453+05:30
02099578-882e-4db2-a47c-731ebe69ac8f	wallets	UPDATE	b31356de-0e1b-4663-abf4-20cc50449b12	\N	{"id": "b31356de-0e1b-4663-abf4-20cc50449b12", "balance": 5000.00, "user_id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "currency": "SLL", "created_at": "2026-01-02T14:37:35.604597+05:30", "updated_at": "2026-01-02T15:41:38.276234+05:30", "last_transaction_at": "2026-01-02T15:41:38.276234+05:30"}	{"id": "b31356de-0e1b-4663-abf4-20cc50449b12", "balance": 4838.00, "user_id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "currency": "SLL", "created_at": "2026-01-02T14:37:35.604597+05:30", "updated_at": "2026-01-02T16:34:30.480453+05:30", "last_transaction_at": "2026-01-02T16:34:30.480453+05:30"}	{balance,updated_at,last_transaction_at}	\N	\N	\N	2026-01-02 16:34:30.480453+05:30
7df15a10-8523-45a4-98b2-5cf0e59a48b6	wallets	UPDATE	18bee39e-ad39-499c-9495-d7416d7a8d7e	\N	{"id": "18bee39e-ad39-499c-9495-d7416d7a8d7e", "balance": 16010.00, "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "currency": "SLL", "created_at": "2025-12-19T23:27:35.419864+05:30", "updated_at": "2025-12-25T17:04:36.951452+05:30", "last_transaction_at": "2025-12-25T17:04:36.951452+05:30"}	{"id": "18bee39e-ad39-499c-9495-d7416d7a8d7e", "balance": 16162.00, "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "currency": "SLL", "created_at": "2025-12-19T23:27:35.419864+05:30", "updated_at": "2026-01-02T16:34:30.480453+05:30", "last_transaction_at": "2026-01-02T16:34:30.480453+05:30"}	{balance,updated_at,last_transaction_at}	\N	\N	\N	2026-01-02 16:34:30.480453+05:30
2335b2be-226f-4ff5-ab47-1f66edd7446f	users	UPDATE	72fe9f39-5599-4339-bd5b-5adc6ca37996	\N	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2026-01-02T14:35:49.060473+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2026-01-02T14:35:49.060473+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766660213370-eea71e983f4f0767.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{"id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "role": "USER", "email": "tc3@tcc.com", "phone": "9876543215", "is_active": true, "last_name": "test", "created_at": "2025-12-19T23:27:35.393285+05:30", "first_name": "test", "kyc_status": "APPROVED", "updated_at": "2026-01-02T16:34:58.573825+05:30", "is_verified": true, "referred_by": null, "country_code": "+232", "locked_until": null, "last_login_at": "2026-01-02T16:34:58.573825+05:30", "password_hash": "$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW", "referral_code": "0D6EF9KO", "email_verified": false, "phone_verified": true, "two_factor_secret": null, "stripe_customer_id": "cus_TdRqd1D0i7ZGBL", "two_factor_enabled": false, "password_changed_at": null, "profile_picture_url": "http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766660213370-eea71e983f4f0767.jpg", "deletion_requested_at": null, "failed_login_attempts": 0, "deletion_scheduled_for": null}	{updated_at,last_login_at}	\N	\N	\N	2026-01-02 16:34:58.573825+05:30
\.


--
-- Data for Name: bank_accounts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.bank_accounts (id, user_id, bank_name, branch_address, account_number, account_holder_name, swift_code, routing_number, is_primary, is_verified, verification_otp, otp_sent_at, otp_verified_at, created_at, updated_at) FROM stdin;
87d16b19-5c33-4bca-bca6-ae9de325a1f9	6b864809-fb5a-4a1f-a95e-edf87b7eeb5c	Bank	Branch	1235465	Sachin	\N	1654654	t	f	\N	\N	\N	2025-12-20 12:42:28.507874+05:30	2025-12-20 12:42:28.507874+05:30
369d8775-2b10-48d1-a051-720d007b90f9	8c6b2a0e-9b12-49db-8a5f-8dcb58572d72	Bank	branch address	123451	Shashank	\N	1234	t	f	\N	\N	\N	2025-12-20 23:43:49.606721+05:30	2025-12-20 23:43:49.606721+05:30
d72715d5-54c5-416a-a48f-d421dcf57d87	72fe9f39-5599-4339-bd5b-5adc6ca37996	Hello Bank	hi	98798564	Test	\N	\N	f	f	\N	\N	\N	2025-12-25 09:12:16.559192+05:30	2025-12-25 09:12:23.032982+05:30
a8948f3c-d653-4d8c-9fb2-6a8c82a4f01a	72fe9f39-5599-4339-bd5b-5adc6ca37996	ABC Bank	Leone, 123, near bank	1234567890	Test Customer	\N	123546	t	f	\N	\N	\N	2025-12-19 23:29:01.130001+05:30	2025-12-25 09:12:23.032982+05:30
\.


--
-- Data for Name: bill_payments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.bill_payments (id, user_id, provider_id, bill_type, bill_id, bill_holder_name, amount, transaction_id, provider_transaction_id, status, receipt_url, processed_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: bill_providers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.bill_providers (id, name, type, logo_url, api_endpoint, api_key_encrypted, is_active, metadata, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: election_options; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.election_options (id, election_id, option_text, vote_count, created_at) FROM stdin;
\.


--
-- Data for Name: election_votes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.election_votes (id, election_id, option_id, user_id, vote_charge, voted_at) FROM stdin;
\.


--
-- Data for Name: elections; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.elections (id, title, question, voting_charge, start_time, end_time, status, created_by, created_at, updated_at, ended_at, total_votes, total_revenue) FROM stdin;
\.


--
-- Data for Name: file_uploads; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.file_uploads (id, user_id, file_type, original_filename, stored_filename, file_url, file_size, mime_type, checksum, metadata, is_deleted, deleted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: fraud_detection_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.fraud_detection_logs (id, user_id, transaction_id, detection_type, risk_score, details, action_taken, reviewed_by, reviewed_at, created_at) FROM stdin;
\.


--
-- Data for Name: investment_categories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.investment_categories (id, name, display_name, description, sub_categories, icon_url, is_active, created_at, updated_at) FROM stdin;
7018cdac-7590-4b11-b72c-8816dafa8071	AGRICULTURE	Agriculture	Invest in agricultural projects	["Land Lease", "Production", "Processing", "Marketing"]	\N	t	2025-12-18 18:12:24.826146+05:30	2025-12-18 18:12:24.826146+05:30
9ded9d93-f3f8-4f17-bdba-5f2ad0a3470a	EDUCATION	Education	Invest in educational institutions	["Institution", "Housing/Dormitory"]	\N	t	2025-12-18 18:12:24.826146+05:30	2025-12-18 18:12:24.826146+05:30
dac8b251-c69e-49d1-901c-5b00172a183e	MINERALS	Minerals	Invest in mineral extraction and trading	["Gold", "Platinum", "Silver", "Diamond"]	\N	t	2025-12-18 18:12:24.826146+05:30	2025-12-18 18:12:24.826146+05:30
\.


--
-- Data for Name: investment_opportunities; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.investment_opportunities (id, category_id, title, description, min_investment, max_investment, tenure_months, return_rate, total_units, available_units, image_url, is_active, display_order, metadata, created_at, updated_at) FROM stdin;
98ac20f5-8a88-4631-a2b0-d1b5fac77e59	7018cdac-7590-4b11-b72c-8816dafa8071	Harvesting	hello to harvesting	5000.00	50005.00	12	15.00	100	100	\N	t	0	\N	2025-12-23 15:05:07.968079+05:30	2025-12-23 15:05:07.968079+05:30
\.


--
-- Data for Name: investment_returns; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.investment_returns (id, investment_id, return_date, calculated_amount, actual_amount, actual_rate, status, notes, processed_by, processed_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: investment_tenure_requests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.investment_tenure_requests (id, investment_id, user_id, old_tenure_months, new_tenure_months, old_return_rate, new_return_rate, status, admin_id, rejection_reason, approved_at, rejected_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: investment_tenures; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.investment_tenures (id, category_id, duration_months, return_percentage, agreement_template_url, is_active, created_at, updated_at) FROM stdin;
3625eaa9-9b53-4c28-9662-aeb5025cd2d3	7018cdac-7590-4b11-b72c-8816dafa8071	6	5.00	\N	t	2025-12-18 18:12:24.826701+05:30	2025-12-18 18:12:24.826701+05:30
3cf678e1-8182-460f-bf8c-4bf79b3eb004	7018cdac-7590-4b11-b72c-8816dafa8071	12	10.00	\N	t	2025-12-18 18:12:24.832788+05:30	2025-12-18 18:12:24.832788+05:30
4b11a4c0-022e-4b84-be53-dc26d9db7d81	7018cdac-7590-4b11-b72c-8816dafa8071	24	20.00	\N	t	2025-12-18 18:12:24.833066+05:30	2025-12-18 18:12:24.833066+05:30
\.


--
-- Data for Name: investment_units; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.investment_units (id, category, unit_name, unit_price, description, icon_url, display_order, is_active, created_at, updated_at) FROM stdin;
5044679a-1cba-41d5-9a47-d55cbfb3748c	AGRICULTURE	Lot	234.00	1 Lot = 234 TCC Coins - Small agricultural investment unit	\N	1	t	2025-12-18 18:12:24.833225+05:30	2025-12-18 18:12:24.833225+05:30
b18b1e51-2263-4873-b2ec-69f97aee0296	AGRICULTURE	Plot	1000.00	1 Plot = 1000 TCC Coins - Medium agricultural investment unit	\N	2	t	2025-12-18 18:12:24.833225+05:30	2025-12-18 18:12:24.833225+05:30
e2edc681-1def-48b2-9e9d-d92861c16a3c	AGRICULTURE	Farm	2340.00	1 Farm = 2340 TCC Coins - Large agricultural investment unit	\N	3	t	2025-12-18 18:12:24.833225+05:30	2025-12-18 18:12:24.833225+05:30
b78b6be1-6456-43ac-aefc-97458593eafc	EDUCATION	Institution	5000.00	Institution investment - Educational facility	\N	1	t	2025-12-18 18:12:24.833225+05:30	2025-12-18 18:12:24.833225+05:30
b9523fd5-0cc4-42e1-b56f-686e7de4fc95	EDUCATION	Housing/Dormitory	3000.00	Housing/Dormitory investment - Student accommodation	\N	2	t	2025-12-18 18:12:24.833225+05:30	2025-12-18 18:12:24.833225+05:30
d8771baf-9a5a-4ccb-9d23-fb3f8b8b1972	MINERALS	Gold	500.00	Gold mining investment unit	\N	1	t	2025-12-18 18:12:24.833225+05:30	2025-12-18 18:12:24.833225+05:30
706dbde5-aba6-4428-a652-dd9d56325b26	MINERALS	Platinum	750.00	Platinum mining investment unit	\N	2	t	2025-12-18 18:12:24.833225+05:30	2025-12-18 18:12:24.833225+05:30
d92d516f-aee7-4bdc-8571-4a9c58dc71e9	MINERALS	Silver	400.00	Silver mining investment unit	\N	3	t	2025-12-18 18:12:24.833225+05:30	2025-12-18 18:12:24.833225+05:30
d1483848-cb0c-4bac-b43c-c1ca44a7008a	MINERALS	Diamond	1000.00	Diamond mining investment unit	\N	4	t	2025-12-18 18:12:24.833225+05:30	2025-12-18 18:12:24.833225+05:30
\.


--
-- Data for Name: investments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.investments (id, user_id, category, sub_category, tenure_id, amount, tenure_months, return_rate, expected_return, actual_return, start_date, end_date, agreement_url, insurance_taken, insurance_cost, status, transaction_id, withdrawal_transaction_id, withdrawn_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: ip_access_control; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ip_access_control (id, ip_address, ip_range_start, ip_range_end, type, reason, severity, expires_at, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: kyc_documents; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.kyc_documents (id, user_id, document_type, document_url, document_number, status, rejection_reason, verified_by, verified_at, created_at, updated_at) FROM stdin;
19792699-0865-4b03-bc31-97c4aa23e4d1	6b864809-fb5a-4a1f-a95e-edf87b7eeb5c	NATIONAL_ID	http://localhost:3000/api/uploads/kyc/6b864809-fb5a-4a1f-a95e-edf87b7eeb5c/1766214729986-3bbae1e9273ca7a9.jpg	12347596	APPROVED	\N	af223b34-da3f-44a6-bcd6-938034b46d50	2025-12-20 17:02:40.2427+05:30	2025-12-20 12:42:10.243309+05:30	2025-12-20 17:02:40.2427+05:30
a03dbd59-7f46-4d28-9681-50d2f1185b37	6b864809-fb5a-4a1f-a95e-edf87b7eeb5c	NATIONAL_ID	http://localhost:3000/api/uploads/kyc/6b864809-fb5a-4a1f-a95e-edf87b7eeb5c/1766214730072-37c5a11eb3846dbd.jpg	12347596	APPROVED	\N	af223b34-da3f-44a6-bcd6-938034b46d50	2025-12-20 17:02:40.2427+05:30	2025-12-20 12:42:10.245868+05:30	2025-12-20 17:02:40.2427+05:30
f6cc90cb-b06e-431f-9327-9a5382ee6b3c	6b864809-fb5a-4a1f-a95e-edf87b7eeb5c	NATIONAL_ID	http://localhost:3000/api/uploads/kyc/6b864809-fb5a-4a1f-a95e-edf87b7eeb5c/1766214730188-07c11225c6b266ae.jpg	\N	APPROVED	\N	af223b34-da3f-44a6-bcd6-938034b46d50	2025-12-20 17:02:40.2427+05:30	2025-12-20 12:42:10.246499+05:30	2025-12-20 17:02:40.2427+05:30
17838cd8-48d7-40a7-b40f-72a5c2042fe1	72fe9f39-5599-4339-bd5b-5adc6ca37996	NATIONAL_ID	http://localhost:3000/v1/uploads/kyc/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766231976699-88d24f25931a3364.jpg	52345234523	APPROVED	\N	af223b34-da3f-44a6-bcd6-938034b46d50	2025-12-20 21:41:59.838666+05:30	2025-12-20 17:29:37.071576+05:30	2025-12-20 21:41:59.838666+05:30
033867d1-3f9f-4155-a4ea-4c3489c63bb2	72fe9f39-5599-4339-bd5b-5adc6ca37996	NATIONAL_ID	http://localhost:3000/v1/uploads/kyc/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766231976775-e7bbd7c0b2924514.jpg	52345234523	APPROVED	\N	af223b34-da3f-44a6-bcd6-938034b46d50	2025-12-20 21:41:59.838666+05:30	2025-12-20 17:29:37.076463+05:30	2025-12-20 21:41:59.838666+05:30
0e6d3bb2-8232-47b3-b455-0962cc123375	72fe9f39-5599-4339-bd5b-5adc6ca37996	NATIONAL_ID	http://localhost:3000/v1/uploads/kyc/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766231977021-fae08e0798f8452a.jpg	\N	APPROVED	\N	af223b34-da3f-44a6-bcd6-938034b46d50	2025-12-20 21:41:59.838666+05:30	2025-12-20 17:29:37.078027+05:30	2025-12-20 21:41:59.838666+05:30
83ce2f2c-4b6d-49ee-8998-a4f303813106	8c6b2a0e-9b12-49db-8a5f-8dcb58572d72	NATIONAL_ID	http://localhost:3000/v1/uploads/kyc/8c6b2a0e-9b12-49db-8a5f-8dcb58572d72/1766254682205-0dc443d1a8da60fd.jpg	64654654	APPROVED	\N	af223b34-da3f-44a6-bcd6-938034b46d50	2025-12-20 23:48:42.866779+05:30	2025-12-20 23:48:02.312242+05:30	2025-12-20 23:48:42.866779+05:30
1e421dfe-96f5-4249-8d47-f491a8583bfa	8c6b2a0e-9b12-49db-8a5f-8dcb58572d72	NATIONAL_ID	http://localhost:3000/v1/uploads/kyc/8c6b2a0e-9b12-49db-8a5f-8dcb58572d72/1766254682248-72799d0c533efaa0.jpg	64654654	APPROVED	\N	af223b34-da3f-44a6-bcd6-938034b46d50	2025-12-20 23:48:42.866779+05:30	2025-12-20 23:48:02.313388+05:30	2025-12-20 23:48:42.866779+05:30
34f4fa18-4cf5-456f-b3ad-c7aa90e3fb05	8c6b2a0e-9b12-49db-8a5f-8dcb58572d72	NATIONAL_ID	http://localhost:3000/v1/uploads/kyc/8c6b2a0e-9b12-49db-8a5f-8dcb58572d72/1766254682288-ca6ecef694bc905b.jpg	\N	APPROVED	\N	af223b34-da3f-44a6-bcd6-938034b46d50	2025-12-20 23:48:42.866779+05:30	2025-12-20 23:48:02.313792+05:30	2025-12-20 23:48:42.866779+05:30
d2b48f71-6980-4d6c-a054-cf8f533a3a1e	39d53302-9bf3-4e79-95ac-883cae482d9e	PASSPORT	http://localhost:3000/v1/uploads/kyc/39d53302-9bf3-4e79-95ac-883cae482d9e/1767344909818-c2d09543168b6e5e.jpg	252525	APPROVED	\N	af223b34-da3f-44a6-bcd6-938034b46d50	2026-01-02 14:40:29.385817+05:30	2026-01-02 14:38:29.907701+05:30	2026-01-02 14:40:29.385817+05:30
66c07a0c-fade-4f51-bcda-a6a97b9de8d9	39d53302-9bf3-4e79-95ac-883cae482d9e	PASSPORT	http://localhost:3000/v1/uploads/kyc/39d53302-9bf3-4e79-95ac-883cae482d9e/1767344909851-43a0a601a3d55461.jpg	252525	APPROVED	\N	af223b34-da3f-44a6-bcd6-938034b46d50	2026-01-02 14:40:29.385817+05:30	2026-01-02 14:38:29.910392+05:30	2026-01-02 14:40:29.385817+05:30
b96ad895-49cc-4e0c-9282-c64b341a3f9b	39d53302-9bf3-4e79-95ac-883cae482d9e	NATIONAL_ID	http://localhost:3000/v1/uploads/kyc/39d53302-9bf3-4e79-95ac-883cae482d9e/1767344909884-96131182964b5980.jpg	\N	APPROVED	\N	af223b34-da3f-44a6-bcd6-938034b46d50	2026-01-02 14:40:29.385817+05:30	2026-01-02 14:38:29.910997+05:30	2026-01-02 14:40:29.385817+05:30
\.


--
-- Data for Name: metal_price_cache; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.metal_price_cache (id, metal_symbol, base_currency, price_per_ounce, price_per_gram, price_per_kilogram, api_timestamp, cached_at, expires_at, created_at, updated_at) FROM stdin;
94353b59-b21a-48fc-a594-ce2ab0bf0d49	SLLXPT	SLL	50026750.598244	1608397.380136	1608397380.136088	1766534399	2025-12-24 19:46:12.810942+05:30	2025-12-25 19:46:12.810942+05:30	2025-12-23 19:44:47.170705+05:30	2025-12-24 19:46:12.810942+05:30
1aa9c0d8-9dc8-4c2e-9f95-3d7159c376e7	SLLXAG	SLL	1612464.426458	51841.935126	51841935.125971	1766534399	2025-12-24 19:46:12.810865+05:30	2025-12-25 19:46:12.810865+05:30	2025-12-23 19:44:47.170647+05:30	2025-12-24 19:46:12.810865+05:30
355749d7-553b-4bce-9317-b4a18e550457	SLLXAU	SLL	103860730.999030	3339200.040782	3339200040.782245	1766534399	2025-12-24 19:46:12.810914+05:30	2025-12-25 19:46:12.810914+05:30	2025-12-23 19:44:47.170671+05:30	2025-12-24 19:46:12.810914+05:30
6dcd3ed0-095f-47d6-8130-dd6a3e208f8b	XAU	SLL	0.000000	0.000000	0.000000	1766534399	2025-12-24 19:46:12.816943+05:30	2025-12-25 19:46:12.816943+05:30	2025-12-23 19:44:47.176231+05:30	2025-12-24 19:46:12.816943+05:30
a8fbbdb0-dd05-4b73-aac7-be9299681e95	XAG	SLL	0.000001	0.000000	0.000020	1766534399	2025-12-24 19:46:12.817892+05:30	2025-12-25 19:46:12.817892+05:30	2025-12-23 19:44:47.175477+05:30	2025-12-24 19:46:12.817892+05:30
4393eef6-c60d-4ada-852c-8adf15466cf2	XPT	SLL	0.000000	0.000000	0.000001	1766534399	2025-12-24 19:46:12.819993+05:30	2025-12-25 19:46:12.819993+05:30	2025-12-23 19:44:47.176496+05:30	2025-12-24 19:46:12.819993+05:30
\.


--
-- Data for Name: notification_preferences; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notification_preferences (id, user_id, push_enabled, email_enabled, sms_enabled, notification_types, quiet_hours_start, quiet_hours_end, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: notification_templates; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notification_templates (id, template_code, channel, subject, body_template, variables, is_active, created_at, updated_at) FROM stdin;
ff69e7bd-b698-4e29-81b2-9f2b78b728fb	OTP_SMS	SMS	\N	Your TCC verification code is {{otp}}. Valid for 5 minutes.	["otp"]	t	2025-12-18 18:12:24.900455+05:30	2025-12-18 18:12:24.900455+05:30
577bef4c-72f6-4fc2-bdef-7b7dfaa1e653	WELCOME_EMAIL	EMAIL	Welcome to TCC!	Hello {{name}}, Welcome to TCC. Your account has been created successfully.	["name"]	t	2025-12-18 18:12:24.900455+05:30	2025-12-18 18:12:24.900455+05:30
31d45743-70fb-42fe-a1be-da0d3265a27a	TRANSFER_SUCCESS	PUSH	\N	Transfer of {{amount}} to {{recipient}} successful	["amount", "recipient"]	t	2025-12-18 18:12:24.900455+05:30	2025-12-18 18:12:24.900455+05:30
eb90637e-d223-4c32-a2f7-6cdf1c0a4825	KYC_APPROVED	EMAIL	KYC Verification Approved	Congratulations {{name}}! Your KYC has been approved.	["name"]	t	2025-12-18 18:12:24.900455+05:30	2025-12-18 18:12:24.900455+05:30
e7e849f8-57f6-4098-a79c-b82b74d3040c	INVESTMENT_MATURED	PUSH	\N	Your {{category}} investment of {{amount}} has matured!	["category", "amount"]	t	2025-12-18 18:12:24.900455+05:30	2025-12-18 18:12:24.900455+05:30
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notifications (id, user_id, type, title, message, data, is_read, read_at, created_at) FROM stdin;
b3a2e090-6713-4daf-96ac-7f5c92b96ddb	6b864809-fb5a-4a1f-a95e-edf87b7eeb5c	KYC	KYC Verified	Your KYC verification has been approved. You can now access all features.	{"status": "APPROVED", "reviewed_by": "af223b34-da3f-44a6-bcd6-938034b46d50"}	f	\N	2025-12-20 17:02:40.2427+05:30
8229fe1e-e132-40eb-b36b-63accd15e806	72fe9f39-5599-4339-bd5b-5adc6ca37996	KYC	KYC Rejected	Your KYC verification was rejected. Reason: Document appears invalid or tampered	{"status": "REJECTED", "reviewed_by": "af223b34-da3f-44a6-bcd6-938034b46d50"}	f	\N	2025-12-20 17:03:01.067975+05:30
c4090378-8a0d-4da1-a304-f0e04be28ef5	72fe9f39-5599-4339-bd5b-5adc6ca37996	KYC	KYC Verified	Your KYC verification has been approved. You can now access all features.	{"status": "APPROVED", "reviewed_by": "af223b34-da3f-44a6-bcd6-938034b46d50"}	f	\N	2025-12-20 21:41:59.838666+05:30
e202ac63-a3ce-4aa6-8908-86f280b9be21	8c6b2a0e-9b12-49db-8a5f-8dcb58572d72	KYC	KYC Rejected	Your KYC verification was rejected. Reason: Photo does not match document	{"status": "REJECTED", "reviewed_by": "af223b34-da3f-44a6-bcd6-938034b46d50"}	f	\N	2025-12-20 23:46:43.364045+05:30
83082cc6-908e-4c99-90fe-b40b1ab22503	8c6b2a0e-9b12-49db-8a5f-8dcb58572d72	KYC	KYC Verified	Your KYC verification has been approved. You can now access all features.	{"status": "APPROVED", "reviewed_by": "af223b34-da3f-44a6-bcd6-938034b46d50"}	f	\N	2025-12-20 23:48:42.866779+05:30
cb33f95e-c2cf-41d3-82e1-4de3e20e85c6	39d53302-9bf3-4e79-95ac-883cae482d9e	KYC	KYC Verified	Your KYC verification has been approved. You can now access all features.	{"status": "APPROVED", "reviewed_by": "af223b34-da3f-44a6-bcd6-938034b46d50"}	f	\N	2026-01-02 14:40:29.385817+05:30
\.


--
-- Data for Name: otp_codes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.otp_codes (id, user_id, phone, email, code, purpose, attempts, is_verified, expires_at, verified_at, created_at) FROM stdin;
\.


--
-- Data for Name: otps; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.otps (id, phone, country_code, otp, purpose, is_verified, attempts, expires_at, created_at) FROM stdin;
4c08fc38-88d7-4c55-b5a7-a2dc417fd66a	9876543210	+232	125786	REGISTRATION	f	0	2025-12-19 15:27:22.27+05:30	2025-12-19 15:22:22.271685+05:30
81381f69-8ca1-4c1e-a22a-74e0b6429c6b	9876543211	+232	833181	REGISTRATION	t	0	2025-12-19 22:31:41.513+05:30	2025-12-19 22:26:41.517652+05:30
fee7be93-3f80-4031-8f5b-c03a32bdbd7d	9876543213	+232	702161	REGISTRATION	t	0	2025-12-19 22:36:27.913+05:30	2025-12-19 22:31:27.91694+05:30
c9b3c3c1-6552-44e2-a214-3ef8ceb4aba1	9876543214	+232	985105	REGISTRATION	t	0	2025-12-19 22:39:52.378+05:30	2025-12-19 22:34:52.380959+05:30
7ace125c-0e3a-4513-b313-e1196e3d46c0	9876543215	+232	212201	REGISTRATION	t	0	2025-12-19 23:32:35.422+05:30	2025-12-19 23:27:35.424496+05:30
6caed7b5-519d-44ce-b635-bc05689323d8	9876543211	+232	274845	LOGIN	f	0	2025-12-20 00:55:47.485+05:30	2025-12-20 00:50:47.485973+05:30
77e22522-2a1d-4a54-a3d7-5ba70a6c3dea	9876543210	+232	794449	LOGIN	f	0	2025-12-20 00:55:55.415+05:30	2025-12-20 00:50:55.415818+05:30
5338d039-8615-480f-aed8-88ce7a1e883b	9876543215	+232	344619	LOGIN	f	0	2025-12-20 02:26:28.438+05:30	2025-12-20 02:21:28.440737+05:30
3df0efd1-6fc8-41ed-950e-5eb6fd71f505	9874654326	+232	596197	REGISTRATION	t	0	2025-12-20 12:46:17.945+05:30	2025-12-20 12:41:17.95097+05:30
fddffd26-65f4-485c-ad43-d7c9673f332e	9876543216	+232	410764	REGISTRATION	t	0	2025-12-20 23:45:21.236+05:30	2025-12-20 23:40:21.244302+05:30
e8b3f11e-9f3a-46de-acd9-c78c34d1d120	9876543225	+232	306761	REGISTRATION	t	0	2026-01-02 14:42:35.609+05:30	2026-01-02 14:37:35.611883+05:30
efa25b3e-6955-43d0-b30a-a49e920bbd49	9876543225	+232	711538	TRANSFER	t	0	2026-01-02 16:39:22.442+05:30	2026-01-02 16:34:22.443055+05:30
\.


--
-- Data for Name: password_history; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.password_history (id, user_id, password_hash, created_at) FROM stdin;
\.


--
-- Data for Name: polls; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.polls (id, title, question, options, voting_charge, start_time, end_time, status, created_by_admin_id, total_votes, total_revenue, results, created_at, updated_at) FROM stdin;
424e2a2f-57d9-40b0-81fd-6558c5fd9357	sdafasdfasdfas	asdfasdfasdfasdfsadfsadfasdf	["asdfasdfas", "asdfasdfasd"]	50.00	2025-12-23 15:46:19.602+05:30	2025-12-30 15:46:19.602+05:30	DRAFT	af223b34-da3f-44a6-bcd6-938034b46d50	0	0.00	\N	2025-12-23 15:46:29.222706+05:30	2025-12-23 15:46:29.222706+05:30
4b195b5b-146a-4550-8389-c731ce41a7bc	2345234	fgsfdgsfdgsdfg	["afssdf", "asdfasdf"]	50.00	2025-12-23 15:53:11.63+05:30	2025-12-30 15:53:11.63+05:30	DRAFT	af223b34-da3f-44a6-bcd6-938034b46d50	0	0.00	\N	2025-12-23 15:53:20.721792+05:30	2025-12-23 15:53:20.721792+05:30
87630d1a-250c-4f89-8c11-b6525e1bb84d	2345234	fgsfdgsfdgsdfg	["afssdf", "asdfasdf"]	50.00	2025-12-23 15:53:11.63+05:30	2025-12-30 15:53:11.63+05:30	DRAFT	af223b34-da3f-44a6-bcd6-938034b46d50	0	0.00	\N	2025-12-23 15:53:37.613194+05:30	2025-12-23 15:53:37.613194+05:30
2f34bd37-b158-4d4e-bc05-82baaf1a5f48	asdfasf	asdfasdfsdfsfs	["asdfasd", "asdfasdf"]	50.00	2025-12-23 16:09:25.353+05:30	2025-12-30 16:09:25.353+05:30	DRAFT	af223b34-da3f-44a6-bcd6-938034b46d50	0	0.00	\N	2025-12-23 16:09:36.21334+05:30	2025-12-23 16:09:36.21334+05:30
aff63447-5599-4fd5-a8f6-bca9065442f0	adsfasdfasdf	asdfasdfasdfasdfsd	["asdfasdfadsf", "asfadsfasdf"]	50.00	2025-12-23 16:10:18.78+05:30	2025-12-30 16:10:18.78+05:30	DRAFT	af223b34-da3f-44a6-bcd6-938034b46d50	0	0.00	\N	2025-12-23 16:10:24.820821+05:30	2025-12-23 16:10:24.820821+05:30
0cfd4031-e6fc-4ad4-85d9-9e9ef54dbd5c	adsfasdfasdf	asdfasdfasdfasdfsd	["asdfasdfadsf", "asfadsfasdf"]	50.00	2025-12-23 16:10:18.78+05:30	2025-12-30 16:10:18.78+05:30	DRAFT	af223b34-da3f-44a6-bcd6-938034b46d50	0	0.00	\N	2025-12-23 16:10:28.777614+05:30	2025-12-23 16:10:28.777614+05:30
8532221b-a526-4f6a-9b91-4b8994ed9491	adsfasdfasdf	asdfasdfasdfasdfsd	["asdfasdfadsf", "asfadsfasdf"]	50.00	2025-12-23 16:10:18.78+05:30	2025-12-30 16:10:18.78+05:30	DRAFT	af223b34-da3f-44a6-bcd6-938034b46d50	0	0.00	\N	2025-12-23 16:10:29.315326+05:30	2025-12-23 16:10:29.315326+05:30
819ae302-9b77-4218-95ec-3335f3fff58f	adsfasdfasdf	asdfasdfasdfasdfsd	["asdfasdfadsf", "asfadsfasdf"]	50.00	2025-12-23 16:10:18.78+05:30	2025-12-30 16:10:18.78+05:30	DRAFT	af223b34-da3f-44a6-bcd6-938034b46d50	0	0.00	\N	2025-12-23 16:10:30.159132+05:30	2025-12-23 16:10:30.159132+05:30
c309bf71-4b72-4b17-a458-2681c44864df	Poll title	details about the poll	["Op 1", "Op 2"]	50.00	2025-12-23 19:05:27.046+05:30	2025-12-30 19:05:27.046+05:30	DRAFT	af223b34-da3f-44a6-bcd6-938034b46d50	0	0.00	\N	2025-12-23 19:05:49.708656+05:30	2025-12-23 19:05:49.708656+05:30
a652f604-63f9-4b5d-a1b3-d086dfe11713	Poll title	details about the poll	["Op 1", "Op 2"]	50.00	2025-12-23 19:05:27.046+05:30	2025-12-30 19:05:27.046+05:30	DRAFT	af223b34-da3f-44a6-bcd6-938034b46d50	0	0.00	\N	2025-12-23 19:06:00.116965+05:30	2025-12-23 19:06:00.116965+05:30
43a1ed07-4cd3-4371-880e-184ebfb192db	Poll title	details about the poll	["Op 1", "Op 2"]	50.00	2025-12-23 19:05:27.046+05:30	2025-12-30 19:05:27.046+05:30	DRAFT	af223b34-da3f-44a6-bcd6-938034b46d50	0	0.00	\N	2025-12-23 19:06:00.733668+05:30	2025-12-23 19:06:00.733668+05:30
2d236ab1-9781-4db3-b667-4985424daf8d	Poll title	details about the poll	["Op 1", "Op 2"]	50.00	2025-12-23 19:05:27.046+05:30	2025-12-30 19:05:27.046+05:30	DRAFT	af223b34-da3f-44a6-bcd6-938034b46d50	0	0.00	\N	2025-12-23 19:06:00.924952+05:30	2025-12-23 19:06:00.924952+05:30
5e25e860-0e54-43b8-8119-96aa2202b628	Poll title	details about the poll	["Op 1", "Op 2"]	50.00	2025-12-23 19:05:27.046+05:30	2025-12-30 19:05:27.046+05:30	DRAFT	af223b34-da3f-44a6-bcd6-938034b46d50	0	0.00	\N	2025-12-23 19:06:01.097504+05:30	2025-12-23 19:06:01.097504+05:30
5f0f6293-af59-4509-9029-7a849bcdb2c8	Poll title	details about the poll	["Op 1", "Op 2"]	50.00	2025-12-23 19:05:27.046+05:30	2025-12-30 19:05:27.046+05:30	DRAFT	af223b34-da3f-44a6-bcd6-938034b46d50	0	0.00	\N	2025-12-23 19:06:01.26367+05:30	2025-12-23 19:06:01.26367+05:30
3922ffe2-96fa-437e-a3a0-62e26746c1c5	Poll title	details about the poll	["Op 1", "Op 2"]	50.00	2025-12-23 19:05:27.046+05:30	2025-12-30 19:05:27.046+05:30	DRAFT	af223b34-da3f-44a6-bcd6-938034b46d50	0	0.00	\N	2025-12-23 19:06:01.467922+05:30	2025-12-23 19:06:01.467922+05:30
\.


--
-- Data for Name: push_tokens; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.push_tokens (id, user_id, token, platform, device_id, is_active, last_used_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: rate_limits; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rate_limits (id, identifier, endpoint, request_count, window_start, window_end, created_at) FROM stdin;
\.


--
-- Data for Name: referrals; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.referrals (id, referrer_id, referred_id, reward_amount, reward_type, status, conditions_met, conditions, paid_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.refresh_tokens (id, user_id, token, expires_at, created_at) FROM stdin;
45f4bae1-7656-47ab-a2fb-8eb8d6b218cf	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NjA2MjY0MywiZXhwIjoxNzY2NjY3NDQzfQ._0OK2rh4bCdqq7mSMCvdp6ILMSF5bPjuUb2Yb_DC2H4	2025-12-25 18:27:23.211+05:30	2025-12-18 18:27:23.211743+05:30
b34b1280-0c06-4efa-943c-6e047e3f72e5	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NjA2MzAwMywiZXhwIjoxNzY2NjY3ODAzfQ.zRglNrtSnkl9tT1CcQyIFETJfcs2qCGy0CBuYYlL-aA	2025-12-25 18:33:23.114+05:30	2025-12-18 18:33:23.114371+05:30
6e29c0b7-5fe7-4c7c-aab3-eac144687438	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NjA2MzA2MiwiZXhwIjoxNzY2NjY3ODYyfQ.HB27il73PXzJVqFtLP4bEqPGp3GxWHyiLt1Z8u9lfEk	2025-12-25 18:34:22.772+05:30	2025-12-18 18:34:22.772441+05:30
cf442c78-35e4-4d78-9576-92d1d5fad940	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NjEzNzg5OSwiZXhwIjoxNzY2NzQyNjk5fQ.ANcb-PyWB2sxM-HPZdii6TNUT2S3NVHLfbDiJna8kgc	2025-12-26 15:21:39.435+05:30	2025-12-19 15:21:39.436245+05:30
025e82c5-06b7-4ff6-b1f8-047c9027d872	1880ea25-a5bf-4c10-8b2e-e7ff1728445b	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxODgwZWEyNS1hNWJmLTRjMTAtOGIyZS1lN2ZmMTcyODQ0NWIiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGNAdGNjLmNvbSIsImlhdCI6MTc2NjEzNzk0OCwiZXhwIjoxNzY2NzQyNzQ4fQ.g3cOnZ50lcI-W3y7JpPbyUvnujQuB_MRZDaH-ktiOBg	2025-12-26 15:22:28.047+05:30	2025-12-19 15:22:28.047443+05:30
8acb3470-c7fb-48d2-aaae-bf6aa173362b	15a46f44-4094-4b25-a4d3-51a3f682a4b9	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxNWE0NmY0NC00MDk0LTRiMjUtYTRkMy01MWEzZjY4MmE0YjkiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMyQHRjYy5jb20iLCJpYXQiOjE3NjYxNjM0MTAsImV4cCI6MTc2Njc2ODIxMH0.NgkkRZwOOOcpt8U18sY5EaK-cEGSEw6v_rsT9ON8FrM	2025-12-26 22:26:50.376+05:30	2025-12-19 22:26:50.376605+05:30
ad63d370-baef-4186-b4d5-1389f9124ae4	43f2c95b-4fe8-4481-aa42-77125cef5d1f	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0M2YyYzk1Yi00ZmU4LTQ0ODEtYWE0Mi03NzEyNWNlZjVkMWYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidDFAdGNjLmNvbSIsImlhdCI6MTc2NjE2MzY5OCwiZXhwIjoxNzY2NzY4NDk4fQ.YHUXLvIqqbSKG3cdxEUvXTetG5MQXtyXVGPFVOcU4NE	2025-12-26 22:31:38.653+05:30	2025-12-19 22:31:38.653836+05:30
3726fcfa-e973-446c-98f7-31daa6072a07	42fa68c5-e80b-4100-9aad-c28300e33fff	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0MmZhNjhjNS1lODBiLTQxMDAtOWFhZC1jMjgzMDBlMzNmZmYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidDJAdGNjLmNvbSIsImlhdCI6MTc2NjE2MzkwNCwiZXhwIjoxNzY2NzY4NzA0fQ.MXR4q-NqOLH6dAuRxLTCWQN32gCQA1zCk07JC98Zu7g	2025-12-26 22:35:04.622+05:30	2025-12-19 22:35:04.622377+05:30
5e5daa7b-2656-4678-9669-6d7e39859ae6	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjYxNjcwNjcsImV4cCI6MTc2Njc3MTg2N30.rZZbY5ZgAWTPHSc6WE1tHnGr5Ub6ewTJM0BD3bi3BvQ	2025-12-26 23:27:47.768+05:30	2025-12-19 23:27:47.768338+05:30
f26a6a92-2ec1-450f-924d-434a05fde053	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NjE2NzE2MiwiZXhwIjoxNzY2NzcxOTYyfQ.06O7P79wXLLdbA1gXR6ZwWoZIOCPYCEDqrnigjgOkW8	2025-12-26 23:29:22.114+05:30	2025-12-19 23:29:22.114413+05:30
77e5f190-fabf-48d7-a612-2fa0e2b8f7c9	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NjE2OTQyMCwiZXhwIjoxNzY2Nzc0MjIwfQ.FB_PTcZUFshgbfFYMGgq6f4j565a9hr15JrfHMEV6_4	2025-12-27 00:07:00.601+05:30	2025-12-20 00:07:00.601819+05:30
614c0329-7768-4c7a-9244-b63447436e84	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NjE3MDYxNCwiZXhwIjoxNzY2Nzc1NDE0fQ.8EyqoparIGAZwPjeQxYz2QwwSN_66a1mVYYvASRLQp4	2025-12-27 00:26:54.217+05:30	2025-12-20 00:26:54.218131+05:30
e2e9ea25-f6b2-42c1-8942-0290d6ce01fc	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NjE3MjE2NywiZXhwIjoxNzY2Nzc2OTY3fQ.clrgyffku5JXmETZ_upGXkzSHQ2VbTTxbv9wJIXBsGE	2025-12-27 00:52:47.54+05:30	2025-12-20 00:52:47.540828+05:30
28b30546-9682-4f5c-aa35-882d008443d4	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjYxNzc5OTUsImV4cCI6MTc2Njc4Mjc5NX0.oSW54AJtGikswUkyGL7sif1mQPRoEdpBtaiK78fsMqM	2025-12-27 02:29:55.437+05:30	2025-12-20 02:29:55.43839+05:30
d89711c6-c6d8-4385-ae9d-bd24d616a831	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjYyMDk5MzksImV4cCI6MTc2NjgxNDczOX0.iCDRnfvNOwGS5yEDJUKSn6KZ0h-4YBkzLZti1SSphEE	2025-12-27 11:22:19.2+05:30	2025-12-20 11:22:19.2014+05:30
7f2f2570-9342-4fc9-a4ad-d0c9daf6d9d4	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NjIxMTI0OCwiZXhwIjoxNzY2ODE2MDQ4fQ.yseT7TGSUhAksaHt5mwz_PKS0G3tjtCLJ-bTYIsEeWM	2025-12-27 11:44:08.618+05:30	2025-12-20 11:44:08.619135+05:30
ae0378f6-b0ad-4a87-af03-dc23261ebd3a	6b864809-fb5a-4a1f-a95e-edf87b7eeb5c	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI2Yjg2NDgwOS1mYjVhLTRhMWYtYTk1ZS1lZGY4N2I3ZWViNWMiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoic2NAdGNjLmNvbSIsImlhdCI6MTc2NjIxNDY5MywiZXhwIjoxNzY2ODE5NDkzfQ.N08EIWxshn1SEW7wsmT-DZRirf1Erd-RDRSjl3CxQx0	2025-12-27 12:41:33.578+05:30	2025-12-20 12:41:33.579428+05:30
f50e5e02-952f-41ed-adf4-bfde75593162	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NjIxNjc0MCwiZXhwIjoxNzY2ODIxNTQwfQ.qYKVf0EuHNI0NFLie1vJtYdgV8VZjluwS--_7tGHYlc	2025-12-27 13:15:40.246+05:30	2025-12-20 13:15:40.248862+05:30
bebd628b-2eb4-452a-8e6f-f4f09426f584	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NjIyMDA5OSwiZXhwIjoxNzY2ODI0ODk5fQ.0U378MEyLtXYr4jticu2Xc1uh-9PdlugaaZmK-ZeEMY	2025-12-27 14:11:39.448+05:30	2025-12-20 14:11:39.451866+05:30
7e520c57-4cfb-4b9a-bd03-ea59588541ed	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NjIyNTM4OSwiZXhwIjoxNzY2ODMwMTg5fQ.rovXEnFCyudqTJz_ZFd33Gajv2dgSMTrZbcz-pyccXY	2025-12-27 15:39:49.722+05:30	2025-12-20 15:39:49.72294+05:30
3d0ba237-665a-455a-a2e8-18f487b4fa57	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjYyMjU5NjQsImV4cCI6MTc2NjgzMDc2NH0.ZH9CpABR_N1I5ppKC8cHnig7FTsNTBUbXoJyMnG1jXY	2025-12-27 15:49:24.314+05:30	2025-12-20 15:49:24.31497+05:30
017dcf57-2f45-4c57-b5ee-9cd7672bad58	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NjIyOTc0NSwiZXhwIjoxNzY2ODM0NTQ1fQ.Ad1PPK9P6Wd1XDKNclDvCWTpuSM94ldEPS0nxdA5wl8	2025-12-27 16:52:25.53+05:30	2025-12-20 16:52:25.530942+05:30
b4466531-e399-4f3a-b537-6d8729459ed7	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjYyMzA2OTMsImV4cCI6MTc2NjgzNTQ5M30.dGGbmsTVC5Pt7HvoRoYNuW9AuqJa6wnNWo_xhV8-pCg	2025-12-27 17:08:13.068+05:30	2025-12-20 17:08:13.068907+05:30
b3e64f37-5217-43d9-bfaf-3d7ed69f0a5f	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjYyMzEzNTUsImV4cCI6MTc2NjgzNjE1NX0.96wOE0Y6jECOC4E7rTEsrcO_4qZlwS94co4tZYxpHgI	2025-12-27 17:19:15.003+05:30	2025-12-20 17:19:15.003927+05:30
2b7b1fbb-c2eb-4e85-ada7-d4a70f61c76b	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjYyMzIxODIsImV4cCI6MTc2NjgzNjk4Mn0.EvU0h3e-osG5Foa1EwIWhYtMyZfpnegadLuWFXvnvpY	2025-12-27 17:33:02.153+05:30	2025-12-20 17:33:02.153519+05:30
35810f60-6c15-4014-91e4-3f7de57fd5ac	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjYyMzU4NjEsImV4cCI6MTc2Njg0MDY2MX0.qkWh0OfOsTcxetD6mdoNtwtQTE-4H6Fr5iyTn5OcQrw	2025-12-27 18:34:21.98+05:30	2025-12-20 18:34:21.98154+05:30
3a608d4c-3606-4400-9bc4-c581d89d46a9	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NjI0MjU3MCwiZXhwIjoxNzY2ODQ3MzcwfQ.Sntm3vYGongOJ0w3aU3OxyVi_AqMLgVUpXbzhGqAUbc	2025-12-27 20:26:10.485+05:30	2025-12-20 20:26:10.487+05:30
7f6072a3-b32d-4471-8c5f-11ebebb4e207	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjYyNDM3NjksImV4cCI6MTc2Njg0ODU2OX0.4GC7zG3YdimjmqZzlazxTvCtzSdNxmsl54mN3TBZCYc	2025-12-27 20:46:09.049+05:30	2025-12-20 20:46:09.0499+05:30
cd7dc2b5-b02a-4e5b-bd1b-948dc841979f	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NjI0NjcwOCwiZXhwIjoxNzY2ODUxNTA4fQ.F7LmSejS32u_1Izve5QfXhEVG0HpeXicaRCBZe9xUfM	2025-12-27 21:35:08.83+05:30	2025-12-20 21:35:08.831447+05:30
81ef93b6-cc44-4141-8206-98c34e5dc95a	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjYyNDgyNzQsImV4cCI6MTc2Njg1MzA3NH0.L9N84eVGyFvVNoGNgNRKyWbt5ofvftmIDuXpQZZGi3k	2025-12-27 22:01:14.861+05:30	2025-12-20 22:01:14.861752+05:30
a81beaac-ad5a-4415-90dc-fe2c7a25fff2	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjYyNTE1MTIsImV4cCI6MTc2Njg1NjMxMn0.gg89mux9AKEqseKlWZkIPlB6BA7NMuBMZb93kF1xc4o	2025-12-27 22:55:12.167+05:30	2025-12-20 22:55:12.168399+05:30
1919e5c8-a0a5-4dcf-adec-d390059f52c6	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjYyNTI2NjEsImV4cCI6MTc2Njg1NzQ2MX0.vhhZfKgAHgLP-pQyYF4RSFQcC_NlsVjOsyWWjDZwcJ0	2025-12-27 23:14:21.944+05:30	2025-12-20 23:14:21.945586+05:30
791524d7-e99d-4e26-90d1-2b81fa5094d4	8c6b2a0e-9b12-49db-8a5f-8dcb58572d72	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI4YzZiMmEwZS05YjEyLTQ5ZGItOGE1Zi04ZGNiNTg1NzJkNzIiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoic2hAdGNjLmNvbSIsImlhdCI6MTc2NjI1NDIyOCwiZXhwIjoxNzY2ODU5MDI4fQ.o2fX615P2Zsbcac8DkY6RbIkBb4NjQihuDEzXIhP0Sk	2025-12-27 23:40:28.364+05:30	2025-12-20 23:40:28.36534+05:30
2ac45966-3fef-41df-a345-30db1d01b23e	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NjI1NDQ2MCwiZXhwIjoxNzY2ODU5MjYwfQ.kA8zcRRSFet7GmoprwmGGCgNag6ybWqzwIiOeDf6Io4	2025-12-27 23:44:20.901+05:30	2025-12-20 23:44:20.901735+05:30
a3090480-bfd7-499c-b01a-10cbf8d3b19f	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NjM3NzI2NCwiZXhwIjoxNzY2OTgyMDY0fQ.zImtCXkF1QW4fpv7SJsJanZ7j_VbZQM5fTcZ6IXDIHQ	2025-12-29 09:51:04.193+05:30	2025-12-22 09:51:04.193679+05:30
559bcd6e-4031-4910-90b3-c1417de1887d	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NjM3NzY0NiwiZXhwIjoxNzY2OTgyNDQ2fQ.aIE_Y3mGI9lAjPRnhCWCRo9cRVq8CzaM8IqNaIVSYnk	2025-12-29 09:57:26.918+05:30	2025-12-22 09:57:26.919144+05:30
ece01f6c-f8bd-4f8c-9e80-35dac2df67dc	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NjM5OTIwMSwiZXhwIjoxNzY3MDA0MDAxfQ.7eyTOsQFDiC1o4j5nmN12pSEgC99q3NNggIYfIGybh8	2025-12-29 15:56:41.541+05:30	2025-12-22 15:56:41.542289+05:30
45cf3cf3-b6fa-4197-85dc-2b867e99fc97	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjY0MTA2MjksImV4cCI6MTc2NzAxNTQyOX0.WEhRswyay5Zhb0_cYJW5X-SJpU-xTwixe7fzPOAoTko	2025-12-29 19:07:09.72+05:30	2025-12-22 19:07:09.721479+05:30
8a4d8bd9-9c55-470a-861a-2d71f1d33ef4	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NjQxMTUzMSwiZXhwIjoxNzY3MDE2MzMxfQ.M1s0_iTvnIAQZ6xey6KUhefWS_H7Ah708-EsKas6Qvw	2025-12-29 19:22:11.287+05:30	2025-12-22 19:22:11.287931+05:30
98144f94-a560-4804-8c44-0432fc29c18e	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NjQxMjQwMCwiZXhwIjoxNzY3MDE3MjAwfQ.PMw523oxK9hk1sNCP8dV4IKAlTEJInnX-849kCCNxVQ	2025-12-29 19:36:40.085+05:30	2025-12-22 19:36:40.086445+05:30
b86767ad-6bf6-4ac6-90d5-a4f96eab8991	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NjQ4NjA0NywiZXhwIjoxNzY3MDkwODQ3fQ.DXgjWGZNLCqpywPdK5OdQVRpvYx4ZZID6HenQP0Wdfc	2025-12-30 16:04:07.646+05:30	2025-12-23 16:04:07.647059+05:30
31cc6618-3024-4c41-997f-1b1084c5b01e	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjY0OTY0MzksImV4cCI6MTc2NzEwMTIzOX0.g21RKOy4YPUDwE18c3MMzObqidhB7VgELddboJ3sl8M	2025-12-30 18:57:19.618+05:30	2025-12-23 18:57:19.619254+05:30
aabf3be1-9b43-4363-9751-eb03088b1f27	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NjQ5NjYzNCwiZXhwIjoxNzY3MTAxNDM0fQ.8Pc5NJLtvCI0moZrtuMw5p7qOHVJ_x7Ge35HCJQHgFg	2025-12-30 19:00:34.754+05:30	2025-12-23 19:00:34.754697+05:30
6860d8d8-a49b-42ad-9e0b-572996e3821a	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjY1NDUxMTEsImV4cCI6MTc2NzE0OTkxMX0.lsWPyqpvetQZDLT3EX4y40Z7VDq6EYR4yh1LCi6V3cw	2025-12-31 08:28:31.105+05:30	2025-12-24 08:28:31.105861+05:30
c34dd935-68b6-4060-95c7-d8062bff4ff5	1880ea25-a5bf-4c10-8b2e-e7ff1728445b	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxODgwZWEyNS1hNWJmLTRjMTAtOGIyZS1lN2ZmMTcyODQ0NWIiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGNAdGNjLmNvbSIsImlhdCI6MTc2NjU1MjU1MiwiZXhwIjoxNzY3MTU3MzUyfQ.qj6U5i11TO6IInfFpMdB6yvS4sCHQOAY0A94jzl5G80	2025-12-31 10:32:32.864+05:30	2025-12-24 10:32:32.865028+05:30
2bb9c607-3411-43e5-a71d-a105a34631d6	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjY1NzExMzksImV4cCI6MTc2NzE3NTkzOX0.IuxES9u2EnawfoRjHg1Tr5Mn2f7-4y7-Hc6SF_euV6A	2025-12-31 15:42:19.96+05:30	2025-12-24 15:42:19.961415+05:30
012d18fd-eb31-4d00-ad2b-e7b8b7c19972	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjY1NzUyNTYsImV4cCI6MTc2NzE4MDA1Nn0.3I6o60XhajBy98WrYi5SsFhtWVELGYo2UCRqLHbbXyw	2025-12-31 16:50:56.551+05:30	2025-12-24 16:50:56.551668+05:30
6cb7cb2f-06e6-4598-8075-c905ca2948d1	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjY1Nzk3NDcsImV4cCI6MTc2NzE4NDU0N30.SnEARX36V4MVl0xmSPNResPARPgLfZ-3NH1ex0aEyM0	2025-12-31 18:05:47.85+05:30	2025-12-24 18:05:47.851157+05:30
2d3174b4-d72d-4826-9098-314ce6db00c0	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjY1ODA2MzYsImV4cCI6MTc2NzE4NTQzNn0.ildGH3jSujg2EPmmkyVOlfU85gSt0rhDvv3LlIK70z0	2025-12-31 18:20:36.639+05:30	2025-12-24 18:20:36.640108+05:30
41485f9e-ec20-43d3-88cc-366b033a4449	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjY1ODQyNjAsImV4cCI6MTc2NzE4OTA2MH0.QWsaV7gwIGhzskqGsgCTu11Qg2H8Yt9ISk1E4rd1qE4	2025-12-31 19:21:00.576+05:30	2025-12-24 19:21:00.577668+05:30
83256865-6d42-4009-be09-6a01241dda80	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjY1ODgwNDcsImV4cCI6MTc2NzE5Mjg0N30.7h9E5M7oXmmCpVR-8gsgWFqqk4oXJxovzwWsxqleGt4	2025-12-31 20:24:07.774+05:30	2025-12-24 20:24:07.776057+05:30
7e2e2120-0cf4-4b6f-aa5d-02f87f936bd7	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjY2MzMwMzIsImV4cCI6MTc2NzIzNzgzMn0.8Xg4JsWEoXnviIYMj9961ggRZLJLBSzxKWEcE-8ABfA	2026-01-01 08:53:52.895+05:30	2025-12-25 08:53:52.896145+05:30
e088a71d-953b-4d9d-b254-5b2de770a020	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjY2MzU4MTcsImV4cCI6MTc2NzI0MDYxN30.2GwFeScTSaATnNCBMspRfrWj__-kd4_baRkidz58Zkw	2026-01-01 09:40:17.075+05:30	2025-12-25 09:40:17.076222+05:30
78c3050e-616a-43c8-b9e3-c5f93caa43ca	1880ea25-a5bf-4c10-8b2e-e7ff1728445b	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxODgwZWEyNS1hNWJmLTRjMTAtOGIyZS1lN2ZmMTcyODQ0NWIiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGNAdGNjLmNvbSIsImlhdCI6MTc2NjY1MjUxMSwiZXhwIjoxNzY3MjU3MzExfQ.61IyxzdVp_gl36yziNf_6yVzMpJ5nGOTkNtZtnruOMY	2026-01-01 14:18:31.346+05:30	2025-12-25 14:18:31.346775+05:30
74a70a2f-627e-47f0-8a36-28dacd69ec6e	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjY2NTgxNzMsImV4cCI6MTc2NzI2Mjk3M30._V6lhRTAB_gZtG03ax-yt_lWnCViOg0jDIPwv9sii4o	2026-01-01 15:52:53.152+05:30	2025-12-25 15:52:53.153001+05:30
1b1bc351-efe2-480f-8f6d-7c0075ac93d4	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjY2NjIyOTMsImV4cCI6MTc2NzI2NzA5M30.YJmw_c3Hj92F6qVDN5mBX5huMYHxRx-v5XmFi70aDoM	2026-01-01 17:01:33.256+05:30	2025-12-25 17:01:33.258072+05:30
ad8aeb84-a74b-4a23-be60-ca0c94823ebc	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjY2NjIzMDEsImV4cCI6MTc2NzI2NzEwMX0.myaKsar8TkeocJoieir5LzAx3_Sh24wR_wZ4kmPvpSI	2026-01-01 17:01:41.284+05:30	2025-12-25 17:01:41.285146+05:30
d086b6a8-f6b0-4b0e-932d-9f7a8028721a	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjY2NjMyODcsImV4cCI6MTc2NzI2ODA4N30.xlltTigWNm9Sh-SWAbi5E0jdlaqWR7Fz545cUEFHXjM	2026-01-01 17:18:07.538+05:30	2025-12-25 17:18:07.539064+05:30
82240ee2-4f4e-40a8-ab1d-e10deda75561	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjY2NjcyNTAsImV4cCI6MTc2NzI3MjA1MH0.2hkjicUmlPJUk77mPNkC71B95DA_o3hY5XDb6nlgwl8	2026-01-01 18:24:10.582+05:30	2025-12-25 18:24:10.583609+05:30
6c5994d7-230a-4427-8152-39e5ad7f74af	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjY2Njg3ODIsImV4cCI6MTc2NzI3MzU4Mn0.gGst8f4iuIPkDaIPhi68A5omXDnIlvHXWBujhVnpOSk	2026-01-01 18:49:42.538+05:30	2025-12-25 18:49:42.539739+05:30
ec5694a1-9a81-480a-b01c-7df2d897a51e	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjcxNTcwNzQsImV4cCI6MTc2Nzc2MTg3NH0.Unjsxf3mmmWIXKI7DEyGTP4rIa_IJwp1OyD1pafx_dg	2026-01-07 10:27:54.351+05:30	2025-12-31 10:27:54.351921+05:30
5b6fa332-1863-403f-b747-687c70877a5f	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjczNDQ1MTUsImV4cCI6MTc2Nzk0OTMxNX0.hQTtWJAAK3_5n9GdVlgI_k-avR0-tK9e2wHrY0bJqtw	2026-01-09 14:31:55.854+05:30	2026-01-02 14:31:55.855463+05:30
d8c76b6e-6e91-4815-aef2-68399f51c869	43f2c95b-4fe8-4481-aa42-77125cef5d1f	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0M2YyYzk1Yi00ZmU4LTQ0ODEtYWE0Mi03NzEyNWNlZjVkMWYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidDFAdGNjLmNvbSIsImlhdCI6MTc2NzM0NDcxOSwiZXhwIjoxNzY3OTQ5NTE5fQ.BUQ9EKCUnb39rYWZSbGZTfuFkFhVeabwBMJJgAvlOgU	2026-01-09 14:35:19.805+05:30	2026-01-02 14:35:19.806095+05:30
322abc71-806f-4ea0-8358-23b50110f51d	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjczNDQ3NDksImV4cCI6MTc2Nzk0OTU0OX0.gYWsJHOsdKCfxqVildTHrczBzQWxvof0JDLbj8pNOv0	2026-01-09 14:35:49.068+05:30	2026-01-02 14:35:49.068923+05:30
b7e7e8ac-9829-43b6-b9fe-1a097b093bc9	39d53302-9bf3-4e79-95ac-883cae482d9e	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzOWQ1MzMwMi05YmYzLTRlNzktOTVhYy04ODNjYWU0ODJkOWUiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoic2hhc2hhbmtAZ21haWwuY29tIiwiaWF0IjoxNzY3MzQ0ODc4LCJleHAiOjE3Njc5NDk2Nzh9.1R5oLyWHgGAPDmSRgoznhTaCtoJC5rOTa11hCmw6K6I	2026-01-09 14:37:58.758+05:30	2026-01-02 14:37:58.75877+05:30
f4394f81-4b8e-4a5f-af97-eb19af76ab08	af223b34-da3f-44a6-bcd6-938034b46d50	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZjIyM2IzNC1kYTNmLTQ0YTYtYmNkNi05MzgwMzRiNDZkNTAiLCJyb2xlIjoiU1VQRVJfQURNSU4iLCJlbWFpbCI6ImFkbWluQHRjYy5zbCIsImlhdCI6MTc2NzM0NTAwNCwiZXhwIjoxNzY3OTQ5ODA0fQ.6q1eVVOkS3iids6RyxQ4pvpWrXDLETHKHGgHa7AlPEI	2026-01-09 14:40:04.801+05:30	2026-01-02 14:40:04.801356+05:30
126ccc25-d3f1-4146-a74b-1323aae483fb	39d53302-9bf3-4e79-95ac-883cae482d9e	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzOWQ1MzMwMi05YmYzLTRlNzktOTVhYy04ODNjYWU0ODJkOWUiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoic2hhc2hhbmtAZ21haWwuY29tIiwiaWF0IjoxNzY3MzQ4NjcwLCJleHAiOjE3Njc5NTM0NzB9.GURsHDT7v30t2GTdGqCmBrroibzQ2BFk4ivCM85VbPQ	2026-01-09 15:41:10.038+05:30	2026-01-02 15:41:10.038635+05:30
44a5251e-f459-475e-a59e-9f98ada15e7a	72fe9f39-5599-4339-bd5b-5adc6ca37996	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3MmZlOWYzOS01NTk5LTQzMzktYmQ1Yi01YWRjNmNhMzc5OTYiLCJyb2xlIjoiVVNFUiIsImVtYWlsIjoidGMzQHRjYy5jb20iLCJpYXQiOjE3NjczNTE4OTgsImV4cCI6MTc2Nzk1NjY5OH0.V3__eGf12g9zckeRj_pREfAU3P2u90n_CynSyJ7Ddmg	2026-01-09 16:34:58.581+05:30	2026-01-02 16:34:58.58261+05:30
\.


--
-- Data for Name: scheduled_transactions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.scheduled_transactions (id, user_id, type, recipient_id, bill_provider_id, amount, frequency, frequency_interval, next_execution_date, last_execution_date, total_executions, max_executions, is_active, metadata, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: security_events; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.security_events (id, user_id, event_type, severity, description, ip_address, device_info, location, metadata, resolved, resolved_by, resolved_at, resolution_notes, created_at) FROM stdin;
\.


--
-- Data for Name: support_tickets; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.support_tickets (id, ticket_id, user_id, email, subject, message, attachments, status, priority, assigned_to, resolved_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: system_config; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.system_config (key, value, category, data_type, description, updated_by, updated_at) FROM stdin;
MIN_DEPOSIT_AMOUNT	1000	TRANSACTION_LIMITS	NUMBER	Minimum deposit amount in SLL	\N	2025-12-18 18:12:24.774388+05:30
MAX_DEPOSIT_AMOUNT	10000000	TRANSACTION_LIMITS	NUMBER	Maximum deposit amount in SLL	\N	2025-12-18 18:12:24.774388+05:30
MIN_WITHDRAWAL_AMOUNT	1000	TRANSACTION_LIMITS	NUMBER	Minimum withdrawal amount in SLL	\N	2025-12-18 18:12:24.774388+05:30
MAX_WITHDRAWAL_AMOUNT	5000000	TRANSACTION_LIMITS	NUMBER	Maximum withdrawal amount in SLL	\N	2025-12-18 18:12:24.774388+05:30
MIN_TRANSFER_AMOUNT	100	TRANSACTION_LIMITS	NUMBER	Minimum transfer amount in SLL	\N	2025-12-18 18:12:24.774388+05:30
MAX_TRANSFER_AMOUNT	2000000	TRANSACTION_LIMITS	NUMBER	Maximum transfer amount in SLL	\N	2025-12-18 18:12:24.774388+05:30
DAILY_DEPOSIT_LIMIT	50000000	TRANSACTION_LIMITS	NUMBER	Daily deposit limit in SLL	\N	2025-12-18 18:12:24.774388+05:30
DAILY_WITHDRAWAL_LIMIT	20000000	TRANSACTION_LIMITS	NUMBER	Daily withdrawal limit in SLL	\N	2025-12-18 18:12:24.774388+05:30
DAILY_TRANSFER_LIMIT	5000000	TRANSACTION_LIMITS	NUMBER	Daily transfer limit in SLL	\N	2025-12-18 18:12:24.774388+05:30
DEPOSIT_FEE_PERCENT	0	FEES	NUMBER	Deposit fee percentage	\N	2025-12-18 18:12:24.774388+05:30
WITHDRAWAL_FEE_PERCENT	2	FEES	NUMBER	Withdrawal fee percentage	\N	2025-12-18 18:12:24.774388+05:30
TRANSFER_FEE_PERCENT	1	FEES	NUMBER	Transfer fee percentage	\N	2025-12-18 18:12:24.774388+05:30
OTP_EXPIRY_MINUTES	5	SECURITY	NUMBER	OTP expiration time in minutes	\N	2025-12-18 18:12:24.774388+05:30
OTP_LENGTH	6	SECURITY	NUMBER	OTP code length	\N	2025-12-18 18:12:24.774388+05:30
MAX_OTP_ATTEMPTS	3	SECURITY	NUMBER	Maximum OTP attempts before blocking	\N	2025-12-18 18:12:24.774388+05:30
SESSION_TIMEOUT_MINUTES	30	SECURITY	NUMBER	Session timeout in minutes	\N	2025-12-18 18:12:24.774388+05:30
MAX_LOGIN_ATTEMPTS	5	SECURITY	NUMBER	Maximum failed login attempts before lockout	\N	2025-12-18 18:12:24.774388+05:30
ACCOUNT_LOCKOUT_MINUTES	30	SECURITY	NUMBER	Account lockout duration in minutes	\N	2025-12-18 18:12:24.774388+05:30
PASSWORD_MIN_LENGTH	8	SECURITY	NUMBER	Minimum password length	\N	2025-12-18 18:12:24.774388+05:30
ACCOUNT_DELETION_GRACE_DAYS	30	SECURITY	NUMBER	Days before account is permanently deleted	\N	2025-12-18 18:12:24.774388+05:30
\.


--
-- Data for Name: transaction_reversals; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.transaction_reversals (id, original_transaction_id, reversal_transaction_id, reason, reversal_type, reversal_amount, initiated_by, approved_by, status, created_at, completed_at) FROM stdin;
\.


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.transactions (id, transaction_id, type, from_user_id, to_user_id, amount, fee, net_amount, status, payment_method, deposit_source, reference, description, metadata, ip_address, user_agent, processed_at, failed_at, failure_reason, created_at, updated_at, stripe_payment_intent_id, payment_gateway_response) FROM stdin;
cbbaa30d-ec74-43b0-9d79-164009ede753	TXN20251220496194	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	5000.00	0.00	5000.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3SgB0OFU6W2alheK143Wh2Co"}	::ffff:127.0.0.1	\N	\N	\N	\N	2025-12-20 02:44:31.739968+05:30	2025-12-20 02:44:31.739968+05:30	pi_3SgB0OFU6W2alheK143Wh2Co	\N
15ba9b69-33f9-4d6b-9ace-d7c87851c444	TXN20251220796792	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	1000.00	0.00	1000.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3SgB6SFU6W2alheK2HvNI2BW"}	::ffff:127.0.0.1	\N	\N	\N	\N	2025-12-20 02:50:47.571881+05:30	2025-12-20 02:50:47.571881+05:30	pi_3SgB6SFU6W2alheK2HvNI2BW	\N
fbcdf221-f025-4dc8-b733-0a371631a4ae	TXN20251220828502	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	5000.00	0.00	5000.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3SgB9PFU6W2alheK0Bj4miDO"}	::ffff:127.0.0.1	\N	\N	\N	\N	2025-12-20 02:53:50.710051+05:30	2025-12-20 02:53:50.710051+05:30	pi_3SgB9PFU6W2alheK0Bj4miDO	\N
c9bc125f-b358-4d78-90d3-6e5119b723f3	TXN20251220212526	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	1000.00	0.00	1000.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3SgBAaFU6W2alheK2mAWYCQQ"}	::ffff:127.0.0.1	\N	\N	\N	\N	2025-12-20 02:55:03.707002+05:30	2025-12-20 02:55:03.707002+05:30	pi_3SgBAaFU6W2alheK2mAWYCQQ	\N
b9826215-a617-43ce-81fc-3feb89fe405a	TXN20251220841845	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	1000.00	0.00	1000.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3SgJTjFU6W2alheK04kq6Txc"}	::ffff:127.0.0.1	\N	\N	\N	\N	2025-12-20 11:47:23.005085+05:30	2025-12-20 11:47:23.005085+05:30	pi_3SgJTjFU6W2alheK04kq6Txc	\N
9c8a8cab-dc4c-47d9-8544-bf5b2e52317b	TXN20251220656959	DEPOSIT	\N	6b864809-fb5a-4a1f-a95e-edf87b7eeb5c	1000.00	0.00	1000.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3SgKNQFU6W2alheK1dEHXU8q"}	::ffff:127.0.0.1	\N	\N	\N	\N	2025-12-20 12:44:56.208476+05:30	2025-12-20 12:44:56.208476+05:30	pi_3SgKNQFU6W2alheK1dEHXU8q	\N
abdc8355-93ed-4f9d-874d-706679eb0a19	TXN20251220430438	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	1000.00	0.00	1000.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3SgOksFU6W2alheK1cWUh0HV"}	::ffff:127.0.0.1	\N	\N	\N	\N	2025-12-20 17:25:26.271234+05:30	2025-12-20 17:25:26.271234+05:30	pi_3SgOksFU6W2alheK1cWUh0HV	\N
9d785e38-2bba-4c79-9029-d864b34614cf	TXN20251220839001	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	1000.00	0.00	1000.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3SgPz3FU6W2alheK0J95Rbbt"}	::ffff:127.0.0.1	\N	\N	\N	\N	2025-12-20 18:44:09.049454+05:30	2025-12-20 18:44:09.049454+05:30	pi_3SgPz3FU6W2alheK0J95Rbbt	\N
20a842d9-7326-40f2-b891-5cc0421ac046	TXN20251220823739	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	1000.00	0.00	1000.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3SgQ79FU6W2alheK2whcSeu9"}	::ffff:127.0.0.1	\N	\N	\N	\N	2025-12-20 18:52:30.74457+05:30	2025-12-20 18:52:30.74457+05:30	pi_3SgQ79FU6W2alheK2whcSeu9	\N
24d14952-1bd5-4329-b56d-130adaf3feb2	TXN20251220441415	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	1000.00	0.00	1000.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3SgT48FU6W2alheK0J0MZCZ3"}	::ffff:127.0.0.1	\N	\N	\N	\N	2025-12-20 22:01:35.991015+05:30	2025-12-20 22:01:35.991015+05:30	pi_3SgT48FU6W2alheK0J0MZCZ3	\N
bb113d54-c898-4c34-ae2e-1c6ac4211c52	TXN20251220509304	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	1000.00	0.00	1000.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3SgTu9FU6W2alheK1F2QmI6i"}	::ffff:127.0.0.1	\N	\N	\N	\N	2025-12-20 22:55:21.05097+05:30	2025-12-20 22:55:21.05097+05:30	pi_3SgTu9FU6W2alheK1F2QmI6i	\N
079f4028-5fec-455e-a14a-b7291fb8e21b	TXN20251220112997	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	1000.00	0.00	1000.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3SgU42FU6W2alheK18wXO0CW"}	::ffff:127.0.0.1	\N	\N	\N	\N	2025-12-20 23:05:33.861477+05:30	2025-12-20 23:05:33.861477+05:30	pi_3SgU42FU6W2alheK18wXO0CW	\N
ba5b7d98-7059-4496-871f-d0e784155551	TXN20251220877328	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	5000.00	0.00	5000.00	COMPLETED	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3SgUCfFU6W2alheK0WSlW80h"}	::ffff:127.0.0.1	\N	2025-12-20 23:15:42.299032+05:30	\N	\N	2025-12-20 23:14:28.860063+05:30	2025-12-20 23:15:42.299032+05:30	pi_3SgUCfFU6W2alheK0WSlW80h	{"id": "pi_3SgUCfFU6W2alheK0WSlW80h", "amount": 500000, "object": "payment_intent", "review": null, "source": null, "status": "succeeded", "created": 1766252669, "currency": "usd", "customer": "cus_TdRqd1D0i7ZGBL", "livemode": false, "metadata": {"type": "wallet_deposit", "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "transaction_id": "TXN20251220877328"}, "shipping": null, "processing": null, "application": null, "canceled_at": null, "description": "Wallet deposit for transaction TXN20251220877328", "next_action": null, "on_behalf_of": null, "client_secret": "pi_3SgUCfFU6W2alheK0WSlW80h_secret_EVarS5bQhxZSLPQ5yrkjqDe4g", "latest_charge": "py_3SgUCfFU6W2alheK08Y7xH8c", "receipt_email": null, "transfer_data": null, "amount_details": {"tip": {}}, "capture_method": "automatic_async", "payment_method": "pm_1SgUDiFU6W2alheKTuz9FSZq", "transfer_group": null, "amount_received": 500000, "customer_account": null, "amount_capturable": 0, "last_payment_error": null, "setup_future_usage": null, "cancellation_reason": null, "confirmation_method": "automatic", "payment_method_types": ["card", "klarna", "link", "affirm", "cashapp", "amazon_pay"], "statement_descriptor": null, "application_fee_amount": null, "payment_method_options": {"card": {"network": null, "installments": null, "mandate_options": null, "request_three_d_secure": "automatic"}, "link": {"persistent_token": null}, "affirm": {}, "klarna": {"preferred_locale": null}, "cashapp": {}, "amazon_pay": {"express_checkout_element_session_id": null}}, "automatic_payment_methods": {"enabled": true, "allow_redirects": "always"}, "statement_descriptor_suffix": null, "excluded_payment_method_types": null, "payment_method_configuration_details": {"id": "pmc_1Sf11kFU6W2alheK0rGIa7ih", "parent": null}}
fa3977bf-3f0d-4e0c-b517-da29a18325fd	TXN20251220130622	DEPOSIT	\N	8c6b2a0e-9b12-49db-8a5f-8dcb58572d72	1000.00	0.00	1000.00	COMPLETED	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3SgUlbFU6W2alheK1WRzctwD"}	::ffff:127.0.0.1	\N	2025-12-20 23:50:49.878194+05:30	\N	\N	2025-12-20 23:50:34.741076+05:30	2025-12-20 23:50:49.878194+05:30	pi_3SgUlbFU6W2alheK1WRzctwD	{"id": "pi_3SgUlbFU6W2alheK1WRzctwD", "amount": 100000, "object": "payment_intent", "review": null, "source": null, "status": "succeeded", "created": 1766254835, "currency": "usd", "customer": "cus_TdmKrXUlEg83LB", "livemode": false, "metadata": {"type": "wallet_deposit", "user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "transaction_id": "TXN20251220130622"}, "shipping": null, "processing": null, "application": null, "canceled_at": null, "description": "Wallet deposit for transaction TXN20251220130622", "next_action": null, "on_behalf_of": null, "client_secret": "pi_3SgUlbFU6W2alheK1WRzctwD_secret_aMoYHI8h2zR3BguJmMI8sQQZw", "latest_charge": "py_3SgUlbFU6W2alheK108qxsby", "receipt_email": null, "transfer_data": null, "amount_details": {"tip": {}}, "capture_method": "automatic_async", "payment_method": "pm_1SgUlgFU6W2alheK4TwnJRQb", "transfer_group": null, "amount_received": 100000, "customer_account": null, "amount_capturable": 0, "last_payment_error": null, "setup_future_usage": null, "cancellation_reason": null, "confirmation_method": "automatic", "payment_method_types": ["card", "klarna", "link", "affirm", "cashapp", "amazon_pay"], "statement_descriptor": null, "application_fee_amount": null, "payment_method_options": {"card": {"network": null, "installments": null, "mandate_options": null, "request_three_d_secure": "automatic"}, "link": {"persistent_token": null}, "affirm": {}, "klarna": {"preferred_locale": null}, "cashapp": {}, "amazon_pay": {"express_checkout_element_session_id": null}}, "automatic_payment_methods": {"enabled": true, "allow_redirects": "always"}, "statement_descriptor_suffix": null, "excluded_payment_method_types": null, "payment_method_configuration_details": {"id": "pmc_1Sf11kFU6W2alheK0rGIa7ih", "parent": null}}
a198366f-18b4-4d9f-93ef-2374e2b77057	TXN20251220472333	DEPOSIT	\N	8c6b2a0e-9b12-49db-8a5f-8dcb58572d72	5000.00	0.00	5000.00	COMPLETED	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3SgUmMFU6W2alheK09XeD4Ux"}	::ffff:127.0.0.1	\N	2025-12-20 23:51:36.777437+05:30	\N	\N	2025-12-20 23:51:22.441124+05:30	2025-12-20 23:51:36.777437+05:30	pi_3SgUmMFU6W2alheK09XeD4Ux	{"id": "pi_3SgUmMFU6W2alheK09XeD4Ux", "amount": 500000, "object": "payment_intent", "review": null, "source": null, "status": "succeeded", "created": 1766254882, "currency": "usd", "customer": "cus_TdmKrXUlEg83LB", "livemode": false, "metadata": {"type": "wallet_deposit", "user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "transaction_id": "TXN20251220472333"}, "shipping": null, "processing": null, "application": null, "canceled_at": null, "description": "Wallet deposit for transaction TXN20251220472333", "next_action": null, "on_behalf_of": null, "client_secret": "pi_3SgUmMFU6W2alheK09XeD4Ux_secret_K8TMXUnK9gg084hyFrZ0Xt1w5", "latest_charge": "py_3SgUmMFU6W2alheK0RrskA4N", "receipt_email": null, "transfer_data": null, "amount_details": {"tip": {}}, "capture_method": "automatic_async", "payment_method": "pm_1SgUmQFU6W2alheKFXoG8kLu", "transfer_group": null, "amount_received": 500000, "customer_account": null, "amount_capturable": 0, "last_payment_error": null, "setup_future_usage": null, "cancellation_reason": null, "confirmation_method": "automatic", "payment_method_types": ["card", "klarna", "link", "affirm", "cashapp", "amazon_pay"], "statement_descriptor": null, "application_fee_amount": null, "payment_method_options": {"card": {"network": null, "installments": null, "mandate_options": null, "request_three_d_secure": "automatic"}, "link": {"persistent_token": null}, "affirm": {}, "klarna": {"preferred_locale": null}, "cashapp": {}, "amazon_pay": {"express_checkout_element_session_id": null}}, "automatic_payment_methods": {"enabled": true, "allow_redirects": "always"}, "statement_descriptor_suffix": null, "excluded_payment_method_types": null, "payment_method_configuration_details": {"id": "pmc_1Sf11kFU6W2alheK0rGIa7ih", "parent": null}}
a1f8bfd4-560d-4abc-9557-588d367bbc14	TXN20251220564247	DEPOSIT	\N	8c6b2a0e-9b12-49db-8a5f-8dcb58572d72	1000.00	0.00	1000.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3SgUuIFU6W2alheK2uDdXYmG"}	::ffff:127.0.0.1	\N	\N	\N	\N	2025-12-20 23:59:33.488611+05:30	2025-12-20 23:59:33.488611+05:30	pi_3SgUuIFU6W2alheK2uDdXYmG	\N
f71ab014-e81c-450f-85fc-1ab88f23885a	TXN20251221944581	DEPOSIT	\N	8c6b2a0e-9b12-49db-8a5f-8dcb58572d72	10000.00	0.00	10000.00	COMPLETED	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3SgUusFU6W2alheK1c1HWTpY"}	::ffff:127.0.0.1	\N	2025-12-21 00:00:30.483263+05:30	\N	\N	2025-12-21 00:00:09.714776+05:30	2025-12-21 00:00:30.483263+05:30	pi_3SgUusFU6W2alheK1c1HWTpY	{"id": "pi_3SgUusFU6W2alheK1c1HWTpY", "amount": 1000000, "object": "payment_intent", "review": null, "source": null, "status": "succeeded", "created": 1766255410, "currency": "usd", "customer": "cus_TdmKrXUlEg83LB", "livemode": false, "metadata": {"type": "wallet_deposit", "user_id": "8c6b2a0e-9b12-49db-8a5f-8dcb58572d72", "transaction_id": "TXN20251221944581"}, "shipping": null, "processing": null, "application": null, "canceled_at": null, "description": "Wallet deposit for transaction TXN20251221944581", "next_action": null, "on_behalf_of": null, "client_secret": "pi_3SgUusFU6W2alheK1c1HWTpY_secret_4rLgfQQEqWo8SRnZah2pS0Ieb", "latest_charge": "ch_3SgUusFU6W2alheK13eTocZ4", "receipt_email": null, "transfer_data": null, "amount_details": {"tip": {}}, "capture_method": "automatic_async", "payment_method": "pm_1SgUvBFU6W2alheK7haNgtcG", "transfer_group": null, "amount_received": 1000000, "customer_account": null, "amount_capturable": 0, "last_payment_error": null, "setup_future_usage": null, "cancellation_reason": null, "confirmation_method": "automatic", "payment_method_types": ["card", "klarna", "link", "affirm", "cashapp", "amazon_pay"], "statement_descriptor": null, "application_fee_amount": null, "payment_method_options": {"card": {"network": null, "installments": null, "mandate_options": null, "request_three_d_secure": "automatic"}, "link": {"persistent_token": null}, "affirm": {}, "klarna": {"preferred_locale": null}, "cashapp": {}, "amazon_pay": {"express_checkout_element_session_id": null}}, "automatic_payment_methods": {"enabled": true, "allow_redirects": "always"}, "statement_descriptor_suffix": null, "excluded_payment_method_types": null, "payment_method_configuration_details": {"id": "pmc_1Sf11kFU6W2alheK0rGIa7ih", "parent": null}}
1329af43-b7ad-4378-aa63-5d998e769e86	TXN20251222653976	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	1005.00	0.00	1005.00	COMPLETED	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3Sh9J1FU6W2alheK25RXuvGq"}	::ffff:127.0.0.1	\N	2025-12-22 19:56:23.675968+05:30	\N	\N	2025-12-22 19:07:46.976626+05:30	2025-12-22 19:56:23.675968+05:30	pi_3Sh9J1FU6W2alheK25RXuvGq	\N
b132fd84-b31a-4244-a67c-43403b57e903	TXN20251223143972	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	1000.00	0.00	1000.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3ShVcmFU6W2alheK07Aadv57"}	::ffff:127.0.0.1	\N	\N	\N	\N	2025-12-23 18:57:39.620208+05:30	2025-12-23 18:57:39.620208+05:30	pi_3ShVcmFU6W2alheK07Aadv57	\N
71566c7f-a0f0-406c-93f8-db584fea8c7f	TXN20251223340124	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	5001.00	0.00	5001.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3ShVgEFU6W2alheK08xfwhnf"}	::ffff:127.0.0.1	\N	\N	\N	\N	2025-12-23 19:01:13.886484+05:30	2025-12-23 19:01:13.886484+05:30	pi_3ShVgEFU6W2alheK08xfwhnf	\N
e574bca5-a052-45ad-9e01-fccc59c27dbb	TXN20251223134887	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	1000.00	0.00	1000.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3ShWHmFU6W2alheK1k1dOLlo"}	::ffff:127.0.0.1	\N	\N	\N	\N	2025-12-23 19:40:02.362874+05:30	2025-12-23 19:40:02.362874+05:30	pi_3ShWHmFU6W2alheK1k1dOLlo	\N
2e853ba0-3dcf-45fa-819c-bc0a07051669	TXN20251223216667	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	5000.00	0.00	5000.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3ShWIXFU6W2alheK2CFFMr13"}	::ffff:127.0.0.1	\N	\N	\N	\N	2025-12-23 19:40:49.21499+05:30	2025-12-23 19:40:49.21499+05:30	pi_3ShWIXFU6W2alheK2CFFMr13	\N
9ada3b78-a84b-4e94-bbcf-07b7f9d75170	TXN20251224337607	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	1000.00	0.00	1000.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3ShraoFU6W2alheK0yQCopIf"}	::ffff:127.0.0.1	\N	\N	\N	\N	2025-12-24 18:25:05.207333+05:30	2025-12-24 18:25:05.207333+05:30	pi_3ShraoFU6W2alheK0yQCopIf	\N
21a12194-2468-424e-a71a-adcce0e7aab5	TXN20251224740071	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	10001.00	0.00	10001.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3ShsT2FU6W2alheK0HOwHxvw"}	::ffff:127.0.0.1	\N	\N	\N	\N	2025-12-24 19:21:07.310078+05:30	2025-12-24 19:21:07.310078+05:30	pi_3ShsT2FU6W2alheK0HOwHxvw	\N
8ac9fd4c-dceb-4add-8207-b53d93b002b2	TXN20251224188900	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	5000.00	0.00	5000.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3ShsnJFU6W2alheK0013lCgQ"}	::ffff:127.0.0.1	\N	\N	\N	\N	2025-12-24 19:42:05.336912+05:30	2025-12-24 19:42:05.336912+05:30	pi_3ShsnJFU6W2alheK0013lCgQ	\N
d76ba9dd-064d-40a7-9d33-2337a60d45d1	TXN20251224620465	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	1000.00	0.00	1000.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3ShtMvFU6W2alheK0WiPFhMD"}	::ffff:127.0.0.1	\N	\N	\N	\N	2025-12-24 20:18:53.071007+05:30	2025-12-24 20:18:53.071007+05:30	pi_3ShtMvFU6W2alheK0WiPFhMD	\N
1bce64d0-0d7e-4095-b12a-0fc20d852dbb	TXN20251225686836	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	10000.00	0.00	10000.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3Si5VnFU6W2alheK1QT2tOjc"}	::ffff:127.0.0.1	\N	\N	\N	\N	2025-12-25 09:16:50.557105+05:30	2025-12-25 09:16:50.557105+05:30	pi_3Si5VnFU6W2alheK1QT2tOjc	\N
b9b95ca7-e3c8-47c9-81b4-dfc788fe77eb	TXN20251225126534	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	1000.00	0.00	1000.00	COMPLETED	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3SiCEkFU6W2alheK1rrE6vZv"}	::ffff:127.0.0.1	\N	2025-12-25 16:28:04.803707+05:30	\N	\N	2025-12-25 16:27:42.196728+05:30	2025-12-25 16:28:04.803707+05:30	pi_3SiCEkFU6W2alheK1rrE6vZv	{"id": "pi_3SiCEkFU6W2alheK1rrE6vZv", "amount": 100000, "object": "payment_intent", "review": null, "source": null, "status": "succeeded", "created": 1766660262, "currency": "usd", "customer": "cus_TdRqd1D0i7ZGBL", "livemode": false, "metadata": {"type": "wallet_deposit", "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "transaction_id": "TXN20251225126534"}, "shipping": null, "processing": null, "application": null, "canceled_at": null, "description": "Wallet deposit for transaction TXN20251225126534", "next_action": null, "on_behalf_of": null, "client_secret": "pi_3SiCEkFU6W2alheK1rrE6vZv_secret_YbkjfXEXE6lZJSgkpZLlGHqcL", "latest_charge": "ch_3SiCEkFU6W2alheK1qkGEQwz", "receipt_email": null, "transfer_data": null, "amount_details": {"tip": {}}, "capture_method": "automatic_async", "payment_method": "pm_1SiCF2FU6W2alheK3N7vyu3U", "transfer_group": null, "amount_received": 100000, "customer_account": null, "amount_capturable": 0, "last_payment_error": null, "setup_future_usage": null, "cancellation_reason": null, "confirmation_method": "automatic", "payment_method_types": ["card", "klarna", "link", "affirm", "cashapp", "amazon_pay"], "statement_descriptor": null, "application_fee_amount": null, "payment_method_options": {"card": {"network": null, "installments": null, "mandate_options": null, "request_three_d_secure": "automatic"}, "link": {"persistent_token": null}, "affirm": {}, "klarna": {"preferred_locale": null}, "cashapp": {}, "amazon_pay": {"express_checkout_element_session_id": null}}, "automatic_payment_methods": {"enabled": true, "allow_redirects": "always"}, "statement_descriptor_suffix": null, "excluded_payment_method_types": null, "payment_method_configuration_details": {"id": "pmc_1Sf11kFU6W2alheK0rGIa7ih", "parent": null}}
21e417f2-3db9-4508-b3af-4afea833a168	TXN20251225154026	DEPOSIT	\N	72fe9f39-5599-4339-bd5b-5adc6ca37996	1000.00	0.00	1000.00	COMPLETED	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3SiCo9FU6W2alheK2M10mmGM"}	::ffff:127.0.0.1	\N	2025-12-25 17:04:36.951452+05:30	\N	\N	2025-12-25 17:04:17.405645+05:30	2025-12-25 17:04:36.951452+05:30	pi_3SiCo9FU6W2alheK2M10mmGM	{"id": "pi_3SiCo9FU6W2alheK2M10mmGM", "amount": 100000, "object": "payment_intent", "review": null, "source": null, "status": "succeeded", "created": 1766662457, "currency": "usd", "customer": "cus_TdRqd1D0i7ZGBL", "livemode": false, "metadata": {"type": "wallet_deposit", "user_id": "72fe9f39-5599-4339-bd5b-5adc6ca37996", "transaction_id": "TXN20251225154026"}, "shipping": null, "processing": null, "application": null, "canceled_at": null, "description": "Wallet deposit for transaction TXN20251225154026", "next_action": null, "on_behalf_of": null, "client_secret": "pi_3SiCo9FU6W2alheK2M10mmGM_secret_F2sxYo5DdAIzLNHfbVKmuL8Or", "latest_charge": "ch_3SiCo9FU6W2alheK2ChliQ1g", "receipt_email": null, "transfer_data": null, "amount_details": {"tip": {}}, "capture_method": "automatic_async", "payment_method": "pm_1SiCoPFU6W2alheKNAsGOZbO", "transfer_group": null, "amount_received": 100000, "customer_account": null, "amount_capturable": 0, "last_payment_error": null, "setup_future_usage": null, "cancellation_reason": null, "confirmation_method": "automatic", "payment_method_types": ["card", "klarna", "link", "affirm", "cashapp", "amazon_pay"], "statement_descriptor": null, "application_fee_amount": null, "payment_method_options": {"card": {"network": null, "installments": null, "mandate_options": null, "request_three_d_secure": "automatic"}, "link": {"persistent_token": null}, "affirm": {}, "klarna": {"preferred_locale": null}, "cashapp": {}, "amazon_pay": {"express_checkout_element_session_id": null}}, "automatic_payment_methods": {"enabled": true, "allow_redirects": "always"}, "statement_descriptor_suffix": null, "excluded_payment_method_types": null, "payment_method_configuration_details": {"id": "pmc_1Sf11kFU6W2alheK0rGIa7ih", "parent": null}}
dc2605d4-ed8e-49a4-9705-067d6b3b3bd2	TXN20260102310787	DEPOSIT	\N	39d53302-9bf3-4e79-95ac-883cae482d9e	10000.00	0.00	10000.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3Sl4NlFU6W2alheK2sw5JEoS"}	::ffff:127.0.0.1	\N	\N	\N	\N	2026-01-02 14:40:53.154345+05:30	2026-01-02 14:40:53.154345+05:30	pi_3Sl4NlFU6W2alheK2sw5JEoS	\N
1623e0a5-0dc7-4e9f-9ea0-014d05aa0404	TXN20260102209426	DEPOSIT	\N	39d53302-9bf3-4e79-95ac-883cae482d9e	2500.00	0.00	2500.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3Sl4oCFU6W2alheK2ZDcWvMT"}	::ffff:127.0.0.1	\N	\N	\N	\N	2026-01-02 15:08:12.208707+05:30	2026-01-02 15:08:12.208707+05:30	pi_3Sl4oCFU6W2alheK2ZDcWvMT	\N
fa174540-3a1a-453d-b158-7de9da4c1bca	TXN20260102693155	DEPOSIT	\N	39d53302-9bf3-4e79-95ac-883cae482d9e	2500.00	0.00	2500.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3Sl4vzFU6W2alheK1jbkBvLZ"}	::ffff:127.0.0.1	\N	\N	\N	\N	2026-01-02 15:16:14.751454+05:30	2026-01-02 15:16:14.751454+05:30	pi_3Sl4vzFU6W2alheK1jbkBvLZ	\N
8e66b5a5-b9e9-483a-ab7a-c1153cd4c7ba	TXN20260102919056	DEPOSIT	\N	39d53302-9bf3-4e79-95ac-883cae482d9e	2500.00	0.00	2500.00	PENDING	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3Sl50OFU6W2alheK25C3Lyo7"}	::ffff:127.0.0.1	\N	\N	\N	\N	2026-01-02 15:20:47.903172+05:30	2026-01-02 15:20:47.903172+05:30	pi_3Sl50OFU6W2alheK25C3Lyo7	\N
6cee6642-032a-40a2-8baa-e2c511aead1e	TXN20260102870229	DEPOSIT	\N	39d53302-9bf3-4e79-95ac-883cae482d9e	2500.00	0.00	2500.00	COMPLETED	MOBILE_MONEY	INTERNET_BANKING	\N	\N	{"paymentGateway": "stripe", "paymentIntentId": "pi_3Sl5KBFU6W2alheK1FfRpXVC"}	::ffff:127.0.0.1	\N	2026-01-02 15:41:38.276234+05:30	\N	\N	2026-01-02 15:41:14.855283+05:30	2026-01-02 15:41:38.276234+05:30	pi_3Sl5KBFU6W2alheK1FfRpXVC	{"id": "pi_3Sl5KBFU6W2alheK1FfRpXVC", "amount": 2500, "object": "payment_intent", "review": null, "source": null, "status": "succeeded", "created": 1767348675, "currency": "usd", "customer": "cus_TiVOLMNMbI1dyi", "livemode": false, "metadata": {"type": "wallet_deposit", "user_id": "39d53302-9bf3-4e79-95ac-883cae482d9e", "transaction_id": "TXN20260102870229"}, "shipping": null, "processing": null, "application": null, "canceled_at": null, "description": "Wallet deposit for transaction TXN20260102870229", "next_action": null, "on_behalf_of": null, "client_secret": "pi_3Sl5KBFU6W2alheK1FfRpXVC_secret_9Oc6y5Hzszpon0KWCjvz6aOVx", "latest_charge": "ch_3Sl5KBFU6W2alheK1tYLDc5n", "receipt_email": null, "transfer_data": null, "amount_details": {"tip": {}}, "capture_method": "automatic_async", "payment_method": "pm_1Sl5KTFU6W2alheKZOH0CehG", "transfer_group": null, "amount_received": 2500, "customer_account": null, "amount_capturable": 0, "last_payment_error": null, "setup_future_usage": null, "cancellation_reason": null, "confirmation_method": "automatic", "payment_method_types": ["card", "klarna", "link", "cashapp", "amazon_pay"], "statement_descriptor": null, "application_fee_amount": null, "payment_method_options": {"card": {"network": null, "installments": null, "mandate_options": null, "request_three_d_secure": "automatic"}, "link": {"persistent_token": null}, "klarna": {"preferred_locale": null}, "cashapp": {}, "amazon_pay": {"express_checkout_element_session_id": null}}, "automatic_payment_methods": {"enabled": true, "allow_redirects": "always"}, "statement_descriptor_suffix": null, "excluded_payment_method_types": null, "payment_method_configuration_details": {"id": "pmc_1Sf11kFU6W2alheK0rGIa7ih", "parent": null}}
6bbaeb8c-77b6-4a63-a13d-0258421180b6	TXN20260102442344	TRANSFER	39d53302-9bf3-4e79-95ac-883cae482d9e	72fe9f39-5599-4339-bd5b-5adc6ca37996	152.00	10.00	152.00	COMPLETED	\N	\N	\N	HELLO	\N	\N	\N	2026-01-02 16:34:30.480453+05:30	\N	\N	2026-01-02 16:34:30.480453+05:30	2026-01-02 16:34:30.480453+05:30	\N	\N
\.


--
-- Data for Name: user_devices; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_devices (id, user_id, device_id, device_type, device_name, device_model, os_version, app_version, fingerprint, is_trusted, is_blocked, trust_score, last_used_at, last_location, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: user_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_sessions (id, user_id, token_hash, refresh_token_hash, device_info, ip_address, location, is_active, last_activity_at, expires_at, created_at) FROM stdin;
\.


--
-- Data for Name: user_transaction_limits; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_transaction_limits (id, user_id, limit_type, limit_value, current_value, reset_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, role, first_name, last_name, email, phone, country_code, password_hash, profile_picture_url, kyc_status, is_active, is_verified, email_verified, phone_verified, last_login_at, password_changed_at, failed_login_attempts, locked_until, two_factor_enabled, two_factor_secret, deletion_requested_at, deletion_scheduled_for, referral_code, referred_by, created_at, updated_at, stripe_customer_id) FROM stdin;
892f1e8c-993a-4016-8099-398d8dcd66a1	SUPER_ADMIN	Super	Admin	admin@tccapp.com	232XXXXXXXX	+232	$2b$10$placeholder_hash	\N	APPROVED	t	t	t	t	\N	\N	0	\N	f	\N	\N	\N	\N	\N	2025-12-18 18:12:24.833677+05:30	2025-12-18 18:12:24.833677+05:30	\N
8c6b2a0e-9b12-49db-8a5f-8dcb58572d72	USER	Shashank	Test	sh@tcc.com	9876543216	+232	$2b$10$rnMGhNFz4hBQDqUmcbiBlO47qzrgETF11pJ2niLJPoRW7EwJeMhEi	\N	APPROVED	t	t	f	t	2025-12-20 23:40:28.359477+05:30	\N	0	\N	f	\N	\N	\N	4QHXP44K	\N	2025-12-20 23:40:21.217414+05:30	2025-12-20 23:50:34.733616+05:30	cus_TdmKrXUlEg83LB
39d53302-9bf3-4e79-95ac-883cae482d9e	USER	Shashank	Singh	shashank@gmail.com	9876543225	+232	$2b$10$4KK05kTfU0iUsQXCJ5lFHuhYJMIjckrRD7fXrYyL8kn56i80OUktW	\N	APPROVED	t	t	f	t	2026-01-02 15:41:10.018938+05:30	\N	0	\N	f	\N	\N	\N	FG609015	\N	2026-01-02 14:37:35.588186+05:30	2026-01-02 15:41:10.018938+05:30	cus_TiVOLMNMbI1dyi
42fa68c5-e80b-4100-9aad-c28300e33fff	USER	t2	t2	t2@tcc.com	9876543214	+232	$2b$10$dq6FRxzeaZzi5G81Ez.njev3Y1cUbOsxWxX0ogavTajUseGLNv6eu	\N	PENDING	t	t	f	t	2025-12-19 22:35:04.620394+05:30	\N	0	\N	f	\N	\N	\N	50X6G2MH	\N	2025-12-19 22:33:43.697063+05:30	2025-12-19 22:35:04.620394+05:30	\N
6b864809-fb5a-4a1f-a95e-edf87b7eeb5c	USER	Sachin	Sachin	sc@tcc.com	9874654326	+232	$2b$10$WtQeSHT5Kj4FLVfnPgVbH.OP2f04HBM2Vt7rjC8sD5JyAbGG7VQzi	\N	APPROVED	t	t	f	t	2025-12-20 12:41:33.569188+05:30	\N	0	\N	f	\N	\N	\N	7QAKQMZS	\N	2025-12-20 12:41:17.907469+05:30	2025-12-20 17:02:40.2427+05:30	cus_TdbaXPCzdHoRVV
1880ea25-a5bf-4c10-8b2e-e7ff1728445b	USER	Test	Test	tc@tcc.com	9876543210	+232	$2b$10$//GgSRxf4e3DGWO4ZQjJyOBv6.Uc3ftQQIFJsiz3gJHJAw7NugDai	\N	PENDING	t	t	f	t	2025-12-25 14:18:31.294748+05:30	\N	0	\N	f	\N	\N	\N	MI87JQJC	\N	2025-12-19 15:22:22.250196+05:30	2025-12-25 14:18:31.294748+05:30	\N
72fe9f39-5599-4339-bd5b-5adc6ca37996	USER	test	test	tc3@tcc.com	9876543215	+232	$2b$10$enhuA4897sX9hIMFXy7eYe/o9Uu8WuVugQveV0NJXfdu1crFiuDTW	http://localhost:3000/v1/uploads/profiles/72fe9f39-5599-4339-bd5b-5adc6ca37996/1766660213370-eea71e983f4f0767.jpg	APPROVED	t	t	f	t	2026-01-02 16:34:58.573825+05:30	\N	0	\N	f	\N	\N	\N	0D6EF9KO	\N	2025-12-19 23:27:35.393285+05:30	2026-01-02 16:34:58.573825+05:30	cus_TdRqd1D0i7ZGBL
15a46f44-4094-4b25-a4d3-51a3f682a4b9	USER	test2	test2	tc2@tcc.com	9876543211	+232	$2b$10$Pe4PprcWOP/YkyAr7FnJy.UflEesu9ARZm2HwuLY6g2oYZMtohryO	\N	PENDING	t	t	f	t	2025-12-19 22:26:50.374461+05:30	\N	0	\N	f	\N	\N	\N	5I7QKT57	\N	2025-12-19 22:26:41.502956+05:30	2025-12-20 00:50:47.481826+05:30	\N
43f2c95b-4fe8-4481-aa42-77125cef5d1f	USER	test	test	t1@tcc.com	9876543213	+232	$2b$10$JP0AgEzScstcK7MryFb2P.qUZ3YMR.gGj/5KPEpT7FZK9NYtLJscm	\N	PENDING	t	t	f	t	2026-01-02 14:35:19.791961+05:30	\N	0	\N	f	\N	\N	\N	6O0JJY1X	\N	2025-12-19 22:31:27.903088+05:30	2026-01-02 14:35:19.791961+05:30	\N
af223b34-da3f-44a6-bcd6-938034b46d50	SUPER_ADMIN	Admin	User	admin@tcc.sl	+23276000001	+232	$2b$12$xTYkPfFW8/ZpN32n1YM2He1As7GnX0p6.hMP2oPFXdppFyuvPk9j2	\N	APPROVED	t	t	t	t	2026-01-02 14:40:04.795536+05:30	\N	0	\N	f	\N	\N	\N	\N	\N	2025-12-18 18:26:56.881408+05:30	2026-01-02 14:40:04.795536+05:30	\N
\.


--
-- Data for Name: votes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.votes (id, poll_id, user_id, selected_option, amount_paid, transaction_id, voted_at) FROM stdin;
\.


--
-- Data for Name: wallet_audit_trail; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.wallet_audit_trail (id, user_id, admin_id, action_type, amount, balance_before, balance_after, reason, notes, transaction_id, ip_address, created_at) FROM stdin;
\.


--
-- Data for Name: wallets; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.wallets (id, user_id, balance, currency, last_transaction_at, created_at, updated_at) FROM stdin;
eb199c7a-77ab-4a14-863f-63592424652c	1880ea25-a5bf-4c10-8b2e-e7ff1728445b	0.00	SLL	\N	2025-12-19 15:22:22.265731+05:30	2025-12-19 15:22:22.265731+05:30
14b1fbaf-ca1f-4749-849d-42e0d45a7420	15a46f44-4094-4b25-a4d3-51a3f682a4b9	0.00	SLL	\N	2025-12-19 22:26:41.50751+05:30	2025-12-19 22:26:41.50751+05:30
b82201e3-1ca9-4ca6-ad64-278cd0e73b38	43f2c95b-4fe8-4481-aa42-77125cef5d1f	0.00	SLL	\N	2025-12-19 22:31:27.911276+05:30	2025-12-19 22:31:27.911276+05:30
5841df58-ae1e-449f-b800-1b8947f0577c	42fa68c5-e80b-4100-9aad-c28300e33fff	0.00	SLL	\N	2025-12-19 22:33:43.703066+05:30	2025-12-19 22:33:43.703066+05:30
0d005204-f0c0-4085-b073-9d3ffa148b1d	6b864809-fb5a-4a1f-a95e-edf87b7eeb5c	0.00	SLL	\N	2025-12-20 12:41:17.937744+05:30	2025-12-20 12:41:17.937744+05:30
18bee39e-ad39-499c-9495-d7416d7a8d7e	72fe9f39-5599-4339-bd5b-5adc6ca37996	16162.00	SLL	2026-01-02 16:34:30.480453+05:30	2025-12-19 23:27:35.419864+05:30	2026-01-02 16:34:30.480453+05:30
c0cbdf1a-f592-4bec-9dd0-7708eb2c1278	8c6b2a0e-9b12-49db-8a5f-8dcb58572d72	32000.00	SLL	2025-12-21 00:00:30.483263+05:30	2025-12-20 23:40:21.230675+05:30	2025-12-21 00:00:30.483263+05:30
b31356de-0e1b-4663-abf4-20cc50449b12	39d53302-9bf3-4e79-95ac-883cae482d9e	4838.00	SLL	2026-01-02 16:34:30.480453+05:30	2026-01-02 14:37:35.604597+05:30	2026-01-02 16:34:30.480453+05:30
\.


--
-- Data for Name: withdrawal_requests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.withdrawal_requests (id, user_id, amount, fee, net_amount, withdrawal_type, investment_id, destination, bank_account_id, mobile_money_number, status, admin_id, rejection_reason, transaction_id, approved_at, rejected_at, processed_at, created_at, updated_at) FROM stdin;
\.


--
-- Name: election_options_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.election_options_id_seq', 1, false);


--
-- Name: election_votes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.election_votes_id_seq', 1, false);


--
-- Name: elections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.elections_id_seq', 1, false);


--
-- Name: admin_audit_logs admin_audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_audit_logs
    ADD CONSTRAINT admin_audit_logs_pkey PRIMARY KEY (id);


--
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- Name: admins admins_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_user_id_key UNIQUE (user_id);


--
-- Name: agent_commissions agent_commissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_commissions
    ADD CONSTRAINT agent_commissions_pkey PRIMARY KEY (id);


--
-- Name: agent_credit_requests agent_credit_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_credit_requests
    ADD CONSTRAINT agent_credit_requests_pkey PRIMARY KEY (id);


--
-- Name: agent_reviews agent_reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_reviews
    ADD CONSTRAINT agent_reviews_pkey PRIMARY KEY (id);


--
-- Name: agent_reviews agent_reviews_transaction_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_reviews
    ADD CONSTRAINT agent_reviews_transaction_id_key UNIQUE (transaction_id);


--
-- Name: agents agents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agents_pkey PRIMARY KEY (id);


--
-- Name: agents agents_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agents_user_id_key UNIQUE (user_id);


--
-- Name: api_keys api_keys_key_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_key_hash_key UNIQUE (key_hash);


--
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: bank_accounts bank_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bank_accounts
    ADD CONSTRAINT bank_accounts_pkey PRIMARY KEY (id);


--
-- Name: bill_payments bill_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_payments
    ADD CONSTRAINT bill_payments_pkey PRIMARY KEY (id);


--
-- Name: bill_providers bill_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_providers
    ADD CONSTRAINT bill_providers_pkey PRIMARY KEY (id);


--
-- Name: election_options election_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.election_options
    ADD CONSTRAINT election_options_pkey PRIMARY KEY (id);


--
-- Name: election_votes election_votes_election_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.election_votes
    ADD CONSTRAINT election_votes_election_id_user_id_key UNIQUE (election_id, user_id);


--
-- Name: election_votes election_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.election_votes
    ADD CONSTRAINT election_votes_pkey PRIMARY KEY (id);


--
-- Name: elections elections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.elections
    ADD CONSTRAINT elections_pkey PRIMARY KEY (id);


--
-- Name: file_uploads file_uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.file_uploads
    ADD CONSTRAINT file_uploads_pkey PRIMARY KEY (id);


--
-- Name: fraud_detection_logs fraud_detection_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fraud_detection_logs
    ADD CONSTRAINT fraud_detection_logs_pkey PRIMARY KEY (id);


--
-- Name: investment_categories investment_categories_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investment_categories
    ADD CONSTRAINT investment_categories_name_key UNIQUE (name);


--
-- Name: investment_categories investment_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investment_categories
    ADD CONSTRAINT investment_categories_pkey PRIMARY KEY (id);


--
-- Name: investment_opportunities investment_opportunities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investment_opportunities
    ADD CONSTRAINT investment_opportunities_pkey PRIMARY KEY (id);


--
-- Name: investment_returns investment_returns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investment_returns
    ADD CONSTRAINT investment_returns_pkey PRIMARY KEY (id);


--
-- Name: investment_tenure_requests investment_tenure_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investment_tenure_requests
    ADD CONSTRAINT investment_tenure_requests_pkey PRIMARY KEY (id);


--
-- Name: investment_tenures investment_tenures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investment_tenures
    ADD CONSTRAINT investment_tenures_pkey PRIMARY KEY (id);


--
-- Name: investment_units investment_units_category_unit_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investment_units
    ADD CONSTRAINT investment_units_category_unit_name_key UNIQUE (category, unit_name);


--
-- Name: investment_units investment_units_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investment_units
    ADD CONSTRAINT investment_units_pkey PRIMARY KEY (id);


--
-- Name: investments investments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investments
    ADD CONSTRAINT investments_pkey PRIMARY KEY (id);


--
-- Name: ip_access_control ip_access_control_ip_address_type_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ip_access_control
    ADD CONSTRAINT ip_access_control_ip_address_type_key UNIQUE (ip_address, type);


--
-- Name: ip_access_control ip_access_control_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ip_access_control
    ADD CONSTRAINT ip_access_control_pkey PRIMARY KEY (id);


--
-- Name: kyc_documents kyc_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kyc_documents
    ADD CONSTRAINT kyc_documents_pkey PRIMARY KEY (id);


--
-- Name: metal_price_cache metal_price_cache_metal_symbol_base_currency_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metal_price_cache
    ADD CONSTRAINT metal_price_cache_metal_symbol_base_currency_key UNIQUE (metal_symbol, base_currency);


--
-- Name: metal_price_cache metal_price_cache_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metal_price_cache
    ADD CONSTRAINT metal_price_cache_pkey PRIMARY KEY (id);


--
-- Name: notification_preferences notification_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT notification_preferences_pkey PRIMARY KEY (id);


--
-- Name: notification_preferences notification_preferences_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT notification_preferences_user_id_key UNIQUE (user_id);


--
-- Name: notification_templates notification_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_templates
    ADD CONSTRAINT notification_templates_pkey PRIMARY KEY (id);


--
-- Name: notification_templates notification_templates_template_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_templates
    ADD CONSTRAINT notification_templates_template_code_key UNIQUE (template_code);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: otp_codes otp_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.otp_codes
    ADD CONSTRAINT otp_codes_pkey PRIMARY KEY (id);


--
-- Name: otps otps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.otps
    ADD CONSTRAINT otps_pkey PRIMARY KEY (id);


--
-- Name: password_history password_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_history
    ADD CONSTRAINT password_history_pkey PRIMARY KEY (id);


--
-- Name: polls polls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polls
    ADD CONSTRAINT polls_pkey PRIMARY KEY (id);


--
-- Name: push_tokens push_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_tokens
    ADD CONSTRAINT push_tokens_pkey PRIMARY KEY (id);


--
-- Name: rate_limits rate_limits_identifier_endpoint_window_start_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_limits
    ADD CONSTRAINT rate_limits_identifier_endpoint_window_start_key UNIQUE (identifier, endpoint, window_start);


--
-- Name: rate_limits rate_limits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_limits
    ADD CONSTRAINT rate_limits_pkey PRIMARY KEY (id);


--
-- Name: referrals referrals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_pkey PRIMARY KEY (id);


--
-- Name: referrals referrals_referred_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_referred_id_key UNIQUE (referred_id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_key UNIQUE (token);


--
-- Name: scheduled_transactions scheduled_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduled_transactions
    ADD CONSTRAINT scheduled_transactions_pkey PRIMARY KEY (id);


--
-- Name: security_events security_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security_events
    ADD CONSTRAINT security_events_pkey PRIMARY KEY (id);


--
-- Name: support_tickets support_tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_tickets
    ADD CONSTRAINT support_tickets_pkey PRIMARY KEY (id);


--
-- Name: support_tickets support_tickets_ticket_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_tickets
    ADD CONSTRAINT support_tickets_ticket_id_key UNIQUE (ticket_id);


--
-- Name: system_config system_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_config
    ADD CONSTRAINT system_config_pkey PRIMARY KEY (key);


--
-- Name: transaction_reversals transaction_reversals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_reversals
    ADD CONSTRAINT transaction_reversals_pkey PRIMARY KEY (id);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: transactions transactions_stripe_payment_intent_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_stripe_payment_intent_id_key UNIQUE (stripe_payment_intent_id);


--
-- Name: transactions transactions_transaction_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_transaction_id_key UNIQUE (transaction_id);


--
-- Name: user_devices user_devices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_devices
    ADD CONSTRAINT user_devices_pkey PRIMARY KEY (id);


--
-- Name: user_devices user_devices_user_id_device_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_devices
    ADD CONSTRAINT user_devices_user_id_device_id_key UNIQUE (user_id, device_id);


--
-- Name: user_sessions user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (id);


--
-- Name: user_sessions user_sessions_refresh_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_refresh_token_hash_key UNIQUE (refresh_token_hash);


--
-- Name: user_sessions user_sessions_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_token_hash_key UNIQUE (token_hash);


--
-- Name: user_transaction_limits user_transaction_limits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_transaction_limits
    ADD CONSTRAINT user_transaction_limits_pkey PRIMARY KEY (id);


--
-- Name: user_transaction_limits user_transaction_limits_user_id_limit_type_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_transaction_limits
    ADD CONSTRAINT user_transaction_limits_user_id_limit_type_key UNIQUE (user_id, limit_type);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_referral_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_referral_code_key UNIQUE (referral_code);


--
-- Name: users users_stripe_customer_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_stripe_customer_id_key UNIQUE (stripe_customer_id);


--
-- Name: votes votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT votes_pkey PRIMARY KEY (id);


--
-- Name: votes votes_poll_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT votes_poll_id_user_id_key UNIQUE (poll_id, user_id);


--
-- Name: wallet_audit_trail wallet_audit_trail_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallet_audit_trail
    ADD CONSTRAINT wallet_audit_trail_pkey PRIMARY KEY (id);


--
-- Name: wallets wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_pkey PRIMARY KEY (id);


--
-- Name: wallets wallets_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_user_id_key UNIQUE (user_id);


--
-- Name: withdrawal_requests withdrawal_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.withdrawal_requests
    ADD CONSTRAINT withdrawal_requests_pkey PRIMARY KEY (id);


--
-- Name: idx_admin_audit_logs_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_admin_audit_logs_action ON public.admin_audit_logs USING btree (action);


--
-- Name: idx_admin_audit_logs_admin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_admin_audit_logs_admin ON public.admin_audit_logs USING btree (admin_id);


--
-- Name: idx_admin_audit_logs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_admin_audit_logs_created_at ON public.admin_audit_logs USING btree (created_at DESC);


--
-- Name: idx_admin_audit_logs_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_admin_audit_logs_entity ON public.admin_audit_logs USING btree (entity_type, entity_id);


--
-- Name: idx_admins_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_admins_role ON public.admins USING btree (admin_role);


--
-- Name: idx_admins_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_admins_user ON public.admins USING btree (user_id);


--
-- Name: idx_agent_commissions_agent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_commissions_agent ON public.agent_commissions USING btree (agent_id);


--
-- Name: idx_agent_commissions_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_commissions_created_at ON public.agent_commissions USING btree (created_at DESC);


--
-- Name: idx_agent_commissions_paid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_commissions_paid ON public.agent_commissions USING btree (paid);


--
-- Name: idx_agent_commissions_transaction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_commissions_transaction ON public.agent_commissions USING btree (transaction_id);


--
-- Name: idx_agent_credit_requests_admin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_credit_requests_admin ON public.agent_credit_requests USING btree (admin_id);


--
-- Name: idx_agent_credit_requests_agent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_credit_requests_agent ON public.agent_credit_requests USING btree (agent_id);


--
-- Name: idx_agent_credit_requests_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_credit_requests_status ON public.agent_credit_requests USING btree (status);


--
-- Name: idx_agent_reviews_agent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_reviews_agent ON public.agent_reviews USING btree (agent_id);


--
-- Name: idx_agent_reviews_rating; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_reviews_rating ON public.agent_reviews USING btree (rating);


--
-- Name: idx_agent_reviews_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_reviews_user ON public.agent_reviews USING btree (user_id);


--
-- Name: idx_agents_active_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agents_active_status ON public.agents USING btree (active_status);


--
-- Name: idx_agents_location; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agents_location ON public.agents USING btree (location_lat, location_lng);


--
-- Name: idx_agents_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agents_user ON public.agents USING btree (user_id);


--
-- Name: idx_api_keys_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_keys_active ON public.api_keys USING btree (is_active);


--
-- Name: idx_api_keys_admin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_keys_admin ON public.api_keys USING btree (admin_id);


--
-- Name: idx_api_keys_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_keys_expires ON public.api_keys USING btree (expires_at);


--
-- Name: idx_api_keys_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_keys_hash ON public.api_keys USING btree (key_hash);


--
-- Name: idx_audit_log_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_log_created ON public.audit_log USING btree (created_at DESC);


--
-- Name: idx_audit_log_operation; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_log_operation ON public.audit_log USING btree (operation);


--
-- Name: idx_audit_log_record; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_log_record ON public.audit_log USING btree (record_id);


--
-- Name: idx_audit_log_table; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_log_table ON public.audit_log USING btree (table_name);


--
-- Name: idx_audit_log_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_log_user ON public.audit_log USING btree (user_id);


--
-- Name: idx_audit_trail_action_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_trail_action_type ON public.wallet_audit_trail USING btree (action_type);


--
-- Name: idx_audit_trail_admin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_trail_admin ON public.wallet_audit_trail USING btree (admin_id);


--
-- Name: idx_audit_trail_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_trail_created_at ON public.wallet_audit_trail USING btree (created_at);


--
-- Name: idx_audit_trail_transaction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_trail_transaction ON public.wallet_audit_trail USING btree (transaction_id);


--
-- Name: idx_audit_trail_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_trail_user ON public.wallet_audit_trail USING btree (user_id);


--
-- Name: idx_bank_accounts_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bank_accounts_user ON public.bank_accounts USING btree (user_id);


--
-- Name: idx_bank_accounts_verified; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bank_accounts_verified ON public.bank_accounts USING btree (is_verified);


--
-- Name: idx_bill_payments_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bill_payments_provider ON public.bill_payments USING btree (provider_id);


--
-- Name: idx_bill_payments_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bill_payments_status ON public.bill_payments USING btree (status);


--
-- Name: idx_bill_payments_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bill_payments_user ON public.bill_payments USING btree (user_id);


--
-- Name: idx_bill_providers_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bill_providers_active ON public.bill_providers USING btree (is_active);


--
-- Name: idx_bill_providers_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bill_providers_type ON public.bill_providers USING btree (type);


--
-- Name: idx_election_options_election; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_election_options_election ON public.election_options USING btree (election_id);


--
-- Name: idx_election_votes_election; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_election_votes_election ON public.election_votes USING btree (election_id);


--
-- Name: idx_election_votes_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_election_votes_user ON public.election_votes USING btree (user_id);


--
-- Name: idx_elections_end_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_elections_end_time ON public.elections USING btree (end_time);


--
-- Name: idx_elections_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_elections_status ON public.elections USING btree (status);


--
-- Name: idx_file_uploads_checksum; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_file_uploads_checksum ON public.file_uploads USING btree (checksum);


--
-- Name: idx_file_uploads_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_file_uploads_created_at ON public.file_uploads USING btree (created_at DESC);


--
-- Name: idx_file_uploads_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_file_uploads_type ON public.file_uploads USING btree (file_type);


--
-- Name: idx_file_uploads_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_file_uploads_user ON public.file_uploads USING btree (user_id);


--
-- Name: idx_fraud_detection_risk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fraud_detection_risk ON public.fraud_detection_logs USING btree (risk_score);


--
-- Name: idx_fraud_detection_transaction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fraud_detection_transaction ON public.fraud_detection_logs USING btree (transaction_id);


--
-- Name: idx_fraud_detection_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fraud_detection_type ON public.fraud_detection_logs USING btree (detection_type);


--
-- Name: idx_fraud_detection_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fraud_detection_user ON public.fraud_detection_logs USING btree (user_id);


--
-- Name: idx_inv_opp_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_opp_active ON public.investment_opportunities USING btree (is_active);


--
-- Name: idx_inv_opp_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_opp_category ON public.investment_opportunities USING btree (category_id);


--
-- Name: idx_inv_opp_category_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_opp_category_active ON public.investment_opportunities USING btree (category_id, is_active);


--
-- Name: idx_inv_opp_display_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_opp_display_order ON public.investment_opportunities USING btree (display_order);


--
-- Name: idx_inv_opp_metadata; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_opp_metadata ON public.investment_opportunities USING gin (metadata);


--
-- Name: idx_investment_returns_investment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_investment_returns_investment ON public.investment_returns USING btree (investment_id);


--
-- Name: idx_investment_returns_processed_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_investment_returns_processed_by ON public.investment_returns USING btree (processed_by);


--
-- Name: idx_investment_returns_return_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_investment_returns_return_date ON public.investment_returns USING btree (return_date);


--
-- Name: idx_investment_returns_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_investment_returns_status ON public.investment_returns USING btree (status);


--
-- Name: idx_investment_tenure_requests_investment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_investment_tenure_requests_investment ON public.investment_tenure_requests USING btree (investment_id);


--
-- Name: idx_investment_tenure_requests_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_investment_tenure_requests_status ON public.investment_tenure_requests USING btree (status);


--
-- Name: idx_investment_tenures_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_investment_tenures_active ON public.investment_tenures USING btree (is_active);


--
-- Name: idx_investment_tenures_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_investment_tenures_category ON public.investment_tenures USING btree (category_id);


--
-- Name: idx_investment_units_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_investment_units_active ON public.investment_units USING btree (is_active);


--
-- Name: idx_investment_units_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_investment_units_category ON public.investment_units USING btree (category);


--
-- Name: idx_investments_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_investments_category ON public.investments USING btree (category);


--
-- Name: idx_investments_end_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_investments_end_date ON public.investments USING btree (end_date);


--
-- Name: idx_investments_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_investments_status ON public.investments USING btree (status);


--
-- Name: idx_investments_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_investments_user ON public.investments USING btree (user_id);


--
-- Name: idx_ip_access_control_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ip_access_control_expires ON public.ip_access_control USING btree (expires_at);


--
-- Name: idx_ip_access_control_ip; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ip_access_control_ip ON public.ip_access_control USING btree (ip_address);


--
-- Name: idx_ip_access_control_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ip_access_control_type ON public.ip_access_control USING btree (type);


--
-- Name: idx_kyc_documents_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kyc_documents_status ON public.kyc_documents USING btree (status);


--
-- Name: idx_kyc_documents_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kyc_documents_type ON public.kyc_documents USING btree (document_type);


--
-- Name: idx_kyc_documents_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kyc_documents_user ON public.kyc_documents USING btree (user_id);


--
-- Name: idx_metal_price_cache_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_metal_price_cache_currency ON public.metal_price_cache USING btree (base_currency);


--
-- Name: idx_metal_price_cache_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_metal_price_cache_expires ON public.metal_price_cache USING btree (expires_at);


--
-- Name: idx_metal_price_cache_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_metal_price_cache_lookup ON public.metal_price_cache USING btree (metal_symbol, base_currency, expires_at);


--
-- Name: idx_metal_price_cache_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_metal_price_cache_symbol ON public.metal_price_cache USING btree (metal_symbol);


--
-- Name: idx_notification_preferences_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notification_preferences_user ON public.notification_preferences USING btree (user_id);


--
-- Name: idx_notification_templates_channel; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notification_templates_channel ON public.notification_templates USING btree (channel);


--
-- Name: idx_notification_templates_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notification_templates_code ON public.notification_templates USING btree (template_code);


--
-- Name: idx_notifications_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_created_at ON public.notifications USING btree (created_at DESC);


--
-- Name: idx_notifications_read; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_read ON public.notifications USING btree (is_read);


--
-- Name: idx_notifications_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_user ON public.notifications USING btree (user_id);


--
-- Name: idx_otp_codes_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_otp_codes_email ON public.otp_codes USING btree (email);


--
-- Name: idx_otp_codes_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_otp_codes_expires_at ON public.otp_codes USING btree (expires_at);


--
-- Name: idx_otp_codes_phone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_otp_codes_phone ON public.otp_codes USING btree (phone);


--
-- Name: idx_otps_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_otps_expires_at ON public.otps USING btree (expires_at);


--
-- Name: idx_otps_phone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_otps_phone ON public.otps USING btree (phone, country_code);


--
-- Name: idx_otps_purpose; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_otps_purpose ON public.otps USING btree (purpose);


--
-- Name: idx_password_history_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_password_history_created ON public.password_history USING btree (created_at DESC);


--
-- Name: idx_password_history_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_password_history_user ON public.password_history USING btree (user_id);


--
-- Name: idx_polls_created_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_polls_created_by ON public.polls USING btree (created_by_admin_id);


--
-- Name: idx_polls_end_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_polls_end_time ON public.polls USING btree (end_time);


--
-- Name: idx_polls_start_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_polls_start_time ON public.polls USING btree (start_time);


--
-- Name: idx_polls_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_polls_status ON public.polls USING btree (status);


--
-- Name: idx_push_tokens_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_push_tokens_active ON public.push_tokens USING btree (is_active);


--
-- Name: idx_push_tokens_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_push_tokens_user ON public.push_tokens USING btree (user_id);


--
-- Name: idx_rate_limits_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rate_limits_identifier ON public.rate_limits USING btree (identifier);


--
-- Name: idx_rate_limits_window; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rate_limits_window ON public.rate_limits USING btree (window_end);


--
-- Name: idx_referrals_referred; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_referrals_referred ON public.referrals USING btree (referred_id);


--
-- Name: idx_referrals_referrer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_referrals_referrer ON public.referrals USING btree (referrer_id);


--
-- Name: idx_referrals_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_referrals_status ON public.referrals USING btree (status);


--
-- Name: idx_refresh_tokens_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_refresh_tokens_expires_at ON public.refresh_tokens USING btree (expires_at);


--
-- Name: idx_refresh_tokens_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_refresh_tokens_token ON public.refresh_tokens USING btree (token);


--
-- Name: idx_refresh_tokens_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_refresh_tokens_user ON public.refresh_tokens USING btree (user_id);


--
-- Name: idx_scheduled_transactions_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scheduled_transactions_active ON public.scheduled_transactions USING btree (is_active);


--
-- Name: idx_scheduled_transactions_next_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scheduled_transactions_next_date ON public.scheduled_transactions USING btree (next_execution_date);


--
-- Name: idx_scheduled_transactions_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scheduled_transactions_user ON public.scheduled_transactions USING btree (user_id);


--
-- Name: idx_security_events_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_security_events_created_at ON public.security_events USING btree (created_at DESC);


--
-- Name: idx_security_events_resolved; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_security_events_resolved ON public.security_events USING btree (resolved);


--
-- Name: idx_security_events_severity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_security_events_severity ON public.security_events USING btree (severity);


--
-- Name: idx_security_events_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_security_events_type ON public.security_events USING btree (event_type);


--
-- Name: idx_security_events_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_security_events_user ON public.security_events USING btree (user_id);


--
-- Name: idx_support_tickets_assigned_to; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_support_tickets_assigned_to ON public.support_tickets USING btree (assigned_to);


--
-- Name: idx_support_tickets_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_support_tickets_status ON public.support_tickets USING btree (status);


--
-- Name: idx_support_tickets_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_support_tickets_user ON public.support_tickets USING btree (user_id);


--
-- Name: idx_system_config_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_config_category ON public.system_config USING btree (category);


--
-- Name: idx_transaction_reversals_original; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_reversals_original ON public.transaction_reversals USING btree (original_transaction_id);


--
-- Name: idx_transaction_reversals_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_reversals_status ON public.transaction_reversals USING btree (status);


--
-- Name: idx_transactions_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_created_at ON public.transactions USING btree (created_at DESC);


--
-- Name: idx_transactions_from_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_from_user ON public.transactions USING btree (from_user_id);


--
-- Name: idx_transactions_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_id ON public.transactions USING btree (transaction_id);


--
-- Name: idx_transactions_metadata; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_metadata ON public.transactions USING gin (metadata);


--
-- Name: idx_transactions_payment_gateway_response; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_payment_gateway_response ON public.transactions USING gin (payment_gateway_response);


--
-- Name: idx_transactions_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_status ON public.transactions USING btree (status);


--
-- Name: idx_transactions_stripe_payment_intent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_stripe_payment_intent ON public.transactions USING btree (stripe_payment_intent_id);


--
-- Name: idx_transactions_to_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_to_user ON public.transactions USING btree (to_user_id);


--
-- Name: idx_transactions_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_type ON public.transactions USING btree (type);


--
-- Name: idx_user_devices_fingerprint; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_devices_fingerprint ON public.user_devices USING btree (fingerprint);


--
-- Name: idx_user_devices_trusted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_devices_trusted ON public.user_devices USING btree (is_trusted);


--
-- Name: idx_user_devices_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_devices_user ON public.user_devices USING btree (user_id);


--
-- Name: idx_user_sessions_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_sessions_active ON public.user_sessions USING btree (is_active);


--
-- Name: idx_user_sessions_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_sessions_expires ON public.user_sessions USING btree (expires_at);


--
-- Name: idx_user_sessions_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_sessions_token ON public.user_sessions USING btree (token_hash);


--
-- Name: idx_user_sessions_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_sessions_user ON public.user_sessions USING btree (user_id);


--
-- Name: idx_user_transaction_limits_reset; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_transaction_limits_reset ON public.user_transaction_limits USING btree (reset_at);


--
-- Name: idx_user_transaction_limits_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_transaction_limits_user ON public.user_transaction_limits USING btree (user_id);


--
-- Name: idx_users_deletion_scheduled; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_deletion_scheduled ON public.users USING btree (deletion_scheduled_for) WHERE (deletion_scheduled_for IS NOT NULL);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_kyc_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_kyc_status ON public.users USING btree (kyc_status);


--
-- Name: idx_users_phone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_phone ON public.users USING btree (phone);


--
-- Name: idx_users_referral_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_referral_code ON public.users USING btree (referral_code) WHERE (referral_code IS NOT NULL);


--
-- Name: idx_users_referred_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_referred_by ON public.users USING btree (referred_by) WHERE (referred_by IS NOT NULL);


--
-- Name: idx_users_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_role ON public.users USING btree (role);


--
-- Name: idx_users_stripe_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_stripe_customer ON public.users USING btree (stripe_customer_id);


--
-- Name: idx_votes_poll; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_votes_poll ON public.votes USING btree (poll_id);


--
-- Name: idx_votes_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_votes_user ON public.votes USING btree (user_id);


--
-- Name: idx_votes_voted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_votes_voted_at ON public.votes USING btree (voted_at);


--
-- Name: idx_wallets_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_wallets_user ON public.wallets USING btree (user_id);


--
-- Name: idx_withdrawal_requests_admin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_withdrawal_requests_admin ON public.withdrawal_requests USING btree (admin_id);


--
-- Name: idx_withdrawal_requests_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_withdrawal_requests_status ON public.withdrawal_requests USING btree (status);


--
-- Name: idx_withdrawal_requests_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_withdrawal_requests_user ON public.withdrawal_requests USING btree (user_id);


--
-- Name: vw_agent_performance_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX vw_agent_performance_id_idx ON public.vw_agent_performance USING btree (id);


--
-- Name: vw_user_dashboard_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX vw_user_dashboard_id_idx ON public.vw_user_dashboard USING btree (id);


--
-- Name: agents audit_agents; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_agents AFTER INSERT OR DELETE OR UPDATE ON public.agents FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: investments audit_investments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_investments AFTER INSERT OR DELETE OR UPDATE ON public.investments FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: transactions audit_transactions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_transactions AFTER INSERT OR DELETE OR UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: users audit_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_users AFTER INSERT OR DELETE OR UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: wallets audit_wallets; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_wallets AFTER INSERT OR DELETE OR UPDATE ON public.wallets FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: users check_password_reuse; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_password_reuse BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.save_password_history();


--
-- Name: support_tickets set_ticket_id_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_ticket_id_trigger BEFORE INSERT ON public.support_tickets FOR EACH ROW EXECUTE FUNCTION public.set_ticket_id();


--
-- Name: transactions set_transaction_id_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_transaction_id_trigger BEFORE INSERT ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.set_transaction_id();


--
-- Name: election_votes trigger_update_election_stats; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_election_stats AFTER INSERT ON public.election_votes FOR EACH ROW EXECUTE FUNCTION public.update_election_stats();


--
-- Name: metal_price_cache trigger_update_metal_price_cache_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_metal_price_cache_timestamp BEFORE UPDATE ON public.metal_price_cache FOR EACH ROW EXECUTE FUNCTION public.update_metal_price_cache_timestamp();


--
-- Name: admins update_admins_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_admins_updated_at BEFORE UPDATE ON public.admins FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: agent_credit_requests update_agent_credit_requests_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_agent_credit_requests_updated_at BEFORE UPDATE ON public.agent_credit_requests FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: agents update_agents_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_agents_updated_at BEFORE UPDATE ON public.agents FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: api_keys update_api_keys_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_api_keys_updated_at BEFORE UPDATE ON public.api_keys FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: bank_accounts update_bank_accounts_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_bank_accounts_updated_at BEFORE UPDATE ON public.bank_accounts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: bill_payments update_bill_payments_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_bill_payments_updated_at BEFORE UPDATE ON public.bill_payments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: bill_providers update_bill_providers_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_bill_providers_updated_at BEFORE UPDATE ON public.bill_providers FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: file_uploads update_file_uploads_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_file_uploads_updated_at BEFORE UPDATE ON public.file_uploads FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: investment_categories update_investment_categories_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_investment_categories_updated_at BEFORE UPDATE ON public.investment_categories FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: investment_opportunities update_investment_opportunities_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_investment_opportunities_updated_at BEFORE UPDATE ON public.investment_opportunities FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: investment_returns update_investment_returns_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_investment_returns_updated_at BEFORE UPDATE ON public.investment_returns FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: investment_tenure_requests update_investment_tenure_requests_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_investment_tenure_requests_updated_at BEFORE UPDATE ON public.investment_tenure_requests FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: investment_tenures update_investment_tenures_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_investment_tenures_updated_at BEFORE UPDATE ON public.investment_tenures FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: investment_units update_investment_units_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_investment_units_updated_at BEFORE UPDATE ON public.investment_units FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: investments update_investments_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_investments_updated_at BEFORE UPDATE ON public.investments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: kyc_documents update_kyc_documents_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_kyc_documents_updated_at BEFORE UPDATE ON public.kyc_documents FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: notification_preferences update_notification_preferences_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_notification_preferences_updated_at BEFORE UPDATE ON public.notification_preferences FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: notification_templates update_notification_templates_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_notification_templates_updated_at BEFORE UPDATE ON public.notification_templates FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: polls update_polls_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_polls_updated_at BEFORE UPDATE ON public.polls FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: push_tokens update_push_tokens_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_push_tokens_updated_at BEFORE UPDATE ON public.push_tokens FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: referrals update_referrals_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_referrals_updated_at BEFORE UPDATE ON public.referrals FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: scheduled_transactions update_scheduled_transactions_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_scheduled_transactions_updated_at BEFORE UPDATE ON public.scheduled_transactions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: support_tickets update_support_tickets_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_support_tickets_updated_at BEFORE UPDATE ON public.support_tickets FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: transactions update_transactions_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: user_devices update_user_devices_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_user_devices_updated_at BEFORE UPDATE ON public.user_devices FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: user_transaction_limits update_user_transaction_limits_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_user_transaction_limits_updated_at BEFORE UPDATE ON public.user_transaction_limits FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: users update_users_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: transactions update_wallet_on_transaction; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_wallet_on_transaction AFTER UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.update_wallet_balance();


--
-- Name: wallets update_wallets_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_wallets_updated_at BEFORE UPDATE ON public.wallets FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: withdrawal_requests update_withdrawal_requests_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_withdrawal_requests_updated_at BEFORE UPDATE ON public.withdrawal_requests FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: admin_audit_logs admin_audit_logs_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_audit_logs
    ADD CONSTRAINT admin_audit_logs_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: admins admins_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: admins admins_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: agent_commissions agent_commissions_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_commissions
    ADD CONSTRAINT agent_commissions_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: agent_commissions agent_commissions_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_commissions
    ADD CONSTRAINT agent_commissions_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.transactions(id) ON DELETE CASCADE;


--
-- Name: agent_credit_requests agent_credit_requests_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_credit_requests
    ADD CONSTRAINT agent_credit_requests_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: agent_credit_requests agent_credit_requests_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_credit_requests
    ADD CONSTRAINT agent_credit_requests_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: agent_reviews agent_reviews_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_reviews
    ADD CONSTRAINT agent_reviews_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: agent_reviews agent_reviews_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_reviews
    ADD CONSTRAINT agent_reviews_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.transactions(id) ON DELETE SET NULL;


--
-- Name: agent_reviews agent_reviews_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_reviews
    ADD CONSTRAINT agent_reviews_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: agents agents_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agents_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: agents agents_verified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agents_verified_by_fkey FOREIGN KEY (verified_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: api_keys api_keys_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: api_keys api_keys_revoked_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_revoked_by_fkey FOREIGN KEY (revoked_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: bank_accounts bank_accounts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bank_accounts
    ADD CONSTRAINT bank_accounts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: bill_payments bill_payments_provider_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_payments
    ADD CONSTRAINT bill_payments_provider_id_fkey FOREIGN KEY (provider_id) REFERENCES public.bill_providers(id) ON DELETE SET NULL;


--
-- Name: bill_payments bill_payments_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_payments
    ADD CONSTRAINT bill_payments_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.transactions(id) ON DELETE CASCADE;


--
-- Name: bill_payments bill_payments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bill_payments
    ADD CONSTRAINT bill_payments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: election_options election_options_election_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.election_options
    ADD CONSTRAINT election_options_election_id_fkey FOREIGN KEY (election_id) REFERENCES public.elections(id) ON DELETE CASCADE;


--
-- Name: election_votes election_votes_election_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.election_votes
    ADD CONSTRAINT election_votes_election_id_fkey FOREIGN KEY (election_id) REFERENCES public.elections(id) ON DELETE CASCADE;


--
-- Name: election_votes election_votes_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.election_votes
    ADD CONSTRAINT election_votes_option_id_fkey FOREIGN KEY (option_id) REFERENCES public.election_options(id) ON DELETE CASCADE;


--
-- Name: election_votes election_votes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.election_votes
    ADD CONSTRAINT election_votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: elections elections_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.elections
    ADD CONSTRAINT elections_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.admins(id);


--
-- Name: file_uploads file_uploads_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.file_uploads
    ADD CONSTRAINT file_uploads_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: fraud_detection_logs fraud_detection_logs_reviewed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fraud_detection_logs
    ADD CONSTRAINT fraud_detection_logs_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.users(id);


--
-- Name: fraud_detection_logs fraud_detection_logs_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fraud_detection_logs
    ADD CONSTRAINT fraud_detection_logs_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.transactions(id);


--
-- Name: fraud_detection_logs fraud_detection_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fraud_detection_logs
    ADD CONSTRAINT fraud_detection_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: investment_opportunities investment_opportunities_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investment_opportunities
    ADD CONSTRAINT investment_opportunities_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.investment_categories(id) ON DELETE CASCADE;


--
-- Name: investment_returns investment_returns_investment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investment_returns
    ADD CONSTRAINT investment_returns_investment_id_fkey FOREIGN KEY (investment_id) REFERENCES public.investments(id) ON DELETE CASCADE;


--
-- Name: investment_returns investment_returns_processed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investment_returns
    ADD CONSTRAINT investment_returns_processed_by_fkey FOREIGN KEY (processed_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: investment_tenure_requests investment_tenure_requests_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investment_tenure_requests
    ADD CONSTRAINT investment_tenure_requests_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: investment_tenure_requests investment_tenure_requests_investment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investment_tenure_requests
    ADD CONSTRAINT investment_tenure_requests_investment_id_fkey FOREIGN KEY (investment_id) REFERENCES public.investments(id) ON DELETE CASCADE;


--
-- Name: investment_tenure_requests investment_tenure_requests_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investment_tenure_requests
    ADD CONSTRAINT investment_tenure_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: investment_tenures investment_tenures_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investment_tenures
    ADD CONSTRAINT investment_tenures_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.investment_categories(id) ON DELETE CASCADE;


--
-- Name: investments investments_tenure_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investments
    ADD CONSTRAINT investments_tenure_id_fkey FOREIGN KEY (tenure_id) REFERENCES public.investment_tenures(id);


--
-- Name: investments investments_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investments
    ADD CONSTRAINT investments_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.transactions(id) ON DELETE SET NULL;


--
-- Name: investments investments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investments
    ADD CONSTRAINT investments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: investments investments_withdrawal_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investments
    ADD CONSTRAINT investments_withdrawal_transaction_id_fkey FOREIGN KEY (withdrawal_transaction_id) REFERENCES public.transactions(id) ON DELETE SET NULL;


--
-- Name: ip_access_control ip_access_control_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ip_access_control
    ADD CONSTRAINT ip_access_control_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: kyc_documents kyc_documents_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kyc_documents
    ADD CONSTRAINT kyc_documents_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: kyc_documents kyc_documents_verified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kyc_documents
    ADD CONSTRAINT kyc_documents_verified_by_fkey FOREIGN KEY (verified_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: notification_preferences notification_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT notification_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: otp_codes otp_codes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.otp_codes
    ADD CONSTRAINT otp_codes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: password_history password_history_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_history
    ADD CONSTRAINT password_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: polls polls_created_by_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polls
    ADD CONSTRAINT polls_created_by_admin_id_fkey FOREIGN KEY (created_by_admin_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: push_tokens push_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_tokens
    ADD CONSTRAINT push_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: referrals referrals_referred_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_referred_id_fkey FOREIGN KEY (referred_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: referrals referrals_referrer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_referrer_id_fkey FOREIGN KEY (referrer_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: scheduled_transactions scheduled_transactions_bill_provider_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduled_transactions
    ADD CONSTRAINT scheduled_transactions_bill_provider_id_fkey FOREIGN KEY (bill_provider_id) REFERENCES public.bill_providers(id);


--
-- Name: scheduled_transactions scheduled_transactions_recipient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduled_transactions
    ADD CONSTRAINT scheduled_transactions_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES public.users(id);


--
-- Name: scheduled_transactions scheduled_transactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduled_transactions
    ADD CONSTRAINT scheduled_transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: security_events security_events_resolved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security_events
    ADD CONSTRAINT security_events_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: security_events security_events_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security_events
    ADD CONSTRAINT security_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: support_tickets support_tickets_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_tickets
    ADD CONSTRAINT support_tickets_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: support_tickets support_tickets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_tickets
    ADD CONSTRAINT support_tickets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: system_config system_config_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_config
    ADD CONSTRAINT system_config_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: transaction_reversals transaction_reversals_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_reversals
    ADD CONSTRAINT transaction_reversals_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.users(id);


--
-- Name: transaction_reversals transaction_reversals_initiated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_reversals
    ADD CONSTRAINT transaction_reversals_initiated_by_fkey FOREIGN KEY (initiated_by) REFERENCES public.users(id);


--
-- Name: transaction_reversals transaction_reversals_original_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_reversals
    ADD CONSTRAINT transaction_reversals_original_transaction_id_fkey FOREIGN KEY (original_transaction_id) REFERENCES public.transactions(id);


--
-- Name: transaction_reversals transaction_reversals_reversal_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_reversals
    ADD CONSTRAINT transaction_reversals_reversal_transaction_id_fkey FOREIGN KEY (reversal_transaction_id) REFERENCES public.transactions(id);


--
-- Name: transactions transactions_from_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_from_user_id_fkey FOREIGN KEY (from_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: transactions transactions_to_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_to_user_id_fkey FOREIGN KEY (to_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: user_devices user_devices_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_devices
    ADD CONSTRAINT user_devices_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_sessions user_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_transaction_limits user_transaction_limits_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_transaction_limits
    ADD CONSTRAINT user_transaction_limits_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: users users_referred_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_referred_by_fkey FOREIGN KEY (referred_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: votes votes_poll_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT votes_poll_id_fkey FOREIGN KEY (poll_id) REFERENCES public.polls(id) ON DELETE CASCADE;


--
-- Name: votes votes_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT votes_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.transactions(id) ON DELETE CASCADE;


--
-- Name: votes votes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: wallet_audit_trail wallet_audit_trail_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallet_audit_trail
    ADD CONSTRAINT wallet_audit_trail_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(id);


--
-- Name: wallet_audit_trail wallet_audit_trail_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallet_audit_trail
    ADD CONSTRAINT wallet_audit_trail_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: wallets wallets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: withdrawal_requests withdrawal_requests_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.withdrawal_requests
    ADD CONSTRAINT withdrawal_requests_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: withdrawal_requests withdrawal_requests_bank_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.withdrawal_requests
    ADD CONSTRAINT withdrawal_requests_bank_account_id_fkey FOREIGN KEY (bank_account_id) REFERENCES public.bank_accounts(id) ON DELETE SET NULL;


--
-- Name: withdrawal_requests withdrawal_requests_investment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.withdrawal_requests
    ADD CONSTRAINT withdrawal_requests_investment_id_fkey FOREIGN KEY (investment_id) REFERENCES public.investments(id) ON DELETE CASCADE;


--
-- Name: withdrawal_requests withdrawal_requests_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.withdrawal_requests
    ADD CONSTRAINT withdrawal_requests_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.transactions(id) ON DELETE SET NULL;


--
-- Name: withdrawal_requests withdrawal_requests_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.withdrawal_requests
    ADD CONSTRAINT withdrawal_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: vw_agent_performance; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: -
--

REFRESH MATERIALIZED VIEW public.vw_agent_performance;


--
-- Name: vw_user_dashboard; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: -
--

REFRESH MATERIALIZED VIEW public.vw_user_dashboard;


--
-- PostgreSQL database dump complete
--

\unrestrict 7ubOiXdiHcI1vudSmRxIC07jmv1cu0gIN62jrkfv3fOpgNOiexUBamGXgSpW4bN

