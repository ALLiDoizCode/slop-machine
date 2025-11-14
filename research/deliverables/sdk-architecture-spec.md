# Permamind SDK Architecture Specification

**Version:** 1.0.0
**Last Updated:** 2025-11-13
**Status:** Design Complete - Ready for Implementation

---

## Overview

The Permamind SDK provides Lua modules for building payment-gated AI-powered AO processes. It abstracts complexity around Apus integration, payment handling, skill loading, and revenue sharing.

**Target Users:**
- Skill creators building monetizable AI processes
- Application developers integrating Permamind skills
- Process developers needing payment gating + AI

**Design Principles:**
1. **Simple by default, powerful when needed**
2. **Security first** - No foot-guns
3. **Fail-fast** - Clear error messages
4. **Composable** - Modules work independently or together
5. **ADP-compliant** - Self-documenting processes

---

## Module Structure

```
@permamind/sdk
├── core.lua              # Core initialization and utilities
├── payment.lua           # Payment gating and revenue sharing
├── skills.lua            # Skill loading and caching
├── ai.lua                # Apus integration wrapper
├── registry.lua          # Registry client for skill discovery
└── handlers.lua          # Pre-built ADP-compliant handlers
```

**Installation:**
```lua
apm.install "@permamind/sdk"
```

**Usage:**
```lua
local Permamind = require('@permamind/sdk')

-- Full SDK (recommended)
Permamind.init({
    enablePayments = true,
    enableAI = true,
    enableSkills = true
})

-- Or import specific modules
local Payment = require('@permamind/sdk/payment')
local AI = require('@permamind/sdk/ai')
```

---

## API Design

### Core Module (`core.lua`)

**Initialization:**
```lua
Permamind.init(config)
```

**Parameters:**
```lua
config = {
    -- Module enablement
    enablePayments = true,      -- Enable payment gating module
    enableAI = true,            -- Enable Apus AI integration
    enableSkills = true,        -- Enable skill loading
    enableRegistry = false,     -- Enable registry client

    -- Payment configuration
    tokenProcess = "token-process-id",  -- Payment token process
    pricePerExecution = 1000,           -- Price in token units
    revenueShares = {                   -- Revenue sharing (optional)
        skillCreator = 0.70,    -- 70% to skill creator
        processOwner = 0.20,    -- 20% to process owner
        platform = 0.10         -- 10% to platform
    },

    -- AI configuration (optional)
    apusDefaults = {
        maxTokens = 2048,
        temperature = 0.7,
        topP = 0.9
    },

    -- Skill configuration (optional)
    skillCacheSize = 10,        -- Number of skills to cache
    skillGateway = "gateway-process-id"  -- For Arweave fetching
}
```

**Returns:** void (initializes global state)

**Example:**
```lua
Permamind.init({
    enablePayments = true,
    enableAI = true,
    tokenProcess = "mqBYxpDsolZmJyBdTK8TJp_ftOuIUXVYcSQ8MYZdJg0",
    pricePerExecution = 1000,
    apusDefaults = {
        maxTokens = 500,
        temperature = 0.8
    }
})
```

**Utility Functions:**
```lua
-- Version info
Permamind.version() -- Returns "1.0.0"

-- Health check
Permamind.isInitialized() -- Returns boolean

-- Configuration
Permamind.getConfig() -- Returns current config

-- Debug mode
Permamind.setDebug(true) -- Enable debug logging
```

---

### Payment Module (`payment.lua`)

**Deposit Handling (Automatic):**
```lua
-- Automatically handles Credit-Notice messages
-- No manual setup required after Permamind.init()
```

**Check User Balance:**
```lua
local balance = Payment.getBalance(userAddress)
```

**Returns:** number (user's deposited balance)

**Charge User:**
```lua
local success, newBalance = Payment.charge(user, amount, metadata)
```

**Parameters:**
- `user` (string): User process/wallet address
- `amount` (number): Amount to charge
- `metadata` (table, optional): Transaction metadata

**Returns:**
- `success` (boolean): Whether charge succeeded
- `newBalance` (number|nil): User's remaining balance (nil if failed)

**Example:**
```lua
local success, newBalance = Payment.charge(msg.From, 1000, {
    service = "skill-execution",
    skillId = "data-analysis-v1"
})

if not success then
    ao.send({Target = msg.From, Action = "Error", Error = "Insufficient balance"})
    return
end

-- Proceed with service delivery
```

**Revenue Sharing:**
```lua
local success = Payment.distributeRevenue(totalAmount, recipients)
```

**Parameters:**
- `totalAmount` (number): Total amount to distribute
- `recipients` (table): Array of {address, percentage}

**Example:**
```lua
Payment.distributeRevenue(1000, {
    {address = SKILL_CREATOR, percentage = 0.70},
    {address = PROCESS_OWNER, percentage = 0.20},
    {address = PLATFORM_TREASURY, percentage = 0.10}
})

-- Automatically sends Credit-Notices to all recipients
```

**Withdrawal:**
```lua
Payment.withdraw(user, amount) -- Sends tokens back to user
```

**Refund:**
```lua
Payment.refund(user, amount, reason)
```

**Example:**
```lua
Payment.refund(msg.From, 1000, "Inference failed")
```

**Balance Audit:**
```lua
local audit = Payment.auditBalances()
-- Returns: {internal: 5000, external: 5000, reserve: 0, consistent: true}
```

**Security Features:**
- ✅ Automatic reentrancy prevention (checks-effects-interactions)
- ✅ Message ID tracking (replay attack prevention)
- ✅ Dual accounting (internal/external balance tracking)
- ✅ Withdrawal locks (race condition prevention)

---

### Skills Module (`skills.lua`)

**Load Skill:**
```lua
local skill, err = Skills.load(skillTxId, options)
```

**Parameters:**
- `skillTxId` (string): Arweave transaction ID of skill
- `options` (table, optional):
  - `useCache` (boolean, default: true): Use cached skill if available
  - `validate` (boolean, default: true): Validate skill format
  - `timeout` (number, default: 30000): Fetch timeout in ms

**Returns:**
- `skill` (table|nil): Parsed skill object
- `err` (string|nil): Error message if failed

**Example:**
```lua
local skill, err = Skills.load("abc123...def789", {
    useCache = true,
    validate = true
})

if err then
    ao.send({Target = msg.From, Action = "Error", Error = "Failed to load skill: " .. err})
    return
end

-- Use skill
local systemPrompt = skill.instructions
local examples = skill.examples
```

**Preload Skills (Caching):**
```lua
Skills.preload(skillTxIds) -- Array of TX IDs to cache
```

**Example:**
```lua
-- Preload popular skills on process initialization
Skills.preload({
    "skill-1-tx-id",
    "skill-2-tx-id",
    "skill-3-tx-id"
})
```

**Skill Format:**
```lua
skill = {
    name = "Data Analysis Expert",
    version = "1.0.0",
    category = "data-analysis",
    author = "creator-address",
    instructions = "You are an expert data analyst...",
    examples = {
        {input = "Analyze this data...", output = "Analysis: ..."},
        {input = "Find trends in...", output = "Trends: ..."}
    },
    metadata = {
        tags = {"analysis", "statistics", "data"},
        license = "MIT",
        price = 1000
    }
}
```

**Cache Management:**
```lua
Skills.clearCache()           -- Clear all cached skills
Skills.evict(skillTxId)       -- Remove specific skill from cache
Skills.getCacheStats()        -- Returns {size, hitRate, missRate}
```

---

### AI Module (`ai.lua`)

**Inference:**
```lua
AI.infer(prompt, options, callback)
```

**Parameters:**
- `prompt` (string): User prompt for AI inference
- `options` (table, optional):
  - `maxTokens` (number): Maximum response tokens
  - `temperature` (float): Randomness (0.0-2.0)
  - `topP` (float): Nucleus sampling (0.0-1.0)
  - `systemPrompt` (string): System instructions (for skill integration)
- `callback` (function): `function(err, result)`

**Example:**
```lua
AI.infer("What is Arweave?", {
    maxTokens = 500,
    temperature = 0.7
}, function(err, result)
    if err then
        ao.send({Target = msg.From, Action = "Error", Error = err.message})
        return
    end

    ao.send({
        Target = msg.From,
        Action = "AI-Response",
        Data = result
    })
end)
```

**Skill-Enhanced Inference:**
```lua
AI.inferWithSkill(skillTxId, prompt, options, callback)
```

**Example:**
```lua
AI.inferWithSkill("skill-tx-id", "Analyze this dataset: [1,2,3,4,5]", {
    maxTokens = 1000
}, function(err, result)
    if err then
        ao.send({Target = msg.From, Action = "Error", Error = err.message})
        return
    end

    ao.send({
        Target = msg.From,
        Action = "Analysis-Complete",
        Data = result
    })
end)

-- Automatically loads skill, constructs system prompt, runs inference
```

**Cost Estimation:**
```lua
local estimatedCost = AI.estimateCost(options)
```

**Returns:** number (estimated cost in credits)

**Check Balance:**
```lua
local balance = AI.getBalance()
```

**Returns:** number (remaining Apus credits)

---

### Registry Module (`registry.lua`)

**Search Skills:**
```lua
Registry.search(query, options, callback)
```

**Parameters:**
- `query` (string): Search query
- `options` (table, optional):
  - `category` (string): Filter by category
  - `tags` (array): Filter by tags
  - `minRating` (number): Minimum rating
  - `limit` (number, default: 20): Results limit
- `callback` (function): `function(err, results)`

**Example:**
```lua
Registry.search("data analysis", {
    category = "data-analysis",
    tags = {"statistics", "ml"},
    limit = 10
}, function(err, results)
    if err then
        ao.send({Target = msg.From, Action = "Error", Error = err.message})
        return
    end

    ao.send({
        Target = msg.From,
        Action = "Search-Results",
        Data = json.encode(results)
    })
end)
```

**Get Skill Details:**
```lua
Registry.getSkill(skillId, callback)
```

**Publish Skill:**
```lua
Registry.publish(skillData, arweaveTxId, callback)
```

**Example:**
```lua
Registry.publish({
    name = "Data Analysis Expert",
    category = "data-analysis",
    tags = {"analysis", "statistics"},
    price = 1000,
    arweaveTxId = "abc123...def789"
}, function(err, skillId)
    if err then
        ao.send({Target = msg.From, Action = "Error", Error = err.message})
        return
    end

    ao.send({
        Target = msg.From,
        Action = "Skill-Published",
        SkillId = skillId
    })
end)
```

---

### Handlers Module (`handlers.lua`)

Pre-built ADP-compliant handlers for common use cases.

**Payment-Gated AI Service:**
```lua
Handlers.add("ai-service", Handlers.paymentGatedAI({
    price = 1000,
    revenueShares = {
        skillCreator = 0.70,
        processOwner = 0.30
    }
}))

-- Automatically handles:
-- 1. Payment validation
-- 2. Skill loading
-- 3. AI inference
-- 4. Revenue distribution
-- 5. Response delivery
```

**Info Handler (ADP Compliance):**
```lua
Handlers.add("info", Handlers.info({
    name = "My AI Service",
    version = "1.0.0",
    capabilities = ["ai-inference", "skill-execution"],
    pricing = {
        perExecution = 1000,
        currency = "token-process-id"
    }
}))

-- Returns comprehensive process metadata
```

**Balance Query:**
```lua
Handlers.add("balance", Handlers.balanceQuery())

-- Responds to Action: "Balance" with user's deposited balance
```

**Withdrawal:**
```lua
Handlers.add("withdraw", Handlers.withdrawal({
    minAmount = 100,
    maxAmount = 10000
}))

-- Handles Action: "Withdraw" with safety checks
```

---

## Complete Example: Payment-Gated AI Service

```lua
local Permamind = require('@permamind/sdk')

-- Initialize SDK
Permamind.init({
    enablePayments = true,
    enableAI = true,
    enableSkills = true,
    tokenProcess = "mqBYxpDsolZmJyBdTK8TJp_ftOuIUXVYcSQ8MYZdJg0",
    pricePerExecution = 1000,
    revenueShares = {
        skillCreator = 0.70,
        processOwner = 0.20,
        platform = 0.10
    },
    apusDefaults = {
        maxTokens = 1000,
        temperature = 0.7
    }
})

-- ADP Info Handler
Handlers.add("info",
    Handlers.utils.hasMatchingTag("Action", "Info"),
    function(msg)
        ao.send({
            Target = msg.From,
            Action = "SaveState",
            Data = json.encode({
                process = {
                    name = "Permamind AI Service",
                    version = "1.0.0",
                    adpVersion = "1.0",
                    capabilities = ["ai-inference", "skill-execution"]
                },
                pricing = {
                    perExecution = 1000,
                    currency = "mqBYxpDsolZmJyBdTK8TJp_ftOuIUXVYcSQ8MYZdJg0"
                }
            })
        })
    end
)

-- Balance Query Handler
Handlers.add("balance",
    Handlers.utils.hasMatchingTag("Action", "Balance"),
    function(msg)
        local Payment = require('@permamind/sdk/payment')
        local balance = Payment.getBalance(msg.From)

        ao.send({
            Target = msg.From,
            Action = "Balance-Response",
            Balance = tostring(balance)
        })
    end
)

-- Execute Skill Handler (Payment-Gated)
Handlers.add("execute-skill",
    Handlers.utils.hasMatchingTag("Action", "ExecuteSkill"),
    function(msg)
        local Payment = require('@permamind/sdk/payment')
        local Skills = require('@permamind/sdk/skills')
        local AI = require('@permamind/sdk/ai')

        -- Validate inputs
        if not msg.SkillId or not msg.Prompt then
            ao.send({
                Target = msg.From,
                Action = "Error",
                Error = "SkillId and Prompt required"
            })
            return
        end

        -- Check payment
        local price = 1000
        local success, newBalance = Payment.charge(msg.From, price, {
            skillId = msg.SkillId,
            prompt = msg.Prompt
        })

        if not success then
            ao.send({
                Target = msg.From,
                Action = "Error",
                Error = "Insufficient balance. Required: " .. price
            })
            return
        end

        -- Load skill
        local skill, err = Skills.load(msg.SkillId)

        if err then
            -- Refund on skill load failure
            Payment.refund(msg.From, price, "Skill load failed")
            ao.send({
                Target = msg.From,
                Action = "Error",
                Error = "Failed to load skill: " .. err
            })
            return
        end

        -- Execute AI inference with skill
        AI.infer(msg.Prompt, {
            systemPrompt = skill.instructions,
            maxTokens = 1000,
            temperature = 0.7
        }, function(inferErr, result)
            if inferErr then
                -- Refund on inference failure
                Payment.refund(msg.From, price, "Inference failed")
                ao.send({
                    Target = msg.From,
                    Action = "Error",
                    Error = "Inference failed: " .. inferErr.message
                })
                return
            end

            -- Distribute revenue
            Payment.distributeRevenue(price, {
                {address = skill.author, percentage = 0.70},
                {address = ao.id, percentage = 0.20},
                {address = "platform-treasury", percentage = 0.10}
            })

            -- Send result
            ao.send({
                Target = msg.From,
                Action = "Execution-Complete",
                SkillId = msg.SkillId,
                Data = result,
                Cost = tostring(price),
                RemainingBalance = tostring(newBalance)
            })
        end)
    end
)

-- Withdrawal Handler
Handlers.add("withdraw",
    Handlers.utils.hasMatchingTag("Action", "Withdraw"),
    function(msg)
        local Payment = require('@permamind/sdk/payment')

        local amount = tonumber(msg.Quantity)

        if not amount or amount <= 0 then
            ao.send({Target = msg.From, Action = "Error", Error = "Invalid amount"})
            return
        end

        local success, err = Payment.withdraw(msg.From, amount)

        if not success then
            ao.send({Target = msg.From, Action = "Error", Error = err})
            return
        end

        ao.send({
            Target = msg.From,
            Action = "Withdrawal-Complete",
            Amount = tostring(amount)
        })
    end
)
```

---

## Error Handling Conventions

**Error Response Format:**
```lua
ao.send({
    Target = msg.From,
    Action = "Error",
    Error = "Human-readable error message",
    ErrorCode = "ERROR_CODE",          -- Optional: Machine-readable code
    ["X-Message-Id"] = msg.Id           -- Original message ID
})
```

**Error Codes:**
| Code | Meaning | User Action |
|------|---------|-------------|
| `INSUFFICIENT_BALANCE` | Not enough deposited funds | Deposit more tokens |
| `SKILL_NOT_FOUND` | Skill TX ID invalid or not found | Check skill ID |
| `INFERENCE_FAILED` | Apus inference error | Retry or contact support |
| `INVALID_INPUT` | Missing or malformed parameters | Check input format |
| `UNAUTHORIZED` | Permission denied | Check ownership/access |
| `RATE_LIMITED` | Too many requests | Wait and retry |

**SDK Internal Error Handling:**
- All public functions return `(result, error)` tuple
- Errors are never thrown (no pcall needed by users)
- Errors are strings with context
- Failed operations never modify state

---

## Testing Guide

**Unit Testing with aolite:**
```lua
local aolite = require('aolite')
local Permamind = require('@permamind/sdk')

-- Test payment gating
local process = aolite.spawnProcess('my_process.lua')

-- Fund user
aolite.send(nil, process, {
    From = "token-process",
    Action = "Credit-Notice",
    Sender = "user-1",
    Quantity = "5000"
})

aolite.runScheduler()

-- Execute paid service
aolite.send(nil, process, {
    From = "user-1",
    Action = "ExecuteSkill",
    SkillId = "skill-tx-id",
    Prompt = "Test prompt"
})

aolite.runScheduler()

-- Check messages
local messages = aolite.getAllMsgs(process)
assert(messages[1].Action == "Execution-Complete", "Should complete execution")

-- Check balance was deducted
assert(process.UserBalances["user-1"] == 4000, "Should deduct 1000")

print("✅ Payment gating test passed")
```

**Integration Testing:**
```bash
# Deploy to testnet
aos my-test-process

# Load SDK and process code
.load-blueprint apm
apm.install "@permamind/sdk"
.load my_process.lua

# Test with real Apus
ApusAI_Debug = true
-- Send test messages via aos CLI
```

---

## Performance Considerations

**Caching:**
- Skills cached in-process (configurable size limit)
- LRU eviction policy
- Cache hit rate logged when debug enabled

**Message Passing:**
- Async by default (non-blocking)
- Callbacks invoked on message arrival
- No synchronous waiting

**State Management:**
- Minimal state size (only balances and pending operations)
- Large data stored on Arweave (TX IDs in state)
- Regular state audit recommended

**Optimization Tips:**
1. Preload popular skills during initialization
2. Use lower `maxTokens` for faster/cheaper inference
3. Batch multiple operations when possible
4. Clear old pending requests periodically

---

## Security Checklist

**Before Deployment:**
- [ ] Payment handlers use checks-effects-interactions pattern
- [ ] Message IDs tracked to prevent replay attacks
- [ ] User balances use dual accounting (internal/external)
- [ ] Withdrawal has locks to prevent race conditions
- [ ] Refunds can only be issued once per transaction
- [ ] Revenue sharing adds up to 100%
- [ ] Access control on admin functions
- [ ] Input validation on all user-supplied data
- [ ] Error messages don't leak sensitive information
- [ ] Test with malicious inputs

---

## Versioning and Upgrades

**Semantic Versioning:**
- Major: Breaking API changes
- Minor: New features (backwards compatible)
- Patch: Bug fixes

**Upgrade Process:**
```lua
-- Check current version
Permamind.version() -- Returns "1.0.0"

-- Upgrade
apm.update "@permamind/sdk"

-- Migrate state if needed
if STATE_VERSION == 1 then
    -- Migration logic
    STATE_VERSION = 2
end
```

---

## Support and Documentation

**Resources:**
- SDK Documentation: https://docs.permamind.io/sdk
- Examples: https://github.com/permamind/examples
- Discord: https://discord.gg/permamind
- Issue Tracker: https://github.com/permamind/sdk/issues

**Getting Help:**
1. Check documentation and examples
2. Search existing issues
3. Ask in Discord #dev-support
4. Create new issue with reproducible example

---

## Roadmap

**v1.1.0 (Q1 2026):**
- Multi-model support (when available)
- Skill composition (chains, workflows)
- Advanced caching strategies
- Performance monitoring built-in

**v1.2.0 (Q2 2026):**
- Subscription-based access models
- Reputation/rating integration
- Advanced analytics
- Frontend SDK (JavaScript)

**v2.0.0 (Q3 2026):**
- HyperBEAM migration (if required)
- New payment patterns
- Breaking API improvements based on feedback

---

**Document Version:** 1.0.0
**Status:** ✅ Ready for Implementation
**Next Step:** Begin SDK development (Sprint 1)
