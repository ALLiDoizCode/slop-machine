-- Migration: 001_create_base_tables
-- Description: Create core tables for users, payment channels, and vouchers
-- Author: Winston (Architect)
-- Date: 2025-11-16

-- ============================================================================
-- USERS TABLE
-- ============================================================================

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ethereum_address VARCHAR(42) NOT NULL UNIQUE,
  bitcoin_address VARCHAR(100),
  solana_address VARCHAR(44),
  nillion_user_id VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  last_seen_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),

  -- Constraints
  CONSTRAINT users_ethereum_address_format CHECK (ethereum_address ~ '^0x[a-fA-F0-9]{40}$')
);

-- Indexes
CREATE INDEX idx_users_ethereum_address ON users(ethereum_address);
CREATE INDEX idx_users_last_seen ON users(last_seen_at DESC);
CREATE INDEX idx_users_nillion ON users(nillion_user_id) WHERE nillion_user_id IS NOT NULL;

COMMENT ON TABLE users IS 'Users identified by blockchain wallet addresses across all three chains';
COMMENT ON COLUMN users.ethereum_address IS 'Primary identity - Ethereum Optimism wallet (0x-prefixed hex)';
COMMENT ON COLUMN users.nillion_user_id IS 'Assigned after first Nillion MPC operation';

-- ============================================================================
-- PAYMENT CHANNELS TABLE
-- ============================================================================

CREATE TABLE payment_channels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chain_id VARCHAR(50) NOT NULL,
  channel_id VARCHAR(255) NOT NULL UNIQUE,
  opener_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  counterparty_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  status VARCHAR(20) NOT NULL DEFAULT 'OPENING',
  capacity BIGINT NOT NULL CHECK (capacity > 0),
  local_balance BIGINT NOT NULL DEFAULT 0 CHECK (local_balance >= 0),
  remote_balance BIGINT NOT NULL DEFAULT 0 CHECK (remote_balance >= 0),
  nonce INTEGER NOT NULL DEFAULT 0 CHECK (nonce >= 0),
  settlement_threshold BIGINT NOT NULL CHECK (settlement_threshold > 0),
  on_chain_tx_hash VARCHAR(66) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  last_activity_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  closed_at TIMESTAMP WITH TIME ZONE,
  metadata JSONB DEFAULT '{}'::jsonb,

  -- Constraints
  CONSTRAINT payment_channels_chain_id_check CHECK (
    chain_id IN ('ETHEREUM_OPTIMISM', 'BITCOIN_LIGHTNING', 'SOLANA')
  ),
  CONSTRAINT payment_channels_status_check CHECK (
    status IN ('OPENING', 'OPEN', 'CLOSING', 'CLOSED', 'DISPUTED')
  ),
  CONSTRAINT payment_channels_balances_check CHECK (
    local_balance + remote_balance <= capacity
  ),
  CONSTRAINT payment_channels_different_users CHECK (
    opener_user_id != counterparty_user_id
  ),
  CONSTRAINT payment_channels_closed_at_check CHECK (
    (status = 'CLOSED' AND closed_at IS NOT NULL) OR
    (status != 'CLOSED' AND closed_at IS NULL)
  )
);

-- Indexes
CREATE INDEX idx_channels_opener ON payment_channels(opener_user_id);
CREATE INDEX idx_channels_counterparty ON payment_channels(counterparty_user_id);
CREATE INDEX idx_channels_status ON payment_channels(status);
CREATE INDEX idx_channels_chain ON payment_channels(chain_id);
CREATE INDEX idx_channels_last_activity ON payment_channels(last_activity_at DESC);

-- Partial index for settlement threshold monitoring (hot query)
CREATE INDEX idx_channels_settlement_threshold ON payment_channels(local_balance, settlement_threshold)
  WHERE status = 'OPEN';

-- GIN index for JSONB metadata queries
CREATE INDEX idx_channels_metadata ON payment_channels USING GIN(metadata);

COMMENT ON TABLE payment_channels IS 'Off-chain payment channels on Ethereum, Bitcoin, or Solana';
COMMENT ON COLUMN payment_channels.nonce IS 'State update counter - prevents replay attacks';
COMMENT ON COLUMN payment_channels.settlement_threshold IS 'Monetary threshold for automatic on-chain settlement';
COMMENT ON COLUMN payment_channels.metadata IS 'Chain-specific data (Vector address, LN channel point, etc.)';

-- ============================================================================
-- VOUCHER POOLS TABLE
-- ============================================================================

CREATE TABLE voucher_pools (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID NOT NULL REFERENCES payment_channels(id) ON DELETE CASCADE,
  pool_nonce INTEGER NOT NULL DEFAULT 0 CHECK (pool_nonce >= 0),
  voucher_count INTEGER NOT NULL DEFAULT 100 CHECK (voucher_count = 100),
  unused_count INTEGER NOT NULL DEFAULT 100 CHECK (unused_count >= 0 AND unused_count <= 100),
  nillion_storage_id VARCHAR(255) NOT NULL,
  last_backup_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),

  -- Unique constraint: one active pool per channel
  UNIQUE(channel_id, pool_nonce)
);

-- Indexes
CREATE INDEX idx_voucher_pools_channel ON voucher_pools(channel_id);
CREATE INDEX idx_voucher_pools_backup ON voucher_pools(last_backup_at DESC)
  WHERE last_backup_at < now() - INTERVAL '24 hours'; -- Find stale backups

COMMENT ON TABLE voucher_pools IS 'Collection of 100 pre-signed Nillion MPC vouchers per channel';
COMMENT ON COLUMN voucher_pools.pool_nonce IS 'Increments when pool regenerated (every ~1 hour)';
COMMENT ON COLUMN voucher_pools.nillion_storage_id IS 'Nillion Private Storage backup reference for crash recovery';

-- ============================================================================
-- VOUCHERS TABLE
-- ============================================================================

CREATE TABLE vouchers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  voucher_id VARCHAR(255) NOT NULL UNIQUE,
  pool_id UUID NOT NULL REFERENCES voucher_pools(id) ON DELETE CASCADE,
  channel_id UUID NOT NULL REFERENCES payment_channels(id) ON DELETE CASCADE,
  nonce INTEGER NOT NULL CHECK (nonce >= 0 AND nonce < 100),
  amount_limit BIGINT NOT NULL CHECK (amount_limit > 0),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  mpc_signature BYTEA NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'UNUSED',
  consumed_by_payment_id UUID, -- FK added after payments table created
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),

  -- Constraints
  UNIQUE(pool_id, nonce),
  CONSTRAINT vouchers_status_check CHECK (
    status IN ('UNUSED', 'CONSUMED', 'EXPIRED')
  ),
  CONSTRAINT vouchers_consumed_check CHECK (
    (status = 'CONSUMED' AND consumed_by_payment_id IS NOT NULL) OR
    (status != 'CONSUMED' AND consumed_by_payment_id IS NULL)
  )
);

-- Indexes
CREATE INDEX idx_vouchers_pool ON vouchers(pool_id);
CREATE INDEX idx_vouchers_channel ON vouchers(channel_id);

-- Partial index for hot path: finding unused vouchers
CREATE INDEX idx_vouchers_channel_unused ON vouchers(channel_id, nonce)
  WHERE status = 'UNUSED';

-- Partial index for expiry cleanup job
CREATE INDEX idx_vouchers_expiry ON vouchers(expires_at)
  WHERE status = 'UNUSED';

COMMENT ON TABLE vouchers IS 'Individual pre-signed Nillion MPC vouchers (100 per pool)';
COMMENT ON COLUMN vouchers.nonce IS 'Voucher sequence 0-99 within pool';
COMMENT ON COLUMN vouchers.amount_limit IS 'Maximum payment this voucher can authorize';
COMMENT ON COLUMN vouchers.expires_at IS '1-hour TTL from creation';
COMMENT ON COLUMN vouchers.mpc_signature IS 'Binary Nillion MPC signature (BYTEA)';

-- ============================================================================
-- PAYMENTS TABLE
-- ============================================================================

CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID NOT NULL REFERENCES payment_channels(id) ON DELETE RESTRICT,
  voucher_id UUID NOT NULL REFERENCES vouchers(id) ON DELETE RESTRICT,
  sender_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  receiver_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  amount BIGINT NOT NULL CHECK (amount > 0),
  nonce INTEGER NOT NULL CHECK (nonce > 0),
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  latency_ms INTEGER NOT NULL CHECK (latency_ms >= 0),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  completed_at TIMESTAMP WITH TIME ZONE,
  error_message TEXT,

  -- Constraints
  CONSTRAINT payments_status_check CHECK (
    status IN ('PENDING', 'COMPLETED', 'FAILED')
  ),
  CONSTRAINT payments_completed_check CHECK (
    (status = 'COMPLETED' AND completed_at IS NOT NULL AND error_message IS NULL) OR
    (status = 'FAILED' AND error_message IS NOT NULL) OR
    (status = 'PENDING')
  )
);

-- Indexes
CREATE INDEX idx_payments_channel ON payments(channel_id, created_at DESC);
CREATE INDEX idx_payments_sender ON payments(sender_user_id, created_at DESC);
CREATE INDEX idx_payments_receiver ON payments(receiver_user_id, created_at DESC);
CREATE INDEX idx_payments_created_at ON payments(created_at DESC);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_voucher ON payments(voucher_id);

-- Partial index for unsettled payments query
CREATE INDEX idx_payments_unsettled ON payments(channel_id, created_at)
  WHERE status = 'COMPLETED';

COMMENT ON TABLE payments IS 'Individual micropayments within payment channels';
COMMENT ON COLUMN payments.nonce IS 'Channel state nonce AFTER this payment';
COMMENT ON COLUMN payments.latency_ms IS 'End-to-end processing time (target <100ms)';

-- Add foreign key to vouchers table (now that payments exists)
ALTER TABLE vouchers
  ADD CONSTRAINT vouchers_consumed_by_payment_fk
  FOREIGN KEY (consumed_by_payment_id)
  REFERENCES payments(id)
  ON DELETE SET NULL;

-- ============================================================================
-- SETTLEMENTS TABLE
-- ============================================================================

CREATE TABLE settlements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID NOT NULL REFERENCES payment_channels(id) ON DELETE RESTRICT,
  chain_id VARCHAR(50) NOT NULL,
  settlement_type VARCHAR(30) NOT NULL,
  payment_count INTEGER NOT NULL DEFAULT 0 CHECK (payment_count >= 0),
  total_amount BIGINT NOT NULL CHECK (total_amount >= 0),
  on_chain_tx_hash VARCHAR(66) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  gas_used BIGINT CHECK (gas_used >= 0),
  gas_cost BIGINT CHECK (gas_cost >= 0),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  confirmed_at TIMESTAMP WITH TIME ZONE,
  error_message TEXT,

  -- Constraints
  CONSTRAINT settlements_chain_id_check CHECK (
    chain_id IN ('ETHEREUM_OPTIMISM', 'BITCOIN_LIGHTNING', 'SOLANA')
  ),
  CONSTRAINT settlements_type_check CHECK (
    settlement_type IN ('MONETARY_THRESHOLD', 'MANUAL', 'CHANNEL_CLOSURE')
  ),
  CONSTRAINT settlements_status_check CHECK (
    status IN ('PENDING', 'CONFIRMED', 'FAILED')
  ),
  CONSTRAINT settlements_confirmed_check CHECK (
    (status = 'CONFIRMED' AND confirmed_at IS NOT NULL) OR
    (status != 'CONFIRMED' AND confirmed_at IS NULL)
  )
);

-- Indexes
CREATE INDEX idx_settlements_channel ON settlements(channel_id, created_at DESC);
CREATE INDEX idx_settlements_status ON settlements(status);
CREATE INDEX idx_settlements_chain ON settlements(chain_id);
CREATE INDEX idx_settlements_created_at ON settlements(created_at DESC);

-- Partial index for pending settlements monitoring
CREATE INDEX idx_settlements_pending ON settlements(created_at)
  WHERE status = 'PENDING';

COMMENT ON TABLE settlements IS 'On-chain settlements triggered by monetary thresholds';
COMMENT ON COLUMN settlements.settlement_type IS 'Trigger: MONETARY_THRESHOLD ($100/$1000) | MANUAL | CHANNEL_CLOSURE';
COMMENT ON COLUMN settlements.payment_count IS 'Number of payments included in this batch settlement';

-- ============================================================================
-- CROSS-CHAIN SWAPS TABLE
-- ============================================================================

CREATE TABLE cross_chain_swaps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_chain_id VARCHAR(50) NOT NULL,
  destination_chain_id VARCHAR(50) NOT NULL,
  source_channel_id UUID NOT NULL REFERENCES payment_channels(id) ON DELETE RESTRICT,
  destination_channel_id UUID NOT NULL REFERENCES payment_channels(id) ON DELETE RESTRICT,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  source_amount BIGINT NOT NULL CHECK (source_amount > 0),
  destination_amount BIGINT NOT NULL CHECK (destination_amount > 0),
  exchange_rate NUMERIC(20, 10) NOT NULL CHECK (exchange_rate > 0),
  htlc_secret BYTEA NOT NULL,
  htlc_hash VARCHAR(64) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'INITIATED',
  source_tx_hash VARCHAR(66),
  destination_tx_hash VARCHAR(66),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  completed_at TIMESTAMP WITH TIME ZONE,
  error_message TEXT,

  -- Constraints
  CONSTRAINT swaps_chain_id_check CHECK (
    source_chain_id IN ('ETHEREUM_OPTIMISM', 'BITCOIN_LIGHTNING', 'SOLANA') AND
    destination_chain_id IN ('ETHEREUM_OPTIMISM', 'BITCOIN_LIGHTNING', 'SOLANA')
  ),
  CONSTRAINT swaps_different_chains CHECK (
    source_chain_id != destination_chain_id
  ),
  CONSTRAINT swaps_status_check CHECK (
    status IN ('INITIATED', 'SOURCE_LOCKED', 'DEST_LOCKED', 'COMPLETED', 'REFUNDED', 'FAILED')
  ),
  CONSTRAINT swaps_completed_check CHECK (
    (status = 'COMPLETED' AND completed_at IS NOT NULL AND source_tx_hash IS NOT NULL AND destination_tx_hash IS NOT NULL) OR
    (status != 'COMPLETED')
  ),
  CONSTRAINT swaps_expiry_future CHECK (
    expires_at > created_at
  )
);

-- Indexes
CREATE INDEX idx_swaps_user ON cross_chain_swaps(user_id, created_at DESC);
CREATE INDEX idx_swaps_status ON cross_chain_swaps(status);
CREATE INDEX idx_swaps_source_channel ON cross_chain_swaps(source_channel_id);
CREATE INDEX idx_swaps_dest_channel ON cross_chain_swaps(destination_channel_id);
CREATE INDEX idx_swaps_created_at ON cross_chain_swaps(created_at DESC);

-- Partial index for timeout cleanup job
CREATE INDEX idx_swaps_expiry ON cross_chain_swaps(expires_at)
  WHERE status IN ('INITIATED', 'SOURCE_LOCKED', 'DEST_LOCKED');

COMMENT ON TABLE cross_chain_swaps IS 'Atomic swaps between two blockchains using HTLCs';
COMMENT ON COLUMN cross_chain_swaps.htlc_secret IS 'Preimage for HTLC unlock (kept secret until reveal)';
COMMENT ON COLUMN cross_chain_swaps.htlc_hash IS 'SHA256(htlc_secret) - public, used in HTLC contracts';
COMMENT ON COLUMN cross_chain_swaps.expires_at IS 'HTLC timeout (30 minutes) - triggers automatic rollback';

-- ============================================================================
-- PERFORMANCE METRICS TABLE (TimescaleDB Hypertable)
-- ============================================================================

CREATE TABLE performance_metrics (
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
  metric_type VARCHAR(20) NOT NULL,
  chain_id VARCHAR(50),
  value NUMERIC(12, 4) NOT NULL,
  p50 NUMERIC(12, 4),
  p95 NUMERIC(12, 4),
  p99 NUMERIC(12, 4),

  -- Constraints
  CONSTRAINT metrics_type_check CHECK (
    metric_type IN ('LATENCY', 'THROUGHPUT', 'SUCCESS_RATE')
  ),
  CONSTRAINT metrics_chain_check CHECK (
    chain_id IS NULL OR chain_id IN ('ETHEREUM_OPTIMISM', 'BITCOIN_LIGHTNING', 'SOLANA')
  ),
  CONSTRAINT metrics_value_positive CHECK (value >= 0),
  CONSTRAINT metrics_percentiles_check CHECK (
    (p50 IS NULL AND p95 IS NULL AND p99 IS NULL) OR
    (p50 <= p95 AND p95 <= p99)
  )
);

-- Convert to TimescaleDB hypertable (partitioned by time)
SELECT create_hypertable(
  'performance_metrics',
  'timestamp',
  chunk_time_interval => INTERVAL '1 day',
  if_not_exists => TRUE
);

-- Indexes
CREATE INDEX idx_metrics_time_type ON performance_metrics(timestamp DESC, metric_type);
CREATE INDEX idx_metrics_chain_time ON performance_metrics(chain_id, timestamp DESC)
  WHERE chain_id IS NOT NULL;

COMMENT ON TABLE performance_metrics IS 'Time-series performance data (latency, throughput, success rate)';
COMMENT ON COLUMN performance_metrics.p95 IS '95th percentile latency - target <100ms';

-- ============================================================================
-- CONTINUOUS AGGREGATES (TimescaleDB)
-- ============================================================================

-- 5-minute rollup for dashboard queries
CREATE MATERIALIZED VIEW metrics_5min
WITH (timescaledb.continuous) AS
SELECT
  time_bucket('5 minutes', timestamp) AS bucket,
  metric_type,
  chain_id,
  AVG(value) AS avg_value,
  MAX(value) AS max_value,
  MIN(value) AS min_value,
  AVG(p95) AS avg_p95,
  COUNT(*) AS sample_count
FROM performance_metrics
GROUP BY bucket, metric_type, chain_id
WITH NO DATA;

-- Refresh policy: update every 5 minutes
SELECT add_continuous_aggregate_policy(
  'metrics_5min',
  start_offset => INTERVAL '1 hour',
  end_offset => INTERVAL '5 minutes',
  schedule_interval => INTERVAL '5 minutes'
);

COMMENT ON MATERIALIZED VIEW metrics_5min IS '5-minute aggregated metrics for faster dashboard queries';

-- 1-hour rollup for historical analysis
CREATE MATERIALIZED VIEW metrics_1hour
WITH (timescaledb.continuous) AS
SELECT
  time_bucket('1 hour', timestamp) AS bucket,
  metric_type,
  chain_id,
  AVG(value) AS avg_value,
  MAX(value) AS max_value,
  MIN(value) AS min_value,
  AVG(p95) AS avg_p95,
  COUNT(*) AS sample_count
FROM performance_metrics
GROUP BY bucket, metric_type, chain_id
WITH NO DATA;

-- Refresh policy: update every hour
SELECT add_continuous_aggregate_policy(
  'metrics_1hour',
  start_offset => INTERVAL '1 day',
  end_offset => INTERVAL '1 hour',
  schedule_interval => INTERVAL '1 hour'
);

-- ============================================================================
-- RETENTION POLICIES (TimescaleDB)
-- ============================================================================

-- Keep raw metrics for 7 days (fine-grained)
SELECT add_retention_policy('performance_metrics', INTERVAL '7 days');

-- Keep 5-minute aggregates for 90 days
SELECT add_retention_policy('metrics_5min', INTERVAL '90 days');

-- Keep 1-hour aggregates for 1 year
SELECT add_retention_policy('metrics_1hour', INTERVAL '1 year');

-- ============================================================================
-- INITIAL DATA
-- ============================================================================

-- Insert system user (for internal operations)
INSERT INTO users (id, ethereum_address, created_at)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  '0x0000000000000000000000000000000000000000',
  now()
) ON CONFLICT (ethereum_address) DO NOTHING;

COMMENT ON TABLE users IS 'System user at 0x0000... for internal operations';
