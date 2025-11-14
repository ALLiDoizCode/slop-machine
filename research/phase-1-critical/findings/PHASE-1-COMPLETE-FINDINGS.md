# Phase 1 Complete Findings: Apus Integration + Payment Gating

**Phase:** 1 (Critical Path)
**Status:** Complete
**Date:** 2025-11-13
**Questions Covered:** Q1-Q5 (Apus), Q8, Q15 (Payment Security)

---

## Q1: Complete Apus SDK API Surface

### Key Findings

**Installation:**
```lua
.load-blueprint apm
apm.install "@apus/ai"
ApusAI = require('@apus/ai')
```

**Core Functions:**
1. `ApusAI.initialize()` - Auto-called, rarely needed
2. `ApusAI.infer(prompt, [options], [callback])` - Main inference function
3. `ApusAI.getBalance()` - Check credit balance

**Router Process:** `TED2PpCVx0KbkQtzEYBo0TRAO-HPJlpCMmUzch9ZL2g`

**Authentication:** Credit-based system (1 credit = 1 inference call)

### Critical Details
- ~50 second latency per call
- Default: 5 test credits per process
- Max tokens: 8,192 (default: 2,048)
- Model: Gemma3-27B (only model currently available)

**See:** `Q01-apus-sdk-api.md` for complete details

---

## Q2: Available AI Models

### Key Findings

**Currently Available:**
| Model | Size | Context Window | Use Case |
|-------|------|----------------|----------|
| Gemma3-27B | 27 billion parameters | 8,192 tokens | General purpose, text generation, reasoning |

**Model Capabilities:**
- Text generation and completion
- Question answering
- Translation
- Reasoning tasks
- Conversation (via X-Session)

### Limitations
- ❌ No vision models currently
- ❌ No code-specialized models
- ❌ No embedding models
- ❌ No fine-tuned variants

### Performance Characteristics
- **Latency:** ~50 seconds per inference
- **Throughput:** Sequential processing (no batching from client side)
- **Quality:** Production-grade LLM suitable for autonomous agents
- **Determinism:** GPU attestation ensures verifiable computation

### Future Roadmap
- Documentation indicates Apus Network vision includes multiple models
- "Catalog of supported models" mentioned but currently singular
- Expect expansion as network matures

---

## Q3: Apus Pricing and Cost Structure

### Key Findings

**Credit System:**
```
1 Credit = 1 Inference Call
Credit Price = Dynamic based on $APUS token exchange rate
```

**Purchasing Credits:**
```lua
ao.send({
    Target = "mqBYxpDsolZmJyBdTK8TJp_ftOuIUXVYcSQ8MYZdJg0", -- $APUS Token
    Recipient = "TED2PpCVx0KbkQtzEYBo0TRAO-HPJlpCMmUzch9ZL2g", -- Router
    Action = "Transfer",
    Quantity = "1000000000000", -- 1 $APUS (10^12 Armstrongs)
    ["X-Reason"] = "Buy-Credits"
})
```

**Default Allocation:**
- New processes: 5,000,000,000,000 units = 5 credits
- Hackathon participants: Apply via Discord for more credits

### Cost Factors

**Per-Call Costs:**
1. **Model size:** Currently only Gemma3-27B (27B params)
2. **Input tokens:** Included in prompt
3. **Output tokens:** Controlled by `max_tokens` parameter
4. **Compute time:** ~50 seconds per inference

**Cost Optimization Strategies:**
1. Lower `max_tokens` for shorter responses
2. Use `temperature=0.0` for deterministic (possibly faster) responses
3. Batch multiple questions in single prompt when possible
4. Cache common responses at application layer
5. Use `X-Session` to maintain conversation context (avoids re-sending history)

### Pricing Model Analysis

**Current Model (Hackathon/Beta):**
- Free test credits for development
- Token-based purchasing for production
- No tiered pricing or subscriptions

**Production Considerations:**
- $APUS token price volatility affects real costs
- No prepaid discounts or volume pricing documented
- Credits non-transferable (cannot resell or trade)

### Budget Planning

**Example Cost Calculation:**
```
Assumed $APUS price: $0.10 per token
1 $APUS token (1,000,000,000,000 Armstrongs) buys X credits
If exchange rate = 1 $APUS = 1 credit:
  Cost per inference = $0.10

1000 inferences = $100
10,000 inferences = $1,000
```

**Note:** Actual exchange rate not publicly documented - must query Router Process state

---

## Q4: Apus Performance Limits and Constraints

### Hard Limits

| Limit | Value | Impact |
|-------|-------|--------|
| Max input+output tokens | 8,192 | Cannot process very long documents |
| Max output tokens | 8,192 | Responses truncated if exceeded |
| Default output tokens | 2,048 | Must explicitly request more |
| Min output tokens | 1 | Can request very short responses |
| Concurrent requests/process | Unknown | Likely sequential |
| Inference timeout | ~50 seconds | Built-in processing time |
| Max timeout | Unknown | May fail if computation exceeds limit |

### Performance Characteristics

**Latency:**
- Average: ~50 seconds per inference call
- Variance: Unknown (needs benchmarking)
- No streaming: Full response returned at once

**Throughput:**
- Sequential processing from client perspective
- No documented batch API
- One request at a time per callback chain

**Rate Limits:**
- Credit exhaustion is primary limit
- No documented requests-per-second limit
- No documented daily/hourly caps beyond credits

### Concurrency Patterns

**Single Process:**
```lua
-- Sequential (blocking)
ApusAI.infer("Question 1")  -- Waits ~50s
ApusAI.infer("Question 2")  -- Waits ~50s
-- Total: ~100s

-- Parallel (callback-based)
ApusAI.infer("Question 1", {}, function(err, res1)
    -- Handle res1
end)
ApusAI.infer("Question 2", {}, function(err, res2)
    -- Handle res2
end)
-- Both sent immediately, responses arrive ~50s later
```

**Multiple Processes:**
- Each process can run inferences independently
- True parallelism possible across processes
- Credit balances are per-process (isolated)

### Reliability Characteristics

**Error Scenarios:**
1. Insufficient credits → Error response
2. Invalid prompt → Error response
3. Router Process unavailable → No response (timeout)
4. Malformed X-Options → Error response
5. Network issues → Message delivery failure

**No Documented SLA:**
- Uptime guarantees not specified
- Response time guarantees not specified
- Error rate expectations not specified

---

## Q5: Apus Integration with AO Message Passing

### Message Passing Architecture

**Flow Diagram:**
```
Your Process → Infer Message → Router Process → GPU Worker → Router Process → Response Message → Your Process
```

**Asynchronous by Default:**
- All Apus calls use AO message passing
- No synchronous HTTP APIs
- Responses arrive via incoming messages

### Integration Patterns

#### Pattern 1: Simple Callback (Recommended for Most Use Cases)
```lua
local ApusAI = require('@apus/ai')

Handlers.add("user-query",
    Handlers.utils.hasMatchingTag("Action", "Query"),
    function(msg)
        ApusAI.infer(msg.Data, {max_tokens = 500}, function(err, result)
            if err then
                ao.send({Target = msg.From, Action = "Error", Error = err.message})
                return
            end
            ao.send({Target = msg.From, Action = "Response", Data = result})
        end)
    end
)
```

#### Pattern 2: Manual Message Handling (Advanced Control)
```lua
-- Send inference request
Handlers.add("start-inference",
    Handlers.utils.hasMatchingTag("Action", "StartInference"),
    function(msg)
        local requestId = msg.Id .. "-" .. msg.Timestamp

        ao.send({
            Target = "TED2PpCVx0KbkQtzEYBo0TRAO-HPJlpCMmUzch9ZL2g",
            Action = "Infer",
            Data = msg.Data,
            ["X-Reference"] = requestId
        })

        -- Store request tracking
        PendingRequests = PendingRequests or {}
        PendingRequests[requestId] = {
            user = msg.From,
            prompt = msg.Data,
            timestamp = msg.Timestamp
        }
    end
)

-- Receive inference response
Handlers.add("accept-inference",
    { Action = "Infer-Response" },
    function(msg)
        local requestId = msg["X-Reference"]
        local pending = PendingRequests[requestId]

        if not pending then
            return  -- Ignore unknown responses
        end

        if msg.Code then
            -- Handle error
            ao.send({
                Target = pending.user,
                Action = "Error",
                Error = msg.Data
            })
        else
            -- Parse success
            local response = json.decode(msg.Data)
            ao.send({
                Target = pending.user,
                Action = "InferenceComplete",
                Data = response.result,
                Attestation = response.attestation
            })
        end

        -- Cleanup
        PendingRequests[requestId] = nil
    end
)
```

#### Pattern 3: State Management During Inference
```lua
-- Track inference state
InferenceJobs = InferenceJobs or {}

Handlers.add("long-running-task",
    Handlers.utils.hasMatchingTag("Action", "StartTask"),
    function(msg)
        local jobId = msg.Id

        InferenceJobs[jobId] = {
            status = "pending",
            user = msg.From,
            prompt = msg.Data,
            startTime = msg.Timestamp
        }

        ApusAI.infer(msg.Data, {}, function(err, result)
            if err then
                InferenceJobs[jobId].status = "failed"
                InferenceJobs[jobId].error = err.message
            else
                InferenceJobs[jobId].status = "complete"
                InferenceJobs[jobId].result = result
                InferenceJobs[jobId].completedTime = msg.Timestamp
            end

            -- Notify user
            ao.send({
                Target = InferenceJobs[jobId].user,
                Action = "TaskUpdate",
                JobId = jobId,
                Status = InferenceJobs[jobId].status,
                Data = result or err.message
            })
        end)
    end
)

-- Query job status
Handlers.add("check-job",
    Handlers.utils.hasMatchingTag("Action", "CheckJob"),
    function(msg)
        local jobId = msg.JobId
        local job = InferenceJobs[jobId]

        if not job then
            ao.send({Target = msg.From, Action = "Error", Error = "Job not found"})
            return
        end

        ao.send({
            Target = msg.From,
            Action = "JobStatus",
            JobId = jobId,
            Status = job.status,
            Data = json.encode(job)
        })
    end
)
```

### Synchronous vs Asynchronous Handling

**Library Default (Pseudo-Synchronous):**
- `ApusAI.infer("prompt")` without callback blocks handler execution
- Response logged to console when complete
- Not recommended for production (blocks other message processing)

**Callback Pattern (True Async):**
- Handler returns immediately
- Callback invoked when response arrives
- Other messages can be processed during inference
- **Recommended for production**

### Error Recovery and Retries

**Strategy 1: Client-Side Retry**
```lua
local function inferWithRetry(prompt, maxAttempts, callback)
    local attempts = 0

    local function attempt()
        attempts = attempts + 1

        ApusAI.infer(prompt, {}, function(err, result)
            if err and attempts < maxAttempts then
                print("Retry " .. attempts .. "/" .. maxAttempts)
                attempt()  -- Retry
            else
                callback(err, result)  -- Final result or failure
            end
        end)
    end

    attempt()
end

-- Usage
inferWithRetry("What is Arweave?", 3, function(err, result)
    if err then
        print("Failed after 3 attempts: " .. err.message)
    else
        print("Success: " .. result)
    end
end)
```

**Strategy 2: Timeout Handling**
```lua
-- Track request timing
local requestStart = msg.Timestamp

ApusAI.infer(prompt, {}, function(err, result)
    local duration = os.time() - requestStart

    if duration > 60 then
        -- Inference took over 60 seconds
        print("Warning: Slow inference (" .. duration .. "s)")
    end

    -- Handle result
end)
```

### Integration with Process State

**State Persistence:**
- Global variables persist across messages
- Inference callbacks can modify state
- Race conditions possible with concurrent callbacks

**State Safety Example:**
```lua
-- Safe state updates with locking
InferenceLock = InferenceLock or false

Handlers.add("safe-inference",
    Handlers.utils.hasMatchingTag("Action", "SafeInfer"),
    function(msg)
        if InferenceLock then
            ao.send({
                Target = msg.From,
                Action = "Error",
                Error = "Inference in progress, please wait"
            })
            return
        end

        InferenceLock = true

        ApusAI.infer(msg.Data, {}, function(err, result)
            -- Update state safely
            ProcessedCount = (ProcessedCount or 0) + 1

            InferenceLock = false

            ao.send({
                Target = msg.From,
                Action = "Result",
                Data = result,
                TotalProcessed = tostring(ProcessedCount)
            })
        end)
    end
)
```

---

## Q8: Credit-Notice / Debit-Notice Token Protocol

### Protocol Overview

The Credit-Notice/Debit-Notice pattern is AO's standard for token transfers, enabling processes to track incoming and outgoing payments atomically.

**Key Concept:** When tokens transfer, both sender and recipient receive notification messages.

### Protocol Implementation

**Standard Token Transfer Handler:**
```lua
Handlers.add("transfer",
    Handlers.utils.hasMatchingTag("Action", "Transfer"),
    function(msg)
        local recipient = msg.Recipient
        local quantity = tonumber(msg.Quantity)
        local sender = msg.From

        -- Validate
        if not recipient or not quantity or quantity <= 0 then
            ao.send({Target = sender, Action = "Error", Error = "Invalid transfer"})
            return
        end

        -- Check balance
        Balances = Balances or {}
        local senderBalance = Balances[sender] or 0

        if senderBalance < quantity then
            ao.send({Target = sender, Action = "Error", Error = "Insufficient balance"})
            return
        end

        -- Execute transfer
        Balances[sender] = senderBalance - quantity
        Balances[recipient] = (Balances[recipient] or 0) + quantity

        -- Send Debit-Notice to sender
        ao.send({
            Target = sender,
            Action = "Debit-Notice",
            Recipient = recipient,
            Quantity = tostring(quantity),
            Data = "Transfer successful"
        })

        -- Send Credit-Notice to recipient
        ao.send({
            Target = recipient,
            Action = "Credit-Notice",
            Sender = sender,
            Quantity = tostring(quantity),
            Data = "Received transfer"
        })
    end
)
```

### Receiving Payment Notifications

**Handler for Incoming Payments:**
```lua
Handlers.add("credit-notice",
    Handlers.utils.hasMatchingTag("Action", "Credit-Notice"),
    function(msg)
        local sender = msg.Sender
        local quantity = tonumber(msg.Quantity)

        -- Track received payments
        ReceivedPayments = ReceivedPayments or {}
        table.insert(ReceivedPayments, {
            from = sender,
            amount = quantity,
            timestamp = msg.Timestamp,
            txId = msg.Id
        })

        print("Received " .. quantity .. " from " .. sender)

        -- Optional: Auto-process payment (e.g., grant access, deliver service)
        processPayment(sender, quantity)
    end
)
```

**Handler for Outgoing Payments:**
```lua
Handlers.add("debit-notice",
    Handlers.utils.hasMatchingTag("Action", "Debit-Notice"),
    function(msg)
        local recipient = msg.Recipient
        local quantity = tonumber(msg.Quantity)

        -- Track sent payments
        SentPayments = SentPayments or {}
        table.insert(SentPayments, {
            to = recipient,
            amount = quantity,
            timestamp = msg.Timestamp,
            txId = msg.Id
        })

        print("Sent " .. quantity .. " to " .. recipient)
    end
)
```

### Payment-Gated Service Pattern

**Complete Payment Gate Example:**
```lua
-- Service configuration
SERVICE_PRICE = 1000  -- Cost per service call
TOKEN_PROCESS = "token-process-id-here"

-- Track user balances (deposited funds)
UserBalances = UserBalances or {}

-- Deposit handler (receives Credit-Notice)
Handlers.add("handle-deposit",
    Handlers.utils.hasMatchingTag("Action", "Credit-Notice"),
    function(msg)
        if msg.From ~= TOKEN_PROCESS then
            return  -- Ignore non-token messages
        end

        local sender = msg.Sender
        local amount = tonumber(msg.Quantity)

        -- Credit user balance
        UserBalances[sender] = (UserBalances[sender] or 0) + amount

        ao.send({
            Target = sender,
            Action = "Deposit-Confirmed",
            Amount = tostring(amount),
            NewBalance = tostring(UserBalances[sender])
        })
    end
)

-- Payment-gated service
Handlers.add("use-service",
    Handlers.utils.hasMatchingTag("Action", "UseService"),
    function(msg)
        local user = msg.From
        local userBalance = UserBalances[user] or 0

        -- Check sufficient funds
        if userBalance < SERVICE_PRICE then
            ao.send({
                Target = user,
                Action = "Error",
                Error = "Insufficient balance. Required: " .. SERVICE_PRICE .. ", Have: " .. userBalance
            })
            return
        end

        -- Deduct payment
        UserBalances[user] = userBalance - SERVICE_PRICE

        -- Deliver service
        local result = performService(msg.Data)

        ao.send({
            Target = user,
            Action = "Service-Delivered",
            Data = result,
            Cost = tostring(SERVICE_PRICE),
            RemainingBalance = tostring(UserBalances[user])
        })
    end
)

-- Withdrawal handler
Handlers.add("withdraw",
    Handlers.utils.hasMatchingTag("Action", "Withdraw"),
    function(msg)
        local user = msg.From
        local amount = tonumber(msg.Quantity)
        local userBalance = UserBalances[user] or 0

        if not amount or amount <= 0 then
            ao.send({Target = user, Action = "Error", Error = "Invalid amount"})
            return
        end

        if userBalance < amount then
            ao.send({Target = user, Action = "Error", Error = "Insufficient balance"})
            return
        end

        -- Deduct from user balance
        UserBalances[user] = userBalance - amount

        -- Transfer tokens back to user
        ao.send({
            Target = TOKEN_PROCESS,
            Action = "Transfer",
            Recipient = user,
            Quantity = tostring(amount)
        })

        ao.send({
            Target = user,
            Action = "Withdrawal-Initiated",
            Amount = tostring(amount),
            RemainingBalance = tostring(UserBalances[user])
        })
    end
)
```

### Race Conditions and Edge Cases

**Scenario 1: Double-Spend Prevention**
```lua
-- Track processed Credit-Notices to prevent replay
ProcessedCredits = ProcessedCredits or {}

Handlers.add("credit-notice",
    { Action = "Credit-Notice" },
    function(msg)
        local creditId = msg.Id

        -- Check if already processed
        if ProcessedCredits[creditId] then
            print("Warning: Duplicate credit notice ignored: " .. creditId)
            return
        end

        -- Mark as processed
        ProcessedCredits[creditId] = true

        -- Process payment
        local sender = msg.Sender
        local amount = tonumber(msg.Quantity)
        UserBalances[sender] = (UserBalances[sender] or 0) + amount
    end
)
```

**Scenario 2: Atomic Service Delivery**
```lua
-- Ensure service delivery and payment are atomic
Handlers.add("paid-service",
    { Action = "PaidService" },
    function(msg)
        local user = msg.From
        local userBalance = UserBalances[user] or 0

        if userBalance < SERVICE_PRICE then
            ao.send({Target = user, Action = "Error", Error = "Insufficient balance"})
            return
        end

        -- Attempt service delivery
        local success, result = pcall(performService, msg.Data)

        if not success then
            -- Service failed - don't charge
            ao.send({
                Target = user,
                Action = "Error",
                Error = "Service failed: " .. tostring(result)
            })
            return
        end

        -- Service succeeded - charge user
        UserBalances[user] = userBalance - SERVICE_PRICE

        ao.send({
            Target = user,
            Action = "Service-Complete",
            Data = result,
            Charged = tostring(SERVICE_PRICE)
        })
    end
)
```

**Scenario 3: Refund Mechanism**
```lua
-- Refund tracking
Refunds = Refunds or {}

Handlers.add("request-refund",
    { Action = "RequestRefund" },
    function(msg)
        local user = msg.From
        local jobId = msg.JobId

        -- Verify refund eligibility
        local job = Jobs[jobId]
        if not job or job.user ~= user then
            ao.send({Target = user, Action = "Error", Error = "Invalid job"})
            return
        end

        if job.status == "complete" then
            ao.send({Target = user, Action = "Error", Error = "Job already complete"})
            return
        end

        local refundId = msg.Id

        -- Check if already refunded
        if Refunds[refundId] then
            ao.send({Target = user, Action = "Error", Error = "Already refunded"})
            return
        end

        -- Process refund
        local refundAmount = job.paidAmount
        UserBalances[user] = (UserBalances[user] or 0) + refundAmount
        Refunds[refundId] = {
            user = user,
            amount = refundAmount,
            jobId = jobId,
            timestamp = msg.Timestamp
        }

        -- Mark job as refunded
        job.status = "refunded"

        ao.send({
            Target = user,
            Action = "Refund-Processed",
            Amount = tostring(refundAmount),
            JobId = jobId
        })
    end
)
```

### Balance Tracking Best Practices

**Pattern 1: Separate Internal and External Balances**
```lua
-- External balances (actual token holdings)
ExternalBalances = ExternalBalances or {}

-- Internal balances (credited to users for services)
InternalBalances = InternalBalances or {}

-- When receiving Credit-Notice from token process
Handlers.add("receive-tokens",
    { Action = "Credit-Notice" },
    function(msg)
        if msg.From == TOKEN_PROCESS then
            local sender = msg.Sender
            local amount = tonumber(msg.Quantity)

            -- Track external balance (actual tokens held by process)
            ExternalBalances[TOKEN_PROCESS] = (ExternalBalances[TOKEN_PROCESS] or 0) + amount

            -- Credit to user's internal balance
            InternalBalances[sender] = (InternalBalances[sender] or 0) + amount
        end
    end
)

-- Audit: Internal balances should never exceed external balance
function auditBalances()
    local totalInternal = 0
    for user, balance in pairs(InternalBalances) do
        totalInternal = totalInternal + balance
    end

    local externalBalance = ExternalBalances[TOKEN_PROCESS] or 0

    if totalInternal > externalBalance then
        error("Balance audit failed: internal > external")
    end

    return {
        external = externalBalance,
        internal = totalInternal,
        reserve = externalBalance - totalInternal
    }
end
```

### Integration with ao Token Standard

**Token Process Requirements:**
- Must implement `Transfer` action
- Must send `Debit-Notice` to sender
- Must send `Credit-Notice` to recipient
- Quantity must be string (AO convention)

**Compatible with:**
- Standard AO token processes
- $APUS token (`mqBYxpDsolZmJyBdTK8TJp_ftOuIUXVYcSQ8MYZdJg0`)
- Any token following Credit-Notice pattern

---

## Q15: Security Patterns for Payment Gating

### Threat Model

**Attack Vectors:**
1. **Reentrancy attacks** - Recursive calls draining balance
2. **Race conditions** - Concurrent withdrawal attempts
3. **Integer overflow/underflow** - Balance manipulation
4. **Replay attacks** - Reusing old Credit-Notice messages
5. **Unauthorized withdrawals** - Accessing others' funds
6. **Denial of service** - Exhausting process resources
7. **Price manipulation** - Exploiting dynamic pricing
8. **Front-running** - Observing and preempting transactions

### Reentrancy Prevention

**Pattern: Checks-Effects-Interactions**
```lua
Handlers.add("withdraw-safe",
    { Action = "Withdraw" },
    function(msg)
        local user = msg.From
        local amount = tonumber(msg.Quantity)

        -- CHECKS: Validate inputs and permissions
        if not amount or amount <= 0 then
            ao.send({Target = user, Action = "Error", Error = "Invalid amount"})
            return
        end

        local userBalance = UserBalances[user] or 0
        if userBalance < amount then
            ao.send({Target = user, Action = "Error", Error = "Insufficient balance"})
            return
        end

        -- EFFECTS: Update state BEFORE external calls
        UserBalances[user] = userBalance - amount

        -- INTERACTIONS: External calls after state changes
        ao.send({
            Target = TOKEN_PROCESS,
            Action = "Transfer",
            Recipient = user,
            Quantity = tostring(amount)
        })

        ao.send({
            Target = user,
            Action = "Withdrawal-Complete",
            Amount = tostring(amount)
        })
    end
)
```

**Anti-Pattern (Vulnerable to Reentrancy):**
```lua
-- ❌ DANGEROUS: External call before state update
Handlers.add("withdraw-unsafe",
    { Action = "Withdraw" },
    function(msg)
        local user = msg.From
        local amount = tonumber(msg.Quantity)

        -- Send tokens BEFORE updating balance
        ao.send({
            Target = TOKEN_PROCESS,
            Action = "Transfer",
            Recipient = user,
            Quantity = tostring(amount)
        })

        -- State update after external call (too late!)
        UserBalances[user] = (UserBalances[user] or 0) - amount
    end
)
```

### Balance Checking Race Conditions

**Pattern: Atomic Operations with Locks**
```lua
-- Simple mutex lock
WithdrawalLock = WithdrawalLock or {}

Handlers.add("withdraw-locked",
    { Action = "Withdraw" },
    function(msg)
        local user = msg.From

        -- Check lock
        if WithdrawalLock[user] then
            ao.send({
                Target = user,
                Action = "Error",
                Error = "Withdrawal in progress, please wait"
            })
            return
        end

        -- Acquire lock
        WithdrawalLock[user] = true

        local amount = tonumber(msg.Quantity)
        local userBalance = UserBalances[user] or 0

        -- Validate
        if userBalance < amount then
            WithdrawalLock[user] = false  -- Release lock
            ao.send({Target = user, Action = "Error", Error = "Insufficient balance"})
            return
        end

        -- Update state
        UserBalances[user] = userBalance - amount

        -- Release lock AFTER state update
        WithdrawalLock[user] = false

        -- External transfer
        ao.send({
            Target = TOKEN_PROCESS,
            Action = "Transfer",
            Recipient = user,
            Quantity = tostring(amount)
        })
    end
)
```

**Pattern: Transaction IDs to Prevent Duplicates**
```lua
ProcessedWithdrawals = ProcessedWithdrawals or {}

Handlers.add("withdraw-idempotent",
    { Action = "Withdraw" },
    function(msg)
        local txId = msg.Id

        -- Check if already processed
        if ProcessedWithdrawals[txId] then
            ao.send({
                Target = msg.From,
                Action = "Error",
                Error = "Withdrawal already processed"
            })
            return
        end

        -- Process withdrawal
        local user = msg.From
        local amount = tonumber(msg.Quantity)
        local userBalance = UserBalances[user] or 0

        if userBalance < amount then
            ao.send({Target = user, Action = "Error", Error = "Insufficient balance"})
            return
        end

        -- Update state
        UserBalances[user] = userBalance - amount
        ProcessedWithdrawals[txId] = {
            user = user,
            amount = amount,
            timestamp = msg.Timestamp
        }

        -- Transfer
        ao.send({
            Target = TOKEN_PROCESS,
            Action = "Transfer",
            Recipient = user,
            Quantity = tostring(amount)
        })
    end
)
```

### Refund Mechanisms

**Safe Refund Pattern:**
```lua
Handlers.add("issue-refund",
    { Action = "IssueRefund" },
    function(msg)
        local jobId = msg.JobId
        local job = Jobs[jobId]

        if not job then
            ao.send({Target = msg.From, Action = "Error", Error = "Job not found"})
            return
        end

        -- Verify refund hasn't been issued
        if job.refunded then
            ao.send({Target = msg.From, Action = "Error", Error = "Already refunded"})
            return
        end

        -- Verify job is eligible for refund
        if job.status == "complete" then
            ao.send({Target = msg.From, Action = "Error", Error = "Job complete, no refund"})
            return
        end

        local user = job.user
        local refundAmount = job.paidAmount

        -- Mark as refunded BEFORE crediting balance
        job.refunded = true
        job.refundedAt = msg.Timestamp

        -- Credit refund
        UserBalances[user] = (UserBalances[user] or 0) + refundAmount

        ao.send({
            Target = user,
            Action = "Refund-Issued",
            JobId = jobId,
            Amount = tostring(refundAmount)
        })
    end
)
```

### Withdrawal Safety

**Pattern: Minimum Balance Requirements**
```lua
MIN_BALANCE = 100  -- Must keep minimum balance

Handlers.add("withdraw-with-minimum",
    { Action = "Withdraw" },
    function(msg)
        local user = msg.From
        local amount = tonumber(msg.Quantity)
        local userBalance = UserBalances[user] or 0

        -- Check if withdrawal would violate minimum
        if (userBalance - amount) < MIN_BALANCE then
            ao.send({
                Target = user,
                Action = "Error",
                Error = "Must maintain minimum balance of " .. MIN_BALANCE
            })
            return
        end

        -- Proceed with withdrawal
        UserBalances[user] = userBalance - amount

        ao.send({
            Target = TOKEN_PROCESS,
            Action = "Transfer",
            Recipient = user,
            Quantity = tostring(amount)
        })
    end
)
```

**Pattern: Withdrawal Limits**
```lua
MAX_WITHDRAWAL = 10000
WithdrawalHistory = WithdrawalHistory or {}

Handlers.add("withdraw-with-limits",
    { Action = "Withdraw" },
    function(msg)
        local user = msg.From
        local amount = tonumber(msg.Quantity)

        -- Enforce maximum withdrawal
        if amount > MAX_WITHDRAWAL then
            ao.send({
                Target = user,
                Action = "Error",
                Error = "Exceeds maximum withdrawal of " .. MAX_WITHDRAWAL
            })
            return
        end

        -- Check daily limit
        local today = os.date("%Y-%m-%d", msg.Timestamp)
        local dailyKey = user .. "-" .. today
        local dailyTotal = (WithdrawalHistory[dailyKey] or 0) + amount

        if dailyTotal > MAX_WITHDRAWAL then
            ao.send({
                Target = user,
                Action = "Error",
                Error = "Daily withdrawal limit exceeded"
            })
            return
        end

        -- Process withdrawal
        UserBalances[user] = (UserBalances[user] or 0) - amount
        WithdrawalHistory[dailyKey] = dailyTotal

        ao.send({
            Target = TOKEN_PROCESS,
            Action = "Transfer",
            Recipient = user,
            Quantity = tostring(amount)
        })
    end
)
```

### Access Control Patterns

**Pattern: Owner-Only Functions**
```lua
OWNER = "owner-process-id-here"

Handlers.add("admin-withdraw",
    { Action = "AdminWithdraw" },
    function(msg)
        -- Check if sender is owner
        if msg.From ~= OWNER then
            ao.send({
                Target = msg.From,
                Action = "Error",
                Error = "Unauthorized: Owner only"
            })
            return
        end

        -- Admin can withdraw process funds
        local amount = tonumber(msg.Quantity)
        local recipient = msg.Recipient

        ao.send({
            Target = TOKEN_PROCESS,
            Action = "Transfer",
            Recipient = recipient,
            Quantity = tostring(amount)
        })
    end
)
```

**Pattern: Role-Based Access Control**
```lua
Roles = Roles or {}
Roles[OWNER] = "admin"

Handlers.add("set-role",
    { Action = "SetRole" },
    function(msg)
        if msg.From ~= OWNER then
            ao.send({Target = msg.From, Action = "Error", Error = "Unauthorized"})
            return
        end

        local user = msg.User
        local role = msg.Role

        Roles[user] = role

        ao.send({
            Target = msg.From,
            Action = "Role-Set",
            User = user,
            Role = role
        })
    end
)

Handlers.add("privileged-action",
    { Action = "PrivilegedAction" },
    function(msg)
        local userRole = Roles[msg.From]

        if userRole ~= "admin" and userRole ~= "moderator" then
            ao.send({Target = msg.From, Action = "Error", Error = "Unauthorized"})
            return
        end

        -- Perform privileged action
    end
)
```

### Integer Overflow/Underflow Prevention

**In Lua, numbers are double-precision floats, so traditional integer overflow isn't an issue. However, precision loss can occur with very large numbers.**

**Pattern: Range Validation**
```lua
MAX_SAFE_INTEGER = 2^53 - 1  -- JavaScript compatibility

function safeAdd(a, b)
    if a + b > MAX_SAFE_INTEGER then
        error("Integer overflow")
    end
    return a + b
end

function safeSubtract(a, b)
    if a < b then
        error("Insufficient balance")
    end
    return a - b
end

Handlers.add("transfer-safe-math",
    { Action = "Transfer" },
    function(msg)
        local sender = msg.From
        local recipient = msg.Recipient
        local quantity = tonumber(msg.Quantity)

        local senderBalance = Balances[sender] or 0
        local recipientBalance = Balances[recipient] or 0

        -- Safe operations
        local newSenderBalance = safeSubtract(senderBalance, quantity)
        local newRecipientBalance = safeAdd(recipientBalance, quantity)

        Balances[sender] = newSenderBalance
        Balances[recipient] = newRecipientBalance
    end
)
```

### Replay Attack Prevention

**Pattern: Nonce System**
```lua
UserNonces = UserNonces or {}

Handlers.add("payment-with-nonce",
    { Action = "PaymentWithNonce" },
    function(msg)
        local user = msg.From
        local nonce = tonumber(msg.Nonce)
        local expectedNonce = (UserNonces[user] or 0) + 1

        -- Verify nonce
        if nonce ~= expectedNonce then
            ao.send({
                Target = user,
                Action = "Error",
                Error = "Invalid nonce. Expected: " .. expectedNonce
            })
            return
        end

        -- Process payment
        local amount = tonumber(msg.Quantity)
        UserBalances[user] = (UserBalances[user] or 0) - amount

        -- Increment nonce
        UserNonces[user] = nonce

        ao.send({
            Target = user,
            Action = "Payment-Processed",
            Nonce = tostring(nonce)
        })
    end
)
```

### Security Checklist

**Before Deploying Payment-Gated Process:**

- [ ] Balance updates happen BEFORE external calls (prevent reentrancy)
- [ ] Message IDs tracked to prevent replay attacks
- [ ] User can only withdraw their own funds (access control)
- [ ] Concurrent operations handled with locks or idempotency
- [ ] Refunds can only be issued once per transaction
- [ ] Balance tracking uses separate internal/external accounting
- [ ] Audit function to verify balance consistency
- [ ] Input validation on all user-supplied values
- [ ] Maximum withdrawal/payment limits enforced
- [ ] Error messages don't leak sensitive information
- [ ] Owner-only functions properly restricted
- [ ] Test with malicious inputs and edge cases

**Recommended Testing:**
1. Attempt double-spending (same Credit-Notice twice)
2. Attempt concurrent withdrawals (race condition)
3. Attempt reentrancy (recursive withdrawal)
4. Attempt integer overflow (very large numbers)
5. Attempt unauthorized access (wrong user)
6. Attempt replay attacks (reuse old messages)

---

## Phase 1 Summary

### Critical Findings

**Apus Integration (Q1-Q5):**
✅ Simple API: 3 functions (initialize, infer, getBalance)
✅ Credit-based pricing: 1 credit = 1 inference call
✅ ~50 second latency per call
✅ Single model: Gemma3-27B (8,192 token limit)
✅ Async message passing via AO Router Process

**Payment Security (Q8, Q15):**
✅ Credit-Notice/Debit-Notice pattern is standard AO token protocol
✅ Must implement checks-effects-interactions to prevent reentrancy
✅ Use message ID tracking to prevent replay attacks
✅ Separate internal/external balance accounting recommended
✅ Locks or idempotency keys prevent race conditions

### Key Risks Identified

⚠️ **Apus Risks:**
- Single model dependency (no fallback)
- ~50s latency may impact UX
- Credit pricing volatility (tied to $APUS token)
- Unknown uptime/reliability SLA

⚠️ **Payment Risks:**
- Reentrancy attacks if not properly guarded
- Race conditions on concurrent operations
- Replay attacks without message ID tracking
- Balance inconsistencies without auditing

### Recommended Actions

**Immediate (Prototyping):**
1. Deploy test process with Apus integration
2. Measure actual inference latency and variance
3. Implement payment gating with security patterns
4. Test with malicious inputs

**Before Production:**
1. Implement comprehensive security checklist
2. Add balance auditing and monitoring
3. Design UX around ~50s latency
4. Plan for Apus downtime scenarios
5. Model cost economics with realistic usage

### Architecture Implications

**For Permamind:**
- Skill execution will have ~50s minimum latency
- Payment gating is feasible with Credit-Notice pattern
- Must design for async, message-based architecture
- Revenue sharing possible via multi-recipient transfers
- Cost estimation difficult without fixed $APUS exchange rate

**Feasibility Assessment:**
✅ **GO** - Core vision is technically feasible
✅ Apus provides necessary AI inference capabilities
✅ AO provides payment gating primitives
⚠️ Must design for latency and cost volatility

---

## Next Steps

**Phase 2 Focus:**
- AO Lua runtime capabilities (Q6)
- Message passing patterns (Q7)
- State management (Q9)
- Testing frameworks (Q10)
- Arweave data fetching (Q11-Q13)

**Immediate Prototyping:**
- Deploy test process to AO
- Integrate Apus with payment gating
- Measure real-world performance
- Validate security patterns
