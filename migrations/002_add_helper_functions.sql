-- Migration: 002_add_helper_functions
-- Description: Add database functions and triggers for common operations
-- Author: Winston (Architect)
-- Date: 2025-11-16

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function: Update last_seen_at timestamp on user activity
CREATE OR REPLACE FUNCTION update_user_last_seen()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE users
  SET last_seen_at = now()
  WHERE id = NEW.sender_user_id OR id = NEW.receiver_user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_user_last_seen IS 'Automatically updates user.last_seen_at on payment activity';

-- Trigger: Update user last_seen on payment
CREATE TRIGGER trigger_update_user_last_seen
  AFTER INSERT ON payments
  FOR EACH ROW
  EXECUTE FUNCTION update_user_last_seen();

-- ============================================================================

-- Function: Update channel last_activity_at on payment
CREATE OR REPLACE FUNCTION update_channel_last_activity()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE payment_channels
  SET last_activity_at = now()
  WHERE id = NEW.channel_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_channel_last_activity IS 'Automatically updates channel.last_activity_at on payment';

-- Trigger: Update channel activity timestamp
CREATE TRIGGER trigger_update_channel_activity
  AFTER INSERT ON payments
  FOR EACH ROW
  EXECUTE FUNCTION update_channel_last_activity();

-- ============================================================================

-- Function: Decrement voucher pool unused_count when voucher consumed
CREATE OR REPLACE FUNCTION decrement_voucher_pool_count()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'CONSUMED' AND OLD.status = 'UNUSED' THEN
    UPDATE voucher_pools
    SET unused_count = unused_count - 1
    WHERE id = NEW.pool_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION decrement_voucher_pool_count IS 'Decrements pool.unused_count when voucher consumed';

-- Trigger: Update pool count on voucher consumption
CREATE TRIGGER trigger_decrement_pool_count
  AFTER UPDATE ON vouchers
  FOR EACH ROW
  WHEN (NEW.status = 'CONSUMED' AND OLD.status = 'UNUSED')
  EXECUTE FUNCTION decrement_voucher_pool_count();

-- ============================================================================

-- Function: Validate channel balance invariant
CREATE OR REPLACE FUNCTION validate_channel_balances()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.local_balance + NEW.remote_balance > NEW.capacity THEN
    RAISE EXCEPTION 'Channel balance invariant violated: local_balance (%) + remote_balance (%) > capacity (%)',
      NEW.local_balance, NEW.remote_balance, NEW.capacity;
  END IF;

  IF NEW.local_balance < 0 OR NEW.remote_balance < 0 THEN
    RAISE EXCEPTION 'Channel balances cannot be negative: local_balance (%), remote_balance (%)',
      NEW.local_balance, NEW.remote_balance;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION validate_channel_balances IS 'Enforces: local_balance + remote_balance <= capacity';

-- Trigger: Validate balances on insert/update
CREATE TRIGGER trigger_validate_channel_balances
  BEFORE INSERT OR UPDATE ON payment_channels
  FOR EACH ROW
  EXECUTE FUNCTION validate_channel_balances();

-- ============================================================================

-- Function: Auto-expire vouchers past TTL
CREATE OR REPLACE FUNCTION expire_old_vouchers()
RETURNS INTEGER AS $$
DECLARE
  expired_count INTEGER;
BEGIN
  UPDATE vouchers
  SET status = 'EXPIRED'
  WHERE status = 'UNUSED'
    AND expires_at < now();

  GET DIAGNOSTICS expired_count = ROW_COUNT;
  RETURN expired_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION expire_old_vouchers IS 'Batch expire vouchers past 1-hour TTL - run via cron';

-- ============================================================================

-- Function: Get unused voucher for channel
CREATE OR REPLACE FUNCTION get_unused_voucher(p_channel_id UUID)
RETURNS TABLE (
  voucher_id UUID,
  voucher_vid VARCHAR(255),
  amount_limit BIGINT,
  expires_at TIMESTAMP WITH TIME ZONE,
  mpc_signature BYTEA
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    v.id,
    v.voucher_id,
    v.amount_limit,
    v.expires_at,
    v.mpc_signature
  FROM vouchers v
  WHERE v.channel_id = p_channel_id
    AND v.status = 'UNUSED'
    AND v.expires_at > now()
  ORDER BY v.nonce
  LIMIT 1
  FOR UPDATE SKIP LOCKED; -- Prevent concurrent selection
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_unused_voucher IS 'Atomically retrieve and lock next unused voucher for channel';

-- ============================================================================

-- Function: Calculate channel utilization percentage
CREATE OR REPLACE FUNCTION channel_utilization(p_channel_id UUID)
RETURNS NUMERIC AS $$
DECLARE
  channel_record RECORD;
BEGIN
  SELECT capacity, local_balance, remote_balance
  INTO channel_record
  FROM payment_channels
  WHERE id = p_channel_id;

  IF channel_record.capacity = 0 THEN
    RETURN 0;
  END IF;

  RETURN ((channel_record.local_balance + channel_record.remote_balance)::NUMERIC / channel_record.capacity) * 100;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION channel_utilization IS 'Returns channel utilization as percentage (0-100)';

-- ============================================================================

-- Function: Get settlement candidates (channels exceeding threshold)
CREATE OR REPLACE FUNCTION get_settlement_candidates()
RETURNS TABLE (
  channel_id UUID,
  chain_id VARCHAR(50),
  local_balance BIGINT,
  settlement_threshold BIGINT,
  unsettled_amount BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    pc.id,
    pc.chain_id,
    pc.local_balance,
    pc.settlement_threshold,
    pc.local_balance - COALESCE(
      (SELECT SUM(s.total_amount)
       FROM settlements s
       WHERE s.channel_id = pc.id
         AND s.status = 'CONFIRMED'),
      0
    ) AS unsettled_amount
  FROM payment_channels pc
  WHERE pc.status = 'OPEN'
    AND pc.local_balance >= pc.settlement_threshold
  ORDER BY pc.local_balance DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_settlement_candidates IS 'Find channels exceeding settlement threshold - used by settlement cron';

-- ============================================================================
-- VIEWS
-- ============================================================================

-- View: Channel status with voucher pool info
CREATE OR REPLACE VIEW channel_status_with_vouchers AS
SELECT
  pc.id AS channel_id,
  pc.chain_id,
  pc.status AS channel_status,
  pc.capacity,
  pc.local_balance,
  pc.remote_balance,
  pc.nonce,
  vp.id AS pool_id,
  vp.unused_count AS unused_vouchers,
  vp.voucher_count AS total_vouchers,
  vp.last_backup_at AS pool_last_backup,
  pc.created_at,
  pc.last_activity_at
FROM payment_channels pc
LEFT JOIN voucher_pools vp ON vp.channel_id = pc.id
  AND vp.pool_nonce = (
    SELECT MAX(pool_nonce)
    FROM voucher_pools
    WHERE channel_id = pc.id
  );

COMMENT ON VIEW channel_status_with_vouchers IS 'Combined view of channel state and active voucher pool';

-- ============================================================================

-- View: User payment statistics
CREATE OR REPLACE VIEW user_payment_stats AS
SELECT
  u.id AS user_id,
  u.ethereum_address,
  COUNT(DISTINCT pc.id) AS total_channels,
  COUNT(DISTINCT CASE WHEN pc.status = 'OPEN' THEN pc.id END) AS open_channels,
  COUNT(p.id) AS total_payments,
  SUM(CASE WHEN p.sender_user_id = u.id THEN p.amount ELSE 0 END) AS total_sent,
  SUM(CASE WHEN p.receiver_user_id = u.id THEN p.amount ELSE 0 END) AS total_received,
  AVG(p.latency_ms) AS avg_latency_ms
FROM users u
LEFT JOIN payment_channels pc ON pc.opener_user_id = u.id OR pc.counterparty_user_id = u.id
LEFT JOIN payments p ON p.sender_user_id = u.id OR p.receiver_user_id = u.id
GROUP BY u.id, u.ethereum_address;

COMMENT ON VIEW user_payment_stats IS 'Aggregated payment statistics per user';

-- ============================================================================
-- GRANT PERMISSIONS (for application user)
-- ============================================================================

-- Note: Create application user with limited permissions in production
-- CREATE USER nillion_app WITH PASSWORD '<secure-password>';
-- GRANT CONNECT ON DATABASE nillion_pay TO nillion_app;
-- GRANT USAGE ON SCHEMA public TO nillion_app;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO nillion_app;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO nillion_app;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO nillion_app;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

INSERT INTO schema_migrations (version)
VALUES ('002-add-helper-functions');
