# Research Question: Complete Apus SDK API Surface

**Question Number:** Q1
**Phase:** 1 (Critical Path)
**Priority:** Critical
**Status:** Complete
**Researcher:** Claude
**Date:** 2025-11-13

## Original Research Question

What is the complete Apus SDK API surface?
- Available functions and their signatures
- How to initialize and configure Apus within AO processes
- Authentication/authorization mechanisms
- Error handling patterns

## Answer Summary

The Apus AI SDK provides a Lua library (`@apus/ai`) with a simple API for AI inference within AO processes. The SDK handles message passing with the Apus AI Router Process (`TED2PpCVx0KbkQtzEYBo0TRAO-HPJlpCMmUzch9ZL2g`) and supports both simple synchronous calls and callback-based asynchronous patterns.

## Detailed Findings

### Installation & Setup

**Installation via APM (AO Package Manager):**
```lua
-- 1. Load APM blueprint
.load-blueprint apm

-- 2. Install Apus AI library (wait ~2 minutes for APM to load)
apm.install "@apus/ai"

-- 3. Require the library in your process
ApusAI = require('@apus/ai')
```

**Environment Requirements:**
- Runs on AO Legacy Network (`aos your_process`)
- Requires APM for installation
- Process must have credits to make inference calls

### Core API Functions

#### ApusAI.initialize()
**Purpose:** Initializes the SDK (optional - automatically called on first use)

**Signature:**
```lua
ApusAI.initialize()
```

**Returns:** void

**When to use:** Typically not needed - SDK auto-initializes

#### ApusAI.infer(prompt, [options], [callback])
**Purpose:** Send AI inference request to Apus Network

**Signature:**
```lua
ApusAI.infer(prompt, [options], [callback])
```

**Parameters:**
- `prompt` (string, required): The input text for AI inference
- `options` (table, optional): Configuration parameters
  - `max_tokens` (integer): Maximum tokens to generate (1-8192, default: 2048)
  - `temperature` (float): Randomness control (0.0-2.0, default: 0.7)
  - `top_p` (float): Nucleus sampling (0.0-1.0, default: 0.9)
- `callback` (function, optional): Async handler receiving `(err, res)`

**Returns:**
- Synchronous mode: Blocks until response received (~50 seconds)
- Async mode: Returns immediately, calls callback when complete

**Examples:**
```lua
-- Simple synchronous call
ApusAI.infer("How are you today?")

-- With options
ApusAI.infer("Translate to French: 'The future is decentralized.'", {
    max_tokens = 512,
    temperature = 0.8
})

-- Asynchronous with callback
ApusAI.infer("What is Arweave?", { max_tokens = 150 }, function(err, res)
    if err then
        print("Error: " .. err.message)
        return
    end
    print("Response: " .. res)
end)
```

#### ApusAI.getBalance()
**Purpose:** Check current credit balance

**Signature:**
```lua
ApusAI.getBalance()
```

**Returns:** Number (credit balance in smallest units)

**Notes:**
- Default balance: 5,000,000,000,000 units (5 credits = 5 inference calls)
- Credits are non-transferable between processes

### Authentication/Authorization

**Credit-Based System:**
- Each process has its own credit balance
- Credits purchased by transferring $APUS tokens to Router Process
- No API keys or external authentication required
- Process ID serves as identity

**Purchasing Credits:**
```lua
ao.send({
    Target = "mqBYxpDsolZmJyBdTK8TJp_ftOuIUXVYcSQ8MYZdJg0", -- $APUS Token Process
    Recipient = "TED2PpCVx0KbkQtzEYBo0TRAO-HPJlpCMmUzch9ZL2g", -- AI Router Process
    Action = "Transfer",
    Quantity = "1000000000000", -- 1 $APUS token (10^12 Armstrongs)
    ["X-Reason"] = "Buy-Credits"
})
```

**Credit Exchange Rate:**
- Based on current market rate (dynamic)
- 1 credit ≈ 1 inference call
- Default test credits: 5 per new process

### Direct API (Advanced - Without @apus/ai Library)

**Router Process ID:** `TED2PpCVx0KbkQtzEYBo0TRAO-HPJlpCMmUzch9ZL2g`

**Inference Request Message:**
```lua
ao.send({
    Target = "TED2PpCVx0KbkQtzEYBo0TRAO-HPJlpCMmUzch9ZL2g",
    Action = "Infer",
    Data = "Your prompt here",
    ["X-Reference"] = "unique-request-id-123",  -- Recommended for tracking
    ["X-Session"] = "session-id",                -- Optional for conversation continuity
    ["X-Options"] = '{"temperature": 0.8, "max_tokens": 150}'  -- JSON string
})
```

**Response Handler:**
```lua
Handlers.add(
    "AcceptResponse",
    { Action = "Infer-Response" },
    function (msg)
        -- Check for errors
        if msg.Code then
            print("Error Code: " .. msg.Code)
            print("Error Message: " .. msg.Data)
            return
        end

        -- Parse successful response
        local response = json.decode(msg.Data)
        print("AI Result: " .. response.result)
        print("Attestation: " .. response.attestation)  -- GPU verification
        print("Session ID: " .. msg["X-Session"])
        print("Reference ID: " .. msg["X-Reference"])
    end
)
```

### Configuration Options

**Debug Mode:**
```lua
-- Enable inference result logging
ApusAI_Debug = true
```

**Inference Parameters (X-Options):**
| Parameter | Type | Default | Range | Description |
|-----------|------|---------|-------|-------------|
| `temperature` | float | 0.7 | 0.0 - 2.0 | Controls randomness (lower = deterministic, higher = creative) |
| `top_p` | float | 0.9 | 0.0 - 1.0 | Nucleus sampling (probability mass cutoff) |
| `max_tokens` | integer | 2048 | 1 - 8192 | Maximum tokens in response |

## Code Examples

### Basic Integration
```lua
-- Load library
ApusAI = require('@apus/ai')

-- Enable debug logging
ApusAI_Debug = true

-- Check balance
local balance = ApusAI.getBalance()
print("Credits: " .. balance)

-- Simple inference
ApusAI.infer("What is Arweave?")
```

### Advanced Integration with Error Handling
```lua
local ApusAI = require('@apus/ai')

-- Handler for asynchronous inference
Handlers.add("run-inference",
    Handlers.utils.hasMatchingTag("Action", "RunInference"),
    function(msg)
        local prompt = msg.Data

        if not prompt or prompt == "" then
            ao.send({
                Target = msg.From,
                Action = "Error",
                Error = "Prompt required in Data field"
            })
            return
        end

        -- Async inference with callback
        ApusAI.infer(prompt, {
            max_tokens = 500,
            temperature = 0.7
        }, function(err, result)
            if err then
                ao.send({
                    Target = msg.From,
                    Action = "Error",
                    Error = err.message
                })
                return
            end

            ao.send({
                Target = msg.From,
                Action = "InferenceResult",
                Data = result
            })
        end)
    end
)
```

## Data & Metrics

| Metric | Value | Source |
|--------|-------|--------|
| Default inference timeout | ~50 seconds | Apus Docs |
| Default test credits | 5,000,000,000,000 units | API Reference |
| Inference calls per credit | 1 | Apus Docs |
| Max tokens per request | 8,192 | API Reference |
| Default max tokens | 2,048 | API Reference |
| Model | Gemma3-27B | API Reference |

## Limitations & Constraints

### Hard Limitations
- Maximum 8,192 tokens per response
- Single model available (Gemma3-27B)
- Credits non-transferable between processes
- No streaming responses (single response after completion)
- Requires AO Legacy Network (not HyperBEAM for client processes)

### Soft Limitations
- ~50 second latency per inference call (may vary)
- APM installation can take ~2 minutes
- Must wait for response before next call (in simple mode)
- Limited to text-based inference (no vision/audio models documented)

## Security Considerations

**Credit System Security:**
- Each process has isolated credit balance
- Cannot drain credits from other processes
- Transfer requires explicit $APUS token payment

**Message Authentication:**
- All requests authenticated via AO message signatures
- Process ID serves as identity
- No risk of impersonation (cryptographic signatures)

**GPU Attestation:**
- Responses include attestation data for verification
- Enables trustless verification of computation
- Part of deterministic GPU computing vision

## Cost Implications

**Credit Costs:**
- 1 credit = 1 inference call
- Credit price determined by $APUS token exchange rate
- No additional fees beyond credit consumption

**Development Costs:**
- Test credits (5) provided free for new processes
- Additional credits via Discord application (hackathon)
- Production: purchase via $APUS token transfers

## Recommendations

### Do This
✅ Use `@apus/ai` library for simplicity (recommended for most use cases)
✅ Implement callback-based async patterns for better UX
✅ Check balance before making inference calls
✅ Use `X-Reference` tags for tracking requests
✅ Enable debug mode during development
✅ Implement proper error handling for failed inferences
✅ Use `X-Session` for multi-turn conversations

### Avoid This
❌ Don't use blocking synchronous calls in production handlers
❌ Don't assume instant responses (allow ~50s latency)
❌ Don't make calls without checking credit balance first
❌ Don't ignore error responses from callbacks
❌ Don't use extremely high max_tokens without justification (costs credits)

## Sources & References

1. **Apus AI Lua SDK GitHub** - https://github.com/apuslabs/ao-ai-lua-sdk
   - Installation instructions and basic API usage

2. **Apus Network Documentation** - https://docs.apus.network/sdk/introduction
   - 5-minute quick start guide and integration patterns

3. **Apus Full API Reference** - https://docs.apus.network/sdk/api-reference
   - Complete API specification, parameters, and advanced usage

4. **APM Package** - `@apus/ai`
   - Lua library for simplified Apus integration

## Validation & Testing

- [x] Finding validated with official documentation
- [x] Code examples tested via documentation review
- [x] Multiple sources confirm finding (GitHub + Docs + API Reference)
- [ ] Community validation obtained (pending)
- [ ] Hands-on experimentation completed (pending - requires deployment)

## Related Questions

- Q2: Available AI models and capabilities
- Q3: Pricing and cost structure
- Q4: Performance limits and constraints
- Q5: Integration with AO message passing

## Open Questions

- What is the exact credit-to-$APUS exchange rate formula?
- Are there rate limits beyond credit consumption?
- Will additional models be available in the future?
- Can inference be canceled mid-execution?
- What happens if Router Process is unreachable?

## Last Updated

2025-11-13

---

## Research Notes

The Apus SDK is remarkably simple - just 3 main functions (initialize, infer, getBalance). The library abstracts away the complexity of message passing with the Router Process. The direct API (without library) provides more control but requires handling message responses manually.

Key insight: The credit system is elegant - it's just token transfers to a router process, making it fully on-chain and auditable. The ~50s latency is notable and should inform UX design for Permamind.
