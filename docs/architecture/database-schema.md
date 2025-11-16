# Database Schema

## PostgreSQL Tables

```sql
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ethereum_address VARCHAR(42) NOT NULL UNIQUE,
  bitcoin_address VARCHAR(100),
  solana_address VARCHAR(44),
  nillion_user_id VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  last_seen_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE INDEX idx_users_ethereum_address ON users(ethereum_address);

-- Payment channels table
CREATE TABLE payment_channels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chain_id VARCHAR(50) NOT NULL,
  channel_id VARCHAR(255) NOT NULL UNIQUE,
  opener_user_id UUID NOT NULL REFERENCES users(id),
  counterparty_user_id UUID NOT NULL REFERENCES users(id),
  status VARCHAR(20) NOT NULL,
  capacity BIGINT NOT NULL CHECK (capacity > 0),
  local_balance BIGINT NOT NULL DEFAULT 0 CHECK (local_balance >= 0),
  remote_balance BIGINT NOT NULL DEFAULT 0 CHECK (remote_balance >= 0),
  nonce INTEGER NOT NULL DEFAULT 0,
  settlement_threshold BIGINT NOT NULL,
  on_chain_tx_hash VARCHAR(66) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  last_activity_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  closed_at TIMESTAMP WITH TIME ZONE,
  metadata JSONB,

  CONSTRAINT check_balances CHECK (local_balance + remote_balance <= capacity)
);

CREATE INDEX idx_channels_opener ON payment_channels(opener_user_id);
CREATE INDEX idx_channels_status ON payment_channels(status);
CREATE INDEX idx_channels_settlement_threshold ON payment_channels(local_balance, settlement_threshold)
  WHERE status = 'OPEN';

-- Voucher pools table
CREATE TABLE voucher_pools (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID NOT NULL REFERENCES payment_channels(id) ON DELETE CASCADE,
  pool_nonce INTEGER NOT NULL DEFAULT 0,
  voucher_count INTEGER NOT NULL DEFAULT 100,
  unused_count INTEGER NOT NULL DEFAULT 100 CHECK (unused_count >= 0),
  nillion_storage_id VARCHAR(255) NOT NULL,
  last_backup_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),

  UNIQUE(channel_id, pool_nonce)
);

-- Vouchers table
CREATE TABLE vouchers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  voucher_id VARCHAR(255) NOT NULL UNIQUE,
  pool_id UUID NOT NULL REFERENCES voucher_pools(id) ON DELETE CASCADE,
  channel_id UUID NOT NULL REFERENCES payment_channels(id) ON DELETE CASCADE,
  nonce INTEGER NOT NULL,
  amount_limit BIGINT NOT NULL CHECK (amount_limit > 0),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  mpc_signature BYTEA NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'UNUSED',
  consumed_by_payment_id UUID REFERENCES payments(id),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),

  UNIQUE(pool_id, nonce)
);

CREATE INDEX idx_vouchers_channel_status ON vouchers(channel_id, status)
  WHERE status = 'UNUSED';

-- Payments table
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID NOT NULL REFERENCES payment_channels(id),
  voucher_id UUID NOT NULL REFERENCES vouchers(id),
  sender_user_id UUID NOT NULL REFERENCES users(id),
  receiver_user_id UUID NOT NULL REFERENCES users(id),
  amount BIGINT NOT NULL CHECK (amount > 0),
  nonce INTEGER NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  latency_ms INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  completed_at TIMESTAMP WITH TIME ZONE,
  error_message TEXT
);

CREATE INDEX idx_payments_channel ON payments(channel_id, created_at DESC);

-- Settlements table
CREATE TABLE settlements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID NOT NULL REFERENCES payment_channels(id),
  chain_id VARCHAR(50) NOT NULL,
  settlement_type VARCHAR(30) NOT NULL,
  payment_count INTEGER NOT NULL DEFAULT 0,
  total_amount BIGINT NOT NULL CHECK (total_amount >= 0),
  on_chain_tx_hash VARCHAR(66) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  gas_used BIGINT,
  gas_cost BIGINT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  confirmed_at TIMESTAMP WITH TIME ZONE,
  error_message TEXT
);

-- Cross-chain swaps table
CREATE TABLE cross_chain_swaps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_chain_id VARCHAR(50) NOT NULL,
  destination_chain_id VARCHAR(50) NOT NULL,
  source_channel_id UUID NOT NULL REFERENCES payment_channels(id),
  destination_channel_id UUID NOT NULL REFERENCES payment_channels(id),
  user_id UUID NOT NULL REFERENCES users(id),
  source_amount BIGINT NOT NULL CHECK (source_amount > 0),
  destination_amount BIGINT NOT NULL CHECK (destination_amount > 0),
  exchange_rate NUMERIC(20, 10) NOT NULL,
  htlc_secret BYTEA NOT NULL,
  htlc_hash VARCHAR(64) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'INITIATED',
  source_tx_hash VARCHAR(66),
  destination_tx_hash VARCHAR(66),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  completed_at TIMESTAMP WITH TIME ZONE
);

-- Performance metrics table (TimescaleDB hypertable)
CREATE TABLE performance_metrics (
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
  metric_type VARCHAR(20) NOT NULL,
  chain_id VARCHAR(50),
  value NUMERIC(12, 4) NOT NULL,
  p50 NUMERIC(12, 4),
  p95 NUMERIC(12, 4),
  p99 NUMERIC(12, 4)
);

-- Convert to TimescaleDB hypertable
SELECT create_hypertable('performance_metrics', 'timestamp',
  chunk_time_interval => INTERVAL '1 day');

CREATE INDEX idx_metrics_time_type ON performance_metrics(timestamp DESC, metric_type);
```

## Redis Key Structure

```