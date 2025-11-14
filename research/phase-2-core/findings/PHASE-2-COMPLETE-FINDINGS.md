# Phase 2 Complete Findings: AO Development + Arweave Storage

**Phase:** 2 (Core Infrastructure)
**Status:** Complete
**Date:** 2025-11-13
**Questions Covered:** Q6-Q7, Q9-Q13

---

## Q6: AO Lua Runtime Environment

### Available Standard Libraries

**Fully Available:**
- `string` - All string manipulation functions
- `table` - Table operations (insert, remove, concat, sort)
- `math` - Mathematical functions (min, max, floor, ceil, random, etc.)
- `json` - JSON encode/decode (via `require("json")`)
- `os` - LIMITED: date, time (NOT: execute, remove, rename, tmpname)

**Available with Restrictions:**
- `os.time()` - ❌ **FORBIDDEN** - Use `msg.Timestamp` instead
- `os.date()` - ✅ Available for formatting timestamps

**NOT Available:**
- `io` library - No file system access
- `debug` library - Not exposed
- `require()` - Only works for `json` and approved AO modules
- `load()` / `loadfile()` - Code loading disabled
- `dofile()` - Not available
- Network libraries - No sockets, HTTP, etc.

### Custom AO-Specific APIs

**AO Globals:**
```lua
ao = {
    send = function(message) end,  -- Send message to other processes
    id = "current-process-id",     -- This process's ID
    env = {                        -- Environment info
        Process = { Id = "...", Owner = "...", Tags = {...} }
    }
}

Handlers = {
    add = function(name, matcher, handler) end,
    utils = {
        hasMatchingTag = function(tag, value) end,
        hasMatchingData = function(pattern) end
    }
}
```

**Message Structure (msg):**
```lua
msg = {
    From = "sender-process-id",
    Id = "message-id",
    Timestamp = 1699564800000,  -- Unix timestamp (milliseconds)
    Tags = {
        Action = "Transfer",
        Quantity = "100",
        -- ... other tags
    },
    Data = "message data string"
}
```

### Memory and Execution Limits

**Memory:**
- No documented hard limit
- State stored in global Lua variables
- Persists across messages (permanent on Arweave)
- Large state increases storage costs

**Execution Time:**
- No documented timeout per message
- Long-running computations should be split across multiple messages
- Blocking operations not supported (no sleep, no I/O wait)

**Best Practices:**
- Keep handler functions focused and fast
- Use message passing for long operations
- Avoid infinite loops
- Limit state size to essentials

### Missing Capabilities vs Standard Lua

**Not Available:**
1. File system I/O
2. Network operations
3. External processes (os.execute)
4. Module system (except json and AO modules)
5. Coroutines (not documented as available)
6. Metatables (available but use cautiously)
7. Garbage collection control
8. Debug hooks

**Workarounds:**
- File storage → Use Arweave transaction IDs
- HTTP requests → Use gateway processes
- External APIs → Message passing to gateway processes
- Time-based operations → Use msg.Timestamp

---

## Q7: AO Message Passing Model

### Send() Function Capabilities

**Full Signature:**
```lua
ao.send({
    Target = "recipient-process-id-43-chars",  -- Required
    Action = "ActionName",                      -- Recommended tag
    Data = "message payload",                   -- Optional

    -- Additional tags (all optional)
    CustomTag1 = "value1",
    CustomTag2 = "value2",
    ["Tag-With-Dashes"] = "value"
})
```

**Return Value:**
- None (fire-and-forget)
- No confirmation of delivery
- No error if Target doesn't exist

**Options:**
```lua
-- Simple send
ao.send({ Target = processId, Action = "Ping" })

-- With data payload
ao.send({
    Target = processId,
    Action = "ProcessData",
    Data = json.encode({ items = [1, 2, 3] })
})

-- With custom tags
ao.send({
    Target = processId,
    Action = "Transfer",
    Recipient = "address",
    Quantity = "1000",
    ["X-Custom-Header"] = "value"
})
```

### Message Receipt and Handler Pattern

**Handler Registration:**
```lua
Handlers.add(
    "handler-name",                    -- Unique identifier
    matcher,                           -- Pattern matcher function
    handler                            -- Handler function
)
```

**Common Matchers:**
```lua
-- Match by Action tag
Handlers.utils.hasMatchingTag("Action", "Transfer")

-- Match multiple criteria
function(msg)
    return msg.Action == "Transfer" and msg.From == AUTHORIZED_USER
end

-- Match by Data pattern
Handlers.utils.hasMatchingData("pattern")
```

**Handler Execution Order:**
- Handlers execute in registration order
- First matching handler processes message
- Subsequent handlers don't run unless explicitly chained

### Asynchronous Message Handling

**Fire-and-Forget:**
```lua
Handlers.add("initiate-task",
    { Action = "StartTask" },
    function(msg)
        -- Send message to worker process
        ao.send({
            Target = WORKER_PROCESS,
            Action = "ProcessJob",
            Data = msg.Data
        })

        -- Handler returns immediately
        -- Response comes as separate incoming message
    end
)

-- Separate handler for response
Handlers.add("receive-result",
    { Action = "JobResult" },
    function(msg)
        -- Process result from worker
        local result = json.decode(msg.Data)

        -- Forward to original requestor (must track in state)
        local originalRequestor = PendingJobs[msg.JobId]
        ao.send({
            Target = originalRequestor,
            Action = "TaskComplete",
            Data = msg.Data
        })
    end
)
```

**Request Tracking Pattern:**
```lua
PendingRequests = PendingRequests or {}

Handlers.add("send-with-tracking",
    { Action = "RequestData" },
    function(msg)
        local requestId = msg.Id

        -- Store request context
        PendingRequests[requestId] = {
            requester = msg.From,
            timestamp = msg.Timestamp,
            data = msg.Data
        }

        -- Send to external process
        ao.send({
            Target = DATA_PROVIDER,
            Action = "GetData",
            ["X-Request-Id"] = requestId,
            Data = msg.Data
        })
    end
)

Handlers.add("receive-data",
    { Action = "DataResponse" },
    function(msg)
        local requestId = msg["X-Request-Id"]
        local request = PendingRequests[requestId]

        if not request then
            return  -- Unknown request
        end

        -- Forward to original requester
        ao.send({
            Target = request.requester,
            Action = "DataReady",
            Data = msg.Data
        })

        -- Cleanup
        PendingRequests[requestId] = nil
    end
)
```

### Message Ordering and Delivery Guarantees

**Ordering:**
- Messages from same sender are processed in send order
- Messages from different senders may interleave
- No guaranteed global ordering

**Delivery:**
- Best-effort delivery (AO network handles retries)
- No built-in acknowledgment mechanism
- Lost messages are retried by compute units
- **Application should implement explicit ACKs for critical operations**

**Reliability Pattern:**
```lua
Handlers.add("reliable-request",
    { Action = "ReliableRequest" },
    function(msg)
        -- Process request
        local result = processData(msg.Data)

        -- Send explicit ACK
        ao.send({
            Target = msg.From,
            Action = "ACK",
            ["X-Message-Id"] = msg.Id,
            Status = "Success",
            Data = result
        })
    end
)
```

### Error Handling for Failed Messages

**No Built-In Error Responses:**
- `ao.send()` never throws errors
- Failed sends are silent
- Recipient must send error messages explicitly

**Error Response Pattern:**
```lua
Handlers.add("with-error-handling",
    { Action = "ProcessData" },
    function(msg)
        -- Validate input
        if not msg.Data or msg.Data == "" then
            ao.send({
                Target = msg.From,
                Action = "Error",
                Error = "Data field required",
                ["X-Message-Id"] = msg.Id
            })
            return
        end

        -- Process (with pcall for truly fallible operations)
        local success, result = pcall(parseAndProcess, msg.Data)

        if not success then
            ao.send({
                Target = msg.From,
                Action = "Error",
                Error = tostring(result),
                ["X-Message-Id"] = msg.Id
            })
            return
        end

        -- Success response
        ao.send({
            Target = msg.From,
            Action = "Success",
            Data = json.encode(result)
        })
    end
)
```

**Timeout Pattern (Application-Level):**
```lua
PendingRequests = PendingRequests or {}

Handlers.add("send-with-timeout",
    { Action = "RequestWithTimeout" },
    function(msg)
        local requestId = msg.Id

        PendingRequests[requestId] = {
            requester = msg.From,
            sentAt = msg.Timestamp,
            timeout = 60000  -- 60 seconds
        }

        ao.send({
            Target = EXTERNAL_SERVICE,
            Action = "GetData",
            ["X-Request-Id"] = requestId
        })
    end
)

-- Periodic timeout checker (triggered by cron message)
Handlers.add("check-timeouts",
    { Action = "CheckTimeouts" },
    function(msg)
        local now = msg.Timestamp

        for requestId, request in pairs(PendingRequests) do
            if (now - request.sentAt) > request.timeout then
                -- Timeout occurred
                ao.send({
                    Target = request.requester,
                    Action = "Timeout",
                    Error = "Request timed out",
                    ["X-Request-Id"] = requestId
                })

                PendingRequests[requestId] = nil
            end
        end
    end
)
```

---

## Q9: AO State Management

### Global State Persistence

**State Persistence Mechanism:**
- All global variables persist across messages
- State stored on Arweave (permanent)
- Each message handler reads current state, modifies it, writes back
- No explicit save/load required

**State Initialization Pattern:**
```lua
-- Initialize state (or {} pattern)
Users = Users or {}
Balances = Balances or {}
TotalSupply = TotalSupply or 1000000

-- Alternative: Explicit initialization
if not Initialized then
    Users = {}
    Balances = {}
    TotalSupply = 1000000
    Initialized = true
end
```

**State Modification:**
```lua
Handlers.add("update-state",
    { Action = "UpdateUser" },
    function(msg)
        local userId = msg.UserId

        -- Read current state
        Users = Users or {}

        -- Modify
        Users[userId] = {
            name = msg.Name,
            email = msg.Email,
            updatedAt = msg.Timestamp
        }

        -- State automatically persisted after handler completes
    end
)
```

### State Size Limits

**No Hard Limits Documented:**
- Theoretically unlimited (stored on Arweave)
- Practical limits:
  - Large state increases message processing time
  - Large state increases Arweave storage costs
  - Very large state may impact process performance

**Optimization Strategies:**
1. Store only essential data in state
2. Use Arweave transaction IDs for large data
3. Implement state pruning/archiving
4. Use pagination for large collections
5. Compress data with JSON encoding

**State Size Example:**
```lua
-- ❌ Inefficient: Store entire history
UserActions = UserActions or {}
table.insert(UserActions, {
    user = msg.From,
    action = msg.Action,
    timestamp = msg.Timestamp,
    data = msg.Data  -- Could be large
})
-- State grows unbounded!

-- ✅ Efficient: Store summary + Arweave references
UserSummary = UserSummary or {}
UserSummary[msg.From] = {
    lastAction = msg.Action,
    lastActive = msg.Timestamp,
    actionCount = (UserSummary[msg.From]?.actionCount or 0) + 1,
    historyTxId = "arweave-tx-id-with-full-history"
}
```

### State Initialization Patterns

**Pattern 1: Lazy Initialization (Recommended)**
```lua
-- State initialized on first access
Handlers.add("access-state",
    { Action = "ReadData" },
    function(msg)
        Users = Users or {}  -- Initialize if not exists

        local user = Users[msg.UserId]
        if not user then
            user = {
                id = msg.UserId,
                createdAt = msg.Timestamp,
                data = {}
            }
            Users[msg.UserId] = user
        end

        ao.send({
            Target = msg.From,
            Action = "UserData",
            Data = json.encode(user)
        })
    end
)
```

**Pattern 2: Explicit Initialization Handler**
```lua
OWNER = "owner-process-id"

Handlers.add("initialize",
    { Action = "Initialize" },
    function(msg)
        if msg.From ~= OWNER then
            ao.send({Target = msg.From, Action = "Error", Error = "Unauthorized"})
            return
        end

        if Initialized then
            ao.send({Target = msg.From, Action = "Error", Error = "Already initialized"})
            return
        end

        -- Initialize state
        Name = "MyToken"
        Symbol = "MTK"
        Decimals = 12
        TotalSupply = 1000000 * (10^12)
        Balances = {}
        Balances[OWNER] = TotalSupply
        Initialized = true

        ao.send({Target = msg.From, Action = "Initialized", Status = "Success"})
    end
)
```

**Pattern 3: Constructor-Style Initialization**
```lua
-- Initialize on first message (any action)
if not Initialized then
    -- Default configuration
    Config = {
        version = "1.0.0",
        maxUsers = 10000,
        feesEnabled = true
    }

    Users = {}
    Transactions = {}
    Initialized = true
    InitializedAt = os.time()
end
```

### State Migration/Upgrade Strategies

**Pattern 1: Version-Based Migration**
```lua
STATE_VERSION = STATE_VERSION or 1

-- Migration logic
if STATE_VERSION == 1 then
    -- Migrate from v1 to v2
    print("Migrating state from v1 to v2")

    -- Add new fields
    for userId, user in pairs(Users) do
        user.email = user.email or ""  -- Add email field
        user.verified = false          -- Add verified field
    end

    STATE_VERSION = 2
end

if STATE_VERSION == 2 then
    -- Migrate from v2 to v3
    print("Migrating state from v2 to v3")

    -- Restructure data
    UsersByEmail = {}
    for userId, user in pairs(Users) do
        if user.email and user.email ~= "" then
            UsersByEmail[user.email] = userId
        end
    end

    STATE_VERSION = 3
end
```

**Pattern 2: Admin-Triggered Migration**
```lua
Handlers.add("migrate-state",
    { Action = "MigrateState" },
    function(msg)
        if msg.From ~= OWNER then
            ao.send({Target = msg.From, Action = "Error", Error = "Unauthorized"})
            return
        end

        local fromVersion = STATE_VERSION or 1
        local toVersion = tonumber(msg.ToVersion)

        if fromVersion >= toVersion then
            ao.send({Target = msg.From, Action = "Error", Error = "Already at version " .. fromVersion})
            return
        end

        -- Perform migration
        if fromVersion == 1 and toVersion == 2 then
            -- Migration logic here
            for userId, user in pairs(Users) do
                user.role = "user"  -- Add role field
            end
            STATE_VERSION = 2
        end

        ao.send({
            Target = msg.From,
            Action = "Migration-Complete",
            FromVersion = tostring(fromVersion),
            ToVersion = tostring(STATE_VERSION)
        })
    end
)
```

**Pattern 3: Backup Before Migration**
```lua
Handlers.add("backup-and-migrate",
    { Action = "BackupAndMigrate" },
    function(msg)
        if msg.From ~= OWNER then
            return
        end

        -- Create state backup
        local backup = {
            version = STATE_VERSION,
            timestamp = msg.Timestamp,
            users = Users,
            balances = Balances,
            config = Config
        }

        -- Store backup (could upload to Arweave)
        StateBackups = StateBackups or {}
        table.insert(StateBackups, backup)

        -- Perform migration
        -- ... migration logic ...

        ao.send({
            Target = msg.From,
            Action = "Backup-Created",
            BackupId = tostring(#StateBackups)
        })
    end
)
```

---

## Q10: Testing and Debugging AO Processes

### Local Development Workflows

**Option 1: aolite (Recommended)**
```lua
-- aolite_test.lua
local aolite = require('aolite')

-- Load your process code
local myProcess = aolite.spawnProcess('my_process.lua')

-- Send test messages
aolite.send(nil, myProcess, {
    From = "test-user",
    Action = "CreateUser",
    Name = "Alice"
})

-- Run scheduler to process messages
aolite.runScheduler()

-- Inspect state directly
print("Users:", json.encode(myProcess.Users))

-- Send another message
aolite.send(nil, myProcess, {
    From = "test-user",
    Action = "GetUser",
    UserId = "user-1"
})

aolite.runScheduler()

-- Check messages
local messages = aolite.getAllMsgs(myProcess)
for _, msg in ipairs(messages) do
    print("Message:", msg.Action, msg.Data)
end
```

**Option 2: aos CLI (Interactive)**
```bash
# Start aos session
aos my-test-process

# Load your code
.load my_process.lua

# Manually test handlers
.send({Action = "CreateUser", Name = "Alice"})

# Check state
Users

# Enable debug logging
ApusAI_Debug = true

# Test with real Apus integration
ApusAI = require('@apus/ai')
ApusAI.infer("Test prompt")
```

### Testing Frameworks

**aolite Configuration:**
```lua
-- test_runner.lua
local aolite = require('aolite')

-- Enable detailed logging
aolite.setMessageLog(3)  -- 0=off, 1=basic, 2=detailed, 3=verbose

-- Test suite
local tests = {}

function tests.testUserCreation()
    local process = aolite.spawnProcess('my_process.lua')

    aolite.send(nil, process, {
        From = "test-user",
        Action = "CreateUser",
        Name = "Alice",
        Email = "alice@example.com"
    })

    aolite.runScheduler()

    -- Assert state
    assert(process.Users["test-user"], "User should be created")
    assert(process.Users["test-user"].Name == "Alice", "Name should match")

    print("✅ testUserCreation passed")
end

function tests.testInsufficientBalance()
    local process = aolite.spawnProcess('token_process.lua')

    aolite.send(nil, process, {
        From = "user-1",
        Action = "Transfer",
        Recipient = "user-2",
        Quantity = "1000"
    })

    aolite.runScheduler()

    local messages = aolite.getAllMsgs(process)
    local errorFound = false

    for _, msg in ipairs(messages) do
        if msg.Action == "Error" then
            errorFound = true
        end
    end

    assert(errorFound, "Should return error for insufficient balance")
    print("✅ testInsufficientBalance passed")
end

-- Run all tests
for name, test in pairs(tests) do
    print("Running", name)
    test()
end

print("\n✅ All tests passed")
```

### Debugging Capabilities

**Built-In Debugging:**
```lua
-- Print debugging
Handlers.add("debug-handler",
    { Action = "TestAction" },
    function(msg)
        print("Debug: Received message from " .. msg.From)
        print("Debug: Action = " .. msg.Action)
        print("Debug: Data = " .. (msg.Data or "nil"))

        -- Inspect tables
        print("Debug: Current state:", json.encode(Users))

        -- Process logic
        local result = processData(msg.Data)
        print("Debug: Result =", json.encode(result))

        ao.send({Target = msg.From, Action = "Response", Data = json.encode(result)})
    end
)
```

**Conditional Debugging:**
```lua
DEBUG_MODE = DEBUG_MODE or false

function debugLog(...)
    if DEBUG_MODE then
        print("[DEBUG]", ...)
    end
end

Handlers.add("with-debug-logs",
    { Action = "ProcessData" },
    function(msg)
        debugLog("Processing data from", msg.From)
        debugLog("Input:", msg.Data)

        local result = processData(msg.Data)

        debugLog("Output:", json.encode(result))

        ao.send({Target = msg.From, Action = "Result", Data = json.encode(result)})
    end
)

-- Enable debug mode
Handlers.add("enable-debug",
    { Action = "EnableDebug" },
    function(msg)
        if msg.From == OWNER then
            DEBUG_MODE = true
            ao.send({Target = msg.From, Action = "Debug-Enabled"})
        end
    end
)
```

### Error Logging and Monitoring

**Structured Error Logging:**
```lua
ErrorLog = ErrorLog or {}

function logError(source, error, context)
    table.insert(ErrorLog, {
        timestamp = os.time(),
        source = source,
        error = tostring(error),
        context = context
    })

    print("[ERROR]", source, error)
end

Handlers.add("with-error-logging",
    { Action = "ProcessData" },
    function(msg)
        local success, result = pcall(processData, msg.Data)

        if not success then
            logError("ProcessData", result, {
                user = msg.From,
                data = msg.Data,
                messageId = msg.Id
            })

            ao.send({
                Target = msg.From,
                Action = "Error",
                Error = "Processing failed"
            })
            return
        end

        ao.send({Target = msg.From, Action = "Success", Data = json.encode(result)})
    end
)

-- Query error log
Handlers.add("get-errors",
    { Action = "GetErrors" },
    function(msg)
        ao.send({
            Target = msg.From,
            Action = "ErrorLog",
            Data = json.encode(ErrorLog)
        })
    end
)
```

**Performance Monitoring:**
```lua
PerformanceMetrics = PerformanceMetrics or {}

function trackPerformance(operation, startTime, endTime)
    PerformanceMetrics[operation] = PerformanceMetrics[operation] or {
        count = 0,
        totalTime = 0,
        avgTime = 0
    }

    local duration = endTime - startTime
    local metrics = PerformanceMetrics[operation]

    metrics.count = metrics.count + 1
    metrics.totalTime = metrics.totalTime + duration
    metrics.avgTime = metrics.totalTime / metrics.count
end

Handlers.add("monitored-operation",
    { Action = "HeavyOperation" },
    function(msg)
        local startTime = os.clock()

        -- Perform operation
        local result = performHeavyComputation(msg.Data)

        local endTime = os.clock()
        trackPerformance("HeavyOperation", startTime, endTime)

        ao.send({Target = msg.From, Action = "Result", Data = json.encode(result)})
    end
)
```

### Cost Estimation During Development

**Message Cost Estimation:**
```lua
-- Estimate based on data size
function estimateMessageCost(message)
    local dataSize = #(message.Data or "")
    local tagCount = 0
    for _ in pairs(message) do
        tagCount = tagCount + 1
    end

    -- Rough estimation (not actual costs)
    local baseCost = 100  -- Base message cost
    local dataCost = dataSize * 0.1  -- Per byte
    local tagCost = tagCount * 10  -- Per tag

    return baseCost + dataCost + tagCost
end

-- Use in testing
local testMessage = {
    Target = "process-id",
    Action = "Transfer",
    Recipient = "user-id",
    Quantity = "1000",
    Data = "Some data payload"
}

print("Estimated cost:", estimateMessageCost(testMessage))
```

**Apus Cost Estimation:**
```lua
-- Track Apus usage
ApusUsageStats = ApusUsageStats or {
    callCount = 0,
    totalCredits = 0,
    avgTokensPerCall = 0
}

function trackApusUsage(creditsUsed, tokensGenerated)
    ApusUsageStats.callCount = ApusUsageStats.callCount + 1
    ApusUsageStats.totalCredits = ApusUsageStats.totalCredits + creditsUsed
    ApusUsageStats.avgTokensPerCall = tokensGenerated
end

-- Wrapper around ApusAI.infer
function trackedInfer(prompt, options, callback)
    local creditsUsed = 1  -- 1 credit per call

    ApusAI.infer(prompt, options, function(err, result)
        if not err then
            local tokensGenerated = #result  -- Rough estimate
            trackApusUsage(creditsUsed, tokensGenerated)
        end

        if callback then
            callback(err, result)
        end
    end)
end
```

---

## Q11-Q13: Arweave Storage Integration

### Q11: Fetching Arweave Data from AO Processes

**No Direct Arweave Read API in AO:**
- AO processes cannot directly fetch Arweave data
- Must use gateway processes or external services
- Data must be passed via messages

**Pattern 1: Gateway Process**
```lua
GATEWAY_PROCESS = "arweave-gateway-process-id"

Handlers.add("fetch-arweave-data",
    { Action = "FetchArweaveData" },
    function(msg)
        local txId = msg.TxId

        -- Request data from gateway
        ao.send({
            Target = GATEWAY_PROCESS,
            Action = "GetTransaction",
            TxId = txId,
            ["X-Request-Id"] = msg.Id
        })

        -- Store request for response handling
        PendingFetches = PendingFetches or {}
        PendingFetches[msg.Id] = {
            requester = msg.From,
            txId = txId
        }
    end
)

-- Handle gateway response
Handlers.add("gateway-response",
    { Action = "TransactionData" },
    function(msg)
        local requestId = msg["X-Request-Id"]
        local request = PendingFetches[requestId]

        if not request then
            return
        end

        -- Forward data to original requester
        ao.send({
            Target = request.requester,
            Action = "ArweaveData",
            TxId = request.txId,
            Data = msg.Data
        })

        PendingFetches[requestId] = nil
    end
)
```

**Pattern 2: Data Passed at Invocation**
```lua
-- Client sends Arweave data directly in message
Handlers.add("process-with-arweave-data",
    { Action = "ProcessSkill" },
    function(msg)
        -- Skill data provided in message Data field
        local skillData = json.decode(msg.Data)

        -- Verify data integrity (optional: check against Arweave TX ID)
        local expectedTxId = msg.SkillTxId
        -- Could verify hash matches, but typically trust the sender

        -- Use skill data
        local result = executeWithSkill(skillData, msg.Prompt)

        ao.send({
            Target = msg.From,
            Action = "Result",
            Data = json.encode(result)
        })
    end
)
```

**Latency Characteristics:**
- Gateway process: +1-5 seconds for message passing
- Direct Arweave fetch (if available): ~500ms - 2s
- Cached data: Near instant

**Caching Strategies:**
```lua
ArweaveCache = ArweaveCache or {}

Handlers.add("cached-arweave-fetch",
    { Action = "GetArweaveData" },
    function(msg)
        local txId = msg.TxId

        -- Check cache
        if ArweaveCache[txId] then
            ao.send({
                Target = msg.From,
                Action = "ArweaveData",
                TxId = txId,
                Data = ArweaveCache[txId],
                Cached = "true"
            })
            return
        end

        -- Fetch from gateway (not cached)
        ao.send({
            Target = GATEWAY_PROCESS,
            Action = "GetTransaction",
            TxId = txId,
            ["X-Request-Id"] = msg.Id
        })

        PendingFetches = PendingFetches or {}
        PendingFetches[msg.Id] = {requester = msg.From, txId = txId}
    end
)

-- Cache response
Handlers.add("cache-arweave-response",
    { Action = "TransactionData" },
    function(msg)
        local requestId = msg["X-Request-Id"]
        local request = PendingFetches[requestId]

        if not request then
            return
        end

        -- Store in cache
        ArweaveCache[request.txId] = msg.Data

        -- Forward to requester
        ao.send({
            Target = request.requester,
            Action = "ArweaveData",
            TxId = request.txId,
            Data = msg.Data
        })

        PendingFetches[requestId] = nil
    end
)
```

### Q12: Arweave Storage Costs

**Pricing Model:**
- One-time payment for permanent storage
- Cost based on data size (bytes)
- Paid in AR tokens
- No ongoing costs (permanent storage)

**Approximate Costs (as of 2024):**
- ~$5-10 per GB for permanent storage
- Prices vary with AR token price
- Smaller files: minimum transaction cost (~0.0001 AR)

**Optimal File Sizes:**
- Very small (<1 KB): Inefficient (transaction overhead)
- Small (1-100 KB): Good for metadata, configs
- Medium (100 KB - 10 MB): Ideal for most use cases
- Large (>10 MB): Consider chunking or compression

**Bundling Strategies:**
```javascript
// Using permaweb-mcp or Turbo SDK
// Bundle multiple small files into single transaction

const files = [
  { path: 'skill1.json', data: skill1Data },
  { path: 'skill2.json', data: skill2Data },
  { path: 'skill3.json', data: skill3Data }
];

// Upload as bundle (cheaper than 3 separate uploads)
const manifestTxId = await uploadBundle(files);

// Access individual files via manifest
// https://arweave.net/{manifestTxId}/skill1.json
```

**When to Use Arweave vs Process State:**

**Use Arweave for:**
- ✅ Large data (>10 KB)
- ✅ Rarely changing data (skills, configs)
- ✅ Shared data (multiple processes need access)
- ✅ Public data (skills, documentation)
- ✅ Historical records (audit trails)

**Use Process State for:**
- ✅ Frequently changing data (balances, counters)
- ✅ Small data (<1 KB per item)
- ✅ Private data (user secrets, internal state)
- ✅ Temporary data (pending requests)
- ✅ High-frequency updates (real-time state)

**Example Decision Matrix:**
```lua
-- ❌ BAD: Store large skill in process state
Skills = Skills or {}
Skills["skill-1"] = {
    name = "Data Analysis",
    description = "...",
    instructions = "... 50 KB of text ...",
    examples = "... 100 KB of examples ..."
}
-- This bloats process state!

-- ✅ GOOD: Store reference to Arweave TX
Skills = Skills or {}
Skills["skill-1"] = {
    name = "Data Analysis",
    arweaveTxId = "abc123...def789",  -- Just 43 bytes!
    version = "1.0.0",
    uploadedAt = 1699564800
}
-- Fetch full skill data when needed
```

### Q13: Arweave Tags and Querying

**Tag Structure:**
```javascript
// When uploading to Arweave
const tags = [
    { name: 'Content-Type', value: 'application/json' },
    { name: 'App-Name', value: 'Permamind' },
    { name: 'Skill-Type', value: 'data-analysis' },
    { name: 'Version', value: '1.0.0' },
    { name: 'Author', value: 'process-id-or-address' },
    { name: 'Created-At', value: '2024-11-13' }
];
```

**GraphQL Query Patterns:**
```graphql
# Find all Permamind skills
query {
  transactions(
    tags: [
      { name: "App-Name", values: ["Permamind"] }
      { name: "Skill-Type", values: ["data-analysis"] }
    ]
    first: 100
  ) {
    edges {
      node {
        id
        tags {
          name
          value
        }
        owner {
          address
        }
        block {
          timestamp
        }
      }
    }
  }
}
```

**Best Practices for Skill Metadata:**
```javascript
const skillTags = [
    // Required
    { name: 'Content-Type', value: 'application/json' },
    { name: 'App-Name', value: 'Permamind' },
    { name: 'Type', value: 'Skill' },

    // Skill metadata
    { name: 'Skill-Name', value: 'Data Analysis Expert' },
    { name: 'Skill-Category', value: 'data-analysis' },
    { name: 'Skill-Version', value: '1.0.0' },

    // Searchability
    { name: 'Tags', value: 'analysis,data,statistics' },
    { name: 'Description', value: 'Analyzes datasets and provides insights' },

    // Attribution
    { name: 'Author', value: 'author-process-id' },
    { name: 'License', value: 'MIT' },

    // Pricing
    { name: 'Price', value: '1000' },  // In smallest token units
    { name: 'Currency', value: 'process-token-id' }
];
```

**Indexing and Performance:**
- Tags indexed by Arweave gateways
- Fast queries on standard tags
- Complex queries may be slower
- Use specific tags to narrow results
- Avoid queries with too many OR conditions

---

## Phase 2 Summary

### Critical Findings

**AO Lua Runtime (Q6):**
✅ Standard Lua libraries available (string, table, math)
✅ JSON encode/decode built-in
❌ No file I/O, no network access, no os.execute
❌ Must use msg.Timestamp instead of os.time()

**Message Passing (Q7):**
✅ Asynchronous fire-and-forget model
✅ Handlers process messages in order
❌ No delivery guarantees (implement ACKs)
❌ No built-in error responses (must send explicitly)

**State Management (Q9):**
✅ Global variables persist automatically
✅ No hard state size limits
⚠️ Large state impacts performance and costs
✅ Migration strategies available

**Testing (Q10):**
✅ aolite provides local testing
✅ aos CLI for interactive development
⚠️ No built-in unit test framework
✅ Print debugging available

**Arweave Integration (Q11-Q13):**
❌ No direct Arweave read API from processes
✅ Gateway processes or message passing required
✅ One-time payment for permanent storage
✅ Tags enable powerful querying
✅ ~$5-10 per GB storage cost

### Recommended Patterns

**State Management:**
- Use `or {}` pattern for initialization
- Store large data on Arweave (TX IDs in state)
- Implement state versioning for migrations
- Cache frequently accessed Arweave data

**Message Passing:**
- Always send explicit error responses
- Implement request tracking for async operations
- Use X-Request-Id for correlation
- Design for eventual consistency

**Testing:**
- Use aolite for unit testing
- Test error cases and edge conditions
- Monitor performance metrics
- Estimate costs during development

### Architecture Implications for Permamind

**Skill Storage:**
- Store skill content on Arweave (large, permanent)
- Store skill metadata in registry process state (small, searchable)
- Cache popular skills in-process for performance

**Payment Gating:**
- Credit-Notice pattern works well with AO message passing
- Track balances in process state (frequently updated)
- Use message IDs to prevent replay attacks

**AI Inference:**
- ~50s Apus latency + message passing overhead
- Must design for async, non-blocking patterns
- Track inference jobs in process state

**Data Architecture:**
```
User → Registry Process (search skills)
     → Skill Process (payment gate)
     → Fetch skill from Arweave (via gateway or cached)
     → Apus AI Inference (~50s)
     → Response via messages
```

---

## Next Steps

**Phase 3 Focus:**
- SDK architecture patterns (Q14, Q16)
- Token economics and pricing models (Q17-Q19)
- Revenue sharing implementation

**Immediate Actions:**
- Deploy test process with aolite
- Benchmark message passing latency
- Test Arweave data fetching patterns
- Validate state persistence across messages
