# Nillion

A comprehensive skill for building privacy-preserving applications on the Nillion secure computation network using blind computation, encrypted storage, and confidential AI.

## Overview

Nillion is humanity's first "blind computer" - a secure computation network that decentralizes trust for high-value, sensitive, and private data. It enables developers to build applications that compute on encrypted data without ever decrypting it, using advanced privacy-enhancing technologies including:

- **Secure Multi-Party Computation (MPC)**: Enable multiple parties to jointly compute on private data
- **Homomorphic Encryption (HE)**: Perform computations on encrypted data
- **Trusted Execution Environments (TEEs)**: Hardware-guaranteed privacy with cryptographic attestation

This skill enables you to build privacy-preserving applications with:
- Private data storage that remains encrypted
- Confidential AI inference without exposing model or data
- Multi-party computations where no single party sees all data
- Secure credential management and access control

---

## Core Concepts

### Nillion Network Architecture

Nillion provides three core infrastructure components:

1. **nilDB**: Secure NoSQL database nodes for encrypted data storage
2. **nilAI**: Secure AI inference nodes running models in TEEs
3. **nilCC**: Confidential compute nodes for arbitrary Docker workloads
4. **nilChain**: Blockchain payment network for service access
5. **NIL**: Native token used to pay for network services

### Blind Computation

Blind computation is Nillion's core principle - programs compute on data in a way that ensures they are "blind" to the underlying sensitive information. The computation happens without any party (including the compute provider) being able to access or view the secret inputs.

### Key Terminology

- **Party**: A participant in a Nada program (e.g., data provider, compute requester)
- **Secret**: Encrypted data stored on or used by the network (SecretInteger, SecretBlob)
- **Nada Program**: MPC programs written in Nada DSL for secure computation
- **Store ID**: Unique identifier for stored secrets on the network
- **Program ID**: Unique identifier for compiled Nada programs
- **Permissions**: Access controls for retrieve/update/delete/compute operations
- **SecretBlob**: Encrypted 1MB data chunks for large data or AI models
- **Collection**: Schema-based data structure for organizing secrets in nilDB

### Developer Solutions

Nillion provides three main solutions:

**Private Storage (nilDB)**
- Store up to 1MB encrypted data per blob
- NoSQL-style collections with schemas
- Fine-grained permissions and access control
- Ideal for: healthcare records, credentials, sensitive documents

**Private LLMs (nilAI)**
- OpenAI-compatible API for private AI inference
- Models run in hardware TEEs
- Input/output data never exposed
- Ideal for: confidential analysis, private chatbots, sensitive data processing

**Confidential Compute (nilCC)**
- Run arbitrary Docker containers in TEEs
- Cryptographic attestation of execution
- Full application privacy
- Ideal for: proprietary algorithms, multi-party workflows, compliance requirements

---

## 1. Client & Configuration

### Installation

**Python Client:**

```bash
# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install Nillion Python client
pip install py-nillion-client
```

**TypeScript/JavaScript Client:**

```bash
# Install Nillion client packages
npm install @nillion/client-vms @nillion/client-react-hooks

# For Next.js applications
npx create-nillion-app my-app
```

**Nada Development Tools:**

```bash
# Install Nada compiler and tools
pip install nada-dsl

# Verify installation
nada --version
```

### Python Client Setup

```python
import os
import asyncio
from py_nillion_client import (
    NodeKey,
    UserKey,
    NillionClient,
    VmClient,
)

async def create_nillion_client():
    """Initialize Nillion client with user and node keys."""

    # Generate or load user key (private key for the user)
    userkey = UserKey.from_seed("my_user_seed")

    # Generate or load node key
    nodekey = NodeKey.from_seed("my_node_seed")

    # Connect to Nillion devnet
    client = await VmClient.create(
        userkey,
        nodekey,
        bootnodes=["/dns/node-1.devnet.nillion.com/tcp/14211"],
        chain_id="nillion-chain-devnet-1"
    )

    return client

# Usage
async def main():
    client = await create_nillion_client()
    print(f"User ID: {client.user_id}")
    print(f"Connected to Nillion network")

if __name__ == "__main__":
    asyncio.run(main())
```

### TypeScript/React Client Setup

```typescript
'use client';

import { useEffect, useState } from 'react';
import { NillionProvider, createClient } from '@nillion/client-react-hooks';
import type { VmClient } from '@nillion/client-vms';

export default function NillionApp() {
  const [client, setClient] = useState<VmClient>();

  useEffect(() => {
    const initClient = async () => {
      // Initialize Nillion client
      const nillionClient = await createClient({
        network: 'devnet', // or 'testnet', 'mainnet'
        userSeed: 'my_user_seed',
        nodeSeed: 'my_node_seed',
      });

      setClient(nillionClient);
      console.log('User ID:', nillionClient.userId);
    };

    initClient();
  }, []);

  if (!client) {
    return <div>Connecting to Nillion...</div>;
  }

  return (
    <NillionProvider client={client}>
      <YourApp />
    </NillionProvider>
  );
}
```

### Environment Configuration

```bash
# .env file for Nillion configuration

# Network configuration
NILLION_NETWORK=devnet  # devnet, testnet, or mainnet
NILLION_CHAIN_ID=nillion-chain-devnet-1

# Client seeds (use secure generation in production!)
NILLION_USER_SEED=your_secure_user_seed_here
NILLION_NODE_SEED=your_secure_node_seed_here

# Bootnode addresses (devnet example)
NILLION_BOOTNODE=/dns/node-1.devnet.nillion.com/tcp/14211

# nilPay subscription (for production)
NILLION_SUBSCRIPTION_ID=your_subscription_id
```

### Configuration Best Practices

1. **Multiple Bootnodes**: Configure 2-3 bootnodes for redundancy
2. **Secure Key Storage**: Never commit seeds/keys to version control
3. **Network Selection**: Start with devnet, move to testnet before mainnet
4. **Client Reuse**: Create client once and reuse across operations
5. **Error Handling**: Always wrap client operations in try/catch blocks

---

## 2. Nada Programs (Privacy-Preserving Computation)

### What is Nada?

Nada is a Python-based DSL (Domain-Specific Language) for writing Multi-Party Computation (MPC) programs. Nada programs define computations that can be executed on secret data without revealing the underlying values.

### Basic Nada Program Structure

```python
from nada_dsl import *

def nada_main():
    # 1. Define parties
    party1 = Party(name="Party1")
    party2 = Party(name="Party2")

    # 2. Define secret inputs
    secret_a = SecretInteger(Input(name="a", party=party1))
    secret_b = SecretInteger(Input(name="b", party=party2))

    # 3. Perform computation
    result = secret_a + secret_b

    # 4. Return output
    return [Output(result, "sum", party1)]
```

### Nada Data Types

```python
from nada_dsl import *

def nada_main():
    party = Party(name="DataProvider")

    # Integer types
    secret_int = SecretInteger(Input(name="int_value", party=party))
    public_int = PublicInteger(Input(name="public_value", party=party))

    # Unsigned integer
    secret_uint = SecretUnsignedInteger(Input(name="uint_value", party=party))

    # Boolean
    secret_bool = SecretBoolean(Input(name="bool_value", party=party))

    # For large data (up to 1MB)
    # SecretBlob is used via the client API, not directly in Nada programs

    return [Output(secret_int, "output", party)]
```

### Nada Operations

```python
from nada_dsl import *

def nada_main():
    alice = Party(name="Alice")
    bob = Party(name="Bob")

    a = SecretInteger(Input(name="a", party=alice))
    b = SecretInteger(Input(name="b", party=bob))

    # Arithmetic operations
    sum_result = a + b
    diff = a - b
    product = a * b
    quotient = a / b
    power = a ** 2

    # Comparison operations (return SecretBoolean)
    is_equal = a == b
    is_greater = a > b
    is_less = a < b
    is_gte = a >= b
    is_lte = a <= b

    # Logical operations (on SecretBoolean)
    logical_and = is_equal & is_greater
    logical_or = is_equal | is_greater
    logical_not = ~is_equal

    # Conditional operations
    max_value = a.if_else(a > b, a, b)

    return [
        Output(sum_result, "sum", alice),
        Output(is_greater, "a_greater_than_b", alice)
    ]
```

### Multi-Party Computation Example

**Millionaires' Problem**: Two parties want to know who is richer without revealing their actual wealth.

```python
# programs/millionaires.py
from nada_dsl import *

def nada_main():
    # Define the two parties
    alice = Party(name="Alice")
    bob = Party(name="Bob")

    # Each party provides their wealth as a secret
    alice_wealth = SecretInteger(Input(name="alice_wealth", party=alice))
    bob_wealth = SecretInteger(Input(name="bob_wealth", party=bob))

    # Compute who is richer (returns SecretBoolean)
    alice_is_richer = alice_wealth > bob_wealth

    # Both parties receive the result
    return [
        Output(alice_is_richer, "alice_is_richer", alice),
        Output(alice_is_richer, "alice_is_richer", bob)
    ]
```

### Nada with Arrays (Nada Numpy)

```python
from nada_dsl import *
import nada_numpy as na

def nada_main():
    # Define parties
    parties = na.parties(3)

    # Create secret arrays
    array_a = na.array([3], parties[0], "A", SecretInteger)
    array_b = na.array([3], parties[1], "B", SecretInteger)

    # Array operations
    result = array_a + array_b
    dot_product = na.dot(array_a, array_b)

    # Output to third party
    return result.output(parties[2], "sum_array")
```

### Creating and Compiling Nada Projects

```bash
# Create new Nada project
nada init my-nada-project
cd my-nada-project

# Project structure:
# my-nada-project/
#   ├── nada-project.toml
#   ├── src/
#   │   └── my_program.py
#   └── tests/

# Compile Nada programs
nada build

# Test Nada program
nada test my_program

# Generate test file
nada generate-test --test-name my_test my_program
```

### Testing Nada Programs

```yaml
# tests/my_program.yaml
---
program: my_program
inputs:
  secrets:
    party1:
      a: "42"
    party2:
      b: "8"
expected_outputs:
  sum: "50"
```

```bash
# Run the test
nada test my_program
```

---

## 3. Data Storage & Retrieval

### Storing Secrets

**Python Example:**

```python
import asyncio
from py_nillion_client import (
    VmClient,
    SecretInteger,
    SecretBlob,
    Permissions,
)

async def store_secret_example(client: VmClient):
    """Store a secret integer on Nillion network."""

    # Create a secret
    secret_value = SecretInteger(42)

    # Define permissions
    permissions = Permissions.default_for_user(client.user_id)

    # Grant another user retrieve permissions
    other_user_id = "other_user_id_here"
    permissions.add_retrieve_permissions([other_user_id])

    # Store the secret
    store_id = await client.store_secrets(
        {
            "my_secret_number": secret_value
        },
        permissions=permissions
    )

    print(f"Secret stored with ID: {store_id}")
    return store_id

async def store_blob_example(client: VmClient):
    """Store a blob (large data) on Nillion network."""

    # Read file data (up to 1MB)
    with open("sensitive_data.txt", "rb") as f:
        blob_data = f.read()

    secret_blob = SecretBlob(blob_data)

    permissions = Permissions.default_for_user(client.user_id)

    store_id = await client.store_secrets(
        {
            "my_data_blob": secret_blob
        },
        permissions=permissions
    )

    return store_id
```

**TypeScript/React Example:**

```typescript
import { useNillion } from '@nillion/client-react-hooks';

function StoreSecretComponent() {
  const { client } = useNillion();

  const storeSecret = async () => {
    if (!client) return;

    // Create secret
    const secret = {
      name: 'my_secret',
      value: 42,
      type: 'SecretInteger'
    };

    // Define permissions
    const permissions = {
      retrieve: [client.userId],
      update: [client.userId],
      delete: [client.userId],
      compute: {}
    };

    // Store the secret
    const storeId = await client.storeSecrets({
      secrets: { my_secret: secret },
      permissions: permissions
    });

    console.log('Stored with ID:', storeId);
    return storeId;
  };

  return (
    <button onClick={storeSecret}>
      Store Secret
    </button>
  );
}
```

### Retrieving Secrets

**Python Example:**

```python
async def retrieve_secret_example(
    client: VmClient,
    store_id: str,
    secret_name: str
):
    """Retrieve a previously stored secret."""

    try:
        # Retrieve the secret
        secret_value = await client.retrieve_secret(
            store_id=store_id,
            secret_name=secret_name
        )

        print(f"Retrieved secret: {secret_value}")
        return secret_value

    except Exception as e:
        print(f"Failed to retrieve secret: {e}")
        # User may not have retrieve permissions
        raise
```

**TypeScript Example:**

```typescript
import { useNillion } from '@nillion/client-react-hooks';

function RetrieveSecretComponent({ storeId }: { storeId: string }) {
  const { client } = useNillion();
  const [secretValue, setSecretValue] = useState<number | null>(null);

  const retrieveSecret = async () => {
    if (!client) return;

    try {
      const value = await client.retrieveSecret({
        storeId: storeId,
        secretName: 'my_secret'
      });

      setSecretValue(value);
    } catch (error) {
      console.error('Failed to retrieve:', error);
    }
  };

  return (
    <div>
      <button onClick={retrieveSecret}>Retrieve Secret</button>
      {secretValue && <p>Secret value: {secretValue}</p>}
    </div>
  );
}
```

### Managing Secret Lifecycle

```python
async def update_secret(
    client: VmClient,
    store_id: str,
    secret_name: str,
    new_value: int
):
    """Update an existing secret."""

    new_secret = SecretInteger(new_value)

    await client.update_secrets(
        store_id=store_id,
        secrets={secret_name: new_secret}
    )

    print(f"Secret {secret_name} updated")

async def delete_secret(
    client: VmClient,
    store_id: str
):
    """Delete a stored secret."""

    await client.delete_secrets(store_id=store_id)
    print(f"Secrets at {store_id} deleted")
```

---

## 4. Compute Operations

### Storing and Running Nada Programs

**Python Example - Complete Workflow:**

```python
import asyncio
from py_nillion_client import VmClient, SecretInteger, Permissions

async def compute_workflow_example(client: VmClient):
    """Complete workflow: store program, store secrets, compute."""

    # Step 1: Store the Nada program
    with open("target/my_program.nada.bin", "rb") as f:
        program_mir = f.read()

    program_id = await client.store_program(
        name="my_program",
        program_mir=program_mir
    )
    print(f"Program stored with ID: {program_id}")

    # Step 2: Store secrets
    alice_secret = SecretInteger(10)
    permissions = Permissions.default_for_user(client.user_id)
    permissions.add_compute_permissions({
        program_id: [client.user_id]
    })

    store_id = await client.store_secrets(
        {
            "alice_input": alice_secret
        },
        permissions=permissions
    )
    print(f"Secrets stored with ID: {store_id}")

    # Step 3: Run computation
    compute_bindings = {
        "alice_input": store_id  # Reference stored secret
    }

    result = await client.compute(
        program_id=program_id,
        compute_bindings=compute_bindings,
        store_ids=[store_id]
    )

    print(f"Computation result: {result}")
    return result
```

### Multi-Party Compute

```python
async def multi_party_compute_example():
    """Example with multiple parties providing inputs."""

    # Party 1: Alice
    alice_client = await create_nillion_client()
    alice_secret = SecretInteger(50000)  # Alice's wealth

    alice_permissions = Permissions.default_for_user(alice_client.user_id)
    alice_permissions.add_compute_permissions({
        program_id: [alice_client.user_id, bob_user_id]
    })

    alice_store_id = await alice_client.store_secrets(
        {"alice_wealth": alice_secret},
        permissions=alice_permissions
    )

    # Party 2: Bob
    bob_client = await create_nillion_client()
    bob_secret = SecretInteger(75000)  # Bob's wealth

    bob_permissions = Permissions.default_for_user(bob_client.user_id)
    bob_permissions.add_compute_permissions({
        program_id: [alice_client.user_id, bob_client.user_id]
    })

    bob_store_id = await bob_client.store_secrets(
        {"bob_wealth": bob_secret},
        permissions=bob_permissions
    )

    # Either party can run the computation
    compute_bindings = {
        "alice_wealth": alice_store_id,
        "bob_wealth": bob_store_id
    }

    result = await alice_client.compute(
        program_id=program_id,
        compute_bindings=compute_bindings,
        store_ids=[alice_store_id, bob_store_id]
    )

    # Result: who is richer?
    print(f"Alice is richer: {result['alice_is_richer']}")
```

### Compute with Runtime Secrets

```python
async def compute_with_runtime_secrets(
    client: VmClient,
    program_id: str
):
    """Run computation with secrets provided at runtime."""

    # Provide secrets directly without storing
    runtime_secrets = {
        "input_a": SecretInteger(100),
        "input_b": SecretInteger(200)
    }

    result = await client.compute(
        program_id=program_id,
        runtime_secrets=runtime_secrets
    )

    return result
```

### Handling Compute Results

```python
async def process_compute_results(result):
    """Process and extract values from compute results."""

    # Results are returned as a dictionary
    for output_name, output_value in result.items():
        print(f"{output_name}: {output_value}")

        # Type conversion
        if isinstance(output_value, int):
            # SecretInteger result
            integer_result = output_value
        elif isinstance(output_value, bool):
            # SecretBoolean result
            boolean_result = output_value
        elif isinstance(output_value, bytes):
            # SecretBlob result
            blob_result = output_value

    return result
```

---

## 5. Permissions & Access Control

### Permission Types

Nillion supports four types of permissions for stored secrets:

1. **Retrieve**: Read secret values
2. **Update**: Modify secret values
3. **Delete**: Remove secrets from storage
4. **Compute**: Use secrets in specific program executions

### Setting Default Permissions

```python
from py_nillion_client import Permissions

# Create permissions with default user
permissions = Permissions.default_for_user(user_id)

# This user automatically gets retrieve and update permissions
```

### Granting Permissions

```python
async def grant_permissions_example(client: VmClient):
    """Grant various permissions to other users."""

    permissions = Permissions.default_for_user(client.user_id)

    # Grant retrieve permissions
    researcher_id = "researcher_user_id"
    permissions.add_retrieve_permissions([researcher_id])

    # Grant update permissions
    admin_id = "admin_user_id"
    permissions.add_update_permissions([admin_id])

    # Grant delete permissions
    permissions.add_delete_permissions([admin_id])

    # Grant compute permissions for specific programs
    program_id = "program_abc123"
    analyst_id = "analyst_user_id"
    permissions.add_compute_permissions({
        program_id: [analyst_id, researcher_id]
    })

    # Store secret with these permissions
    secret = SecretInteger(42)
    store_id = await client.store_secrets(
        {"sensitive_data": secret},
        permissions=permissions
    )

    return store_id
```

### Updating Permissions

```python
async def update_permissions_example(
    client: VmClient,
    store_id: str
):
    """Update permissions for already stored secrets."""

    # Revoke retrieve permission
    user_to_revoke = "user_id_to_revoke"

    await client.revoke_retrieve_permissions(
        store_id=store_id,
        user_ids=[user_to_revoke]
    )

    # Grant new compute permission
    new_program_id = "new_program_xyz"
    new_user_id = "new_analyst_id"

    await client.grant_compute_permissions(
        store_id=store_id,
        program_id=new_program_id,
        user_ids=[new_user_id]
    )
```

### Permission Patterns

**Pattern 1: Data Owner with Multiple Analysts**

```python
async def data_owner_pattern(client: VmClient):
    """Owner stores data, grants compute-only to analysts."""

    permissions = Permissions.default_for_user(client.user_id)

    # Analysts can only compute, not retrieve raw data
    analyst_ids = ["analyst_1", "analyst_2", "analyst_3"]
    approved_program = "statistical_analysis_program"

    permissions.add_compute_permissions({
        approved_program: analyst_ids
    })

    # Owner retains full control
    store_id = await client.store_secrets(
        {"patient_data": SecretInteger(medical_value)},
        permissions=permissions
    )

    return store_id
```

**Pattern 2: Collaborative Multi-Party**

```python
async def collaborative_pattern():
    """Multiple parties with symmetric permissions."""

    # All parties can compute with each other's data
    party_ids = ["party_a", "party_b", "party_c"]
    collaboration_program = "joint_analysis"

    permissions = Permissions.default_for_user(party_ids[0])
    permissions.add_compute_permissions({
        collaboration_program: party_ids
    })

    # Each party stores their data with same permissions
    # This enables true multi-party computation
```

**Pattern 3: Secure Credential Vault**

```python
async def credential_vault_pattern(client: VmClient):
    """Store credentials with strict access control."""

    permissions = Permissions.default_for_user(client.user_id)

    # Only allow specific authentication program to access
    auth_program_id = "secure_auth_check"
    service_id = "authentication_service"

    permissions.add_compute_permissions({
        auth_program_id: [service_id]
    })

    # No retrieve permissions - credentials never exposed
    credential_blob = SecretBlob(b"sensitive_api_key")

    store_id = await client.store_secrets(
        {"api_credential": credential_blob},
        permissions=permissions
    )

    return store_id
```

---

## 6. Integration Patterns

### Web3 Integration with Wallet Connection

```typescript
import { useNillion } from '@nillion/client-react-hooks';
import { useWallet } from '@solana/wallet-adapter-react';

function Web3NillionIntegration() {
  const { client } = useNillion();
  const { publicKey, signMessage } = useWallet();

  const storeWithWallet = async () => {
    if (!client || !publicKey) return;

    // Use wallet public key as part of permissions
    const walletBasedPermissions = {
      retrieve: [publicKey.toString()],
      update: [publicKey.toString()],
      compute: {}
    };

    const secret = { value: 42, type: 'SecretInteger' };

    const storeId = await client.storeSecrets({
      secrets: { wallet_secret: secret },
      permissions: walletBasedPermissions
    });

    return storeId;
  };

  return <button onClick={storeWithWallet}>Store with Wallet</button>;
}
```

### Backend API Integration (Express + Python)

**Express Backend:**

```typescript
import express from 'express';
import { createClient } from '@nillion/client-vms';

const app = express();
app.use(express.json());

let nillionClient: VmClient;

// Initialize Nillion client on server start
async function initNillion() {
  nillionClient = await createClient({
    network: process.env.NILLION_NETWORK || 'devnet',
    userSeed: process.env.NILLION_USER_SEED!,
    nodeSeed: process.env.NILLION_NODE_SEED!,
  });
}

// API endpoint to store data
app.post('/api/store-secret', async (req, res) => {
  try {
    const { secretName, secretValue, userId } = req.body;

    const permissions = {
      retrieve: [userId],
      update: [userId],
      compute: {}
    };

    const storeId = await nillionClient.storeSecrets({
      secrets: { [secretName]: { value: secretValue, type: 'SecretInteger' } },
      permissions
    });

    res.json({ success: true, storeId });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// API endpoint to compute
app.post('/api/compute', async (req, res) => {
  try {
    const { programId, storeIds } = req.body;

    const result = await nillionClient.compute({
      programId,
      storeIds
    });

    res.json({ success: true, result });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

initNillion().then(() => {
  app.listen(3000, () => console.log('Server running on port 3000'));
});
```

**FastAPI Backend (Python):**

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from py_nillion_client import VmClient, SecretInteger, Permissions

app = FastAPI()
nillion_client: VmClient = None

@app.on_event("startup")
async def startup_event():
    """Initialize Nillion client on server start."""
    global nillion_client
    nillion_client = await create_nillion_client()

class StoreSecretRequest(BaseModel):
    secret_name: str
    secret_value: int
    user_id: str

@app.post("/api/store-secret")
async def store_secret(request: StoreSecretRequest):
    """API endpoint to store a secret."""
    try:
        secret = SecretInteger(request.secret_value)
        permissions = Permissions.default_for_user(request.user_id)

        store_id = await nillion_client.store_secrets(
            {request.secret_name: secret},
            permissions=permissions
        )

        return {"success": True, "store_id": store_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class ComputeRequest(BaseModel):
    program_id: str
    store_ids: list[str]

@app.post("/api/compute")
async def run_compute(request: ComputeRequest):
    """API endpoint to run computation."""
    try:
        result = await nillion_client.compute(
            program_id=request.program_id,
            store_ids=request.store_ids
        )

        return {"success": True, "result": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

### Next.js Full-Stack Application

```typescript
// app/providers.tsx
'use client';

import { NillionProvider, createClient } from '@nillion/client-react-hooks';
import { useEffect, useState } from 'react';
import type { VmClient } from '@nillion/client-vms';

export function NillionAppProvider({ children }: { children: React.ReactNode }) {
  const [client, setClient] = useState<VmClient>();

  useEffect(() => {
    const init = async () => {
      const nillionClient = await createClient({
        network: 'devnet',
        userSeed: process.env.NEXT_PUBLIC_NILLION_USER_SEED!,
        nodeSeed: process.env.NEXT_PUBLIC_NILLION_NODE_SEED!,
      });
      setClient(nillionClient);
    };
    init();
  }, []);

  if (!client) return <div>Loading Nillion...</div>;

  return <NillionProvider client={client}>{children}</NillionProvider>;
}

// app/page.tsx
'use client';

import { useNillion } from '@nillion/client-react-hooks';

export default function HomePage() {
  const { client } = useNillion();
  const [storeId, setStoreId] = useState<string>('');

  const handleStore = async () => {
    if (!client) return;

    const id = await client.storeSecrets({
      secrets: { my_value: { value: 42, type: 'SecretInteger' } },
      permissions: { retrieve: [client.userId], update: [], delete: [], compute: {} }
    });

    setStoreId(id);
  };

  return (
    <div>
      <button onClick={handleStore}>Store Secret</button>
      {storeId && <p>Stored: {storeId}</p>}
    </div>
  );
}
```

### Private AI Integration (nilAI)

```python
import asyncio
from openai import AsyncOpenAI

async def private_llm_example():
    """Use Nillion's private LLM via OpenAI-compatible API."""

    # Initialize OpenAI client pointing to Nillion nilAI
    client = AsyncOpenAI(
        api_key=os.environ["NILLION_API_KEY"],
        base_url="https://nilai-api.nillion.com/v1"  # nilAI endpoint
    )

    # Use like standard OpenAI API, but with privacy guarantees
    response = await client.chat.completions.create(
        model="gpt-4",  # Running in TEE
        messages=[
            {
                "role": "user",
                "content": "Analyze this sensitive medical data: [patient symptoms]"
            }
        ]
    )

    # Input and output never exposed outside TEE
    return response.choices[0].message.content
```

---

## 7. Testing & Development

### Local Development Setup

```bash
# Install development dependencies
pip install nada-dsl pytest

# Install Nillion devnet (local network)
pip install nillion-devnet

# Start local devnet
nillion-devnet
```

### Running Local Devnet

```bash
# Terminal 1: Start devnet
nillion-devnet

# Output:
# ℹ️ Nillion devnet running at port 37427
# ℹ️ Bootnode running at /ip4/127.0.0.1/tcp/14211
# ℹ️ Chain ID: nillion-chain-devnet-1

# Terminal 2: Run your application against devnet
export NILLION_BOOTNODE=/ip4/127.0.0.1/tcp/14211
export NILLION_CHAIN_ID=nillion-chain-devnet-1
python my_app.py
```

### Testing Nada Programs

**Unit Tests:**

```yaml
# tests/addition_test.yaml
---
program: addition
inputs:
  secrets:
    Party1:
      a: "10"
    Party2:
      b: "20"
expected_outputs:
  sum: "30"
```

```bash
# Run Nada tests
nada test addition

# Run all tests
nada test
```

**Python Integration Tests:**

```python
import pytest
import asyncio
from py_nillion_client import VmClient, SecretInteger

@pytest.fixture
async def nillion_client():
    """Fixture to create Nillion client for testing."""
    client = await create_nillion_client()
    yield client
    # Cleanup if needed

@pytest.mark.asyncio
async def test_store_and_retrieve(nillion_client):
    """Test storing and retrieving a secret."""

    # Store secret
    secret = SecretInteger(42)
    permissions = Permissions.default_for_user(nillion_client.user_id)

    store_id = await nillion_client.store_secrets(
        {"test_secret": secret},
        permissions=permissions
    )

    assert store_id is not None

    # Retrieve secret
    retrieved = await nillion_client.retrieve_secret(
        store_id=store_id,
        secret_name="test_secret"
    )

    assert retrieved == 42

@pytest.mark.asyncio
async def test_compute_program(nillion_client):
    """Test running a Nada program."""

    # Load and store program
    with open("target/my_program.nada.bin", "rb") as f:
        program_mir = f.read()

    program_id = await nillion_client.store_program(
        name="test_program",
        program_mir=program_mir
    )

    # Run computation
    result = await nillion_client.compute(
        program_id=program_id,
        runtime_secrets={
            "input_a": SecretInteger(10),
            "input_b": SecretInteger(20)
        }
    )

    assert result["sum"] == 30
```

### Debugging Techniques

**Enable Debug Logging:**

```python
import logging

# Enable Nillion client debug logs
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger("nillion")
logger.setLevel(logging.DEBUG)

# Your Nillion operations
client = await create_nillion_client()
```

**Inspect Program Bindings:**

```python
async def debug_compute(client: VmClient, program_id: str):
    """Debug compute operations with detailed logging."""

    print(f"Program ID: {program_id}")
    print(f"User ID: {client.user_id}")

    compute_bindings = {"input_a": store_id_1}
    print(f"Compute bindings: {compute_bindings}")

    try:
        result = await client.compute(
            program_id=program_id,
            compute_bindings=compute_bindings
        )
        print(f"Computation successful: {result}")
        return result
    except Exception as e:
        print(f"Computation failed: {e}")
        print(f"Error type: {type(e)}")
        raise
```

**Common Issues and Solutions:**

1. **Permission Denied**: Verify user has compute permissions for the program
2. **Secret Not Found**: Check store_id and secret_name are correct
3. **Program Not Found**: Ensure program was successfully stored
4. **Network Connection**: Verify bootnode address and network connectivity

---

## 8. Deployment & Production

### Production Deployment Checklist

- [ ] Use secure key generation (not hardcoded seeds)
- [ ] Store keys in secure vault (AWS Secrets Manager, HashiCorp Vault)
- [ ] Configure multiple bootnodes for redundancy
- [ ] Set up nilPay subscription for mainnet access
- [ ] Implement proper error handling and retries
- [ ] Add monitoring and alerting
- [ ] Test with testnet before mainnet
- [ ] Review and audit all Nada programs
- [ ] Implement rate limiting for API endpoints
- [ ] Set up proper CORS and authentication

### Secure Key Generation

```python
import os
from py_nillion_client import UserKey, NodeKey

# Generate secure random keys (production)
def generate_secure_keys():
    """Generate cryptographically secure keys."""

    # Generate from secure random bytes
    user_seed = os.urandom(32).hex()
    node_seed = os.urandom(32).hex()

    user_key = UserKey.from_seed(user_seed)
    node_key = NodeKey.from_seed(node_seed)

    # Store seeds in secure vault, not in code!
    # e.g., AWS Secrets Manager, environment variables, etc.

    return user_key, node_key
```

### Environment-Specific Configuration

```python
import os
from dataclasses import dataclass

@dataclass
class NillionConfig:
    network: str
    chain_id: str
    bootnodes: list[str]
    user_seed: str
    node_seed: str

def get_config(env: str = "production") -> NillionConfig:
    """Get environment-specific Nillion configuration."""

    configs = {
        "development": NillionConfig(
            network="devnet",
            chain_id="nillion-chain-devnet-1",
            bootnodes=["/ip4/127.0.0.1/tcp/14211"],
            user_seed=os.environ["NILLION_DEV_USER_SEED"],
            node_seed=os.environ["NILLION_DEV_NODE_SEED"],
        ),
        "testnet": NillionConfig(
            network="testnet",
            chain_id="nillion-chain-testnet-1",
            bootnodes=[
                "/dns/node-1.testnet.nillion.com/tcp/14211",
                "/dns/node-2.testnet.nillion.com/tcp/14211",
                "/dns/node-3.testnet.nillion.com/tcp/14211",
            ],
            user_seed=os.environ["NILLION_TESTNET_USER_SEED"],
            node_seed=os.environ["NILLION_TESTNET_NODE_SEED"],
        ),
        "production": NillionConfig(
            network="mainnet",
            chain_id="nillion-chain-mainnet-1",
            bootnodes=[
                "/dns/node-1.mainnet.nillion.com/tcp/14211",
                "/dns/node-2.mainnet.nillion.com/tcp/14211",
                "/dns/node-3.mainnet.nillion.com/tcp/14211",
            ],
            user_seed=os.environ["NILLION_MAINNET_USER_SEED"],
            node_seed=os.environ["NILLION_MAINNET_NODE_SEED"],
        )
    }

    return configs[env]
```

### Error Handling and Retries

```python
import asyncio
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=4, max=10)
)
async def resilient_store_secrets(
    client: VmClient,
    secrets: dict,
    permissions: Permissions
):
    """Store secrets with automatic retry on failure."""
    try:
        store_id = await client.store_secrets(secrets, permissions)
        return store_id
    except Exception as e:
        print(f"Store attempt failed: {e}")
        raise  # Will trigger retry

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=4, max=10)
)
async def resilient_compute(
    client: VmClient,
    program_id: str,
    **kwargs
):
    """Run computation with automatic retry on failure."""
    try:
        result = await client.compute(program_id=program_id, **kwargs)
        return result
    except Exception as e:
        print(f"Compute attempt failed: {e}")
        raise
```

### Monitoring and Observability

```python
import time
from dataclasses import dataclass
from typing import Optional

@dataclass
class OperationMetrics:
    operation: str
    duration_ms: float
    success: bool
    error: Optional[str] = None

class NillionMonitor:
    """Monitor Nillion operations and collect metrics."""

    def __init__(self):
        self.metrics: list[OperationMetrics] = []

    async def monitored_operation(self, operation_name: str, coro):
        """Wrap Nillion operations with monitoring."""
        start_time = time.time()

        try:
            result = await coro
            duration = (time.time() - start_time) * 1000

            self.metrics.append(OperationMetrics(
                operation=operation_name,
                duration_ms=duration,
                success=True
            ))

            print(f"✓ {operation_name} completed in {duration:.2f}ms")
            return result

        except Exception as e:
            duration = (time.time() - start_time) * 1000

            self.metrics.append(OperationMetrics(
                operation=operation_name,
                duration_ms=duration,
                success=False,
                error=str(e)
            ))

            print(f"✗ {operation_name} failed after {duration:.2f}ms: {e}")
            raise

    def get_stats(self):
        """Get operation statistics."""
        total = len(self.metrics)
        successful = sum(1 for m in self.metrics if m.success)
        avg_duration = sum(m.duration_ms for m in self.metrics) / total if total > 0 else 0

        return {
            "total_operations": total,
            "successful": successful,
            "failed": total - successful,
            "success_rate": successful / total if total > 0 else 0,
            "avg_duration_ms": avg_duration
        }

# Usage
monitor = NillionMonitor()

store_id = await monitor.monitored_operation(
    "store_secrets",
    client.store_secrets(secrets, permissions)
)

result = await monitor.monitored_operation(
    "compute",
    client.compute(program_id=program_id, store_ids=[store_id])
)

print(monitor.get_stats())
```

### Performance Optimization

**1. Batch Operations:**

```python
async def batch_store_secrets(
    client: VmClient,
    secret_batches: list[dict]
):
    """Store multiple secrets in parallel."""

    tasks = [
        client.store_secrets(secrets, permissions)
        for secrets, permissions in secret_batches
    ]

    # Execute in parallel
    store_ids = await asyncio.gather(*tasks)
    return store_ids
```

**2. Connection Pooling:**

```python
class NillionClientPool:
    """Maintain a pool of Nillion clients for high throughput."""

    def __init__(self, pool_size: int = 5):
        self.pool_size = pool_size
        self.clients: list[VmClient] = []
        self.current_idx = 0

    async def initialize(self, config: NillionConfig):
        """Initialize the client pool."""
        for _ in range(self.pool_size):
            client = await create_nillion_client_with_config(config)
            self.clients.append(client)

    def get_client(self) -> VmClient:
        """Get next client from pool (round-robin)."""
        client = self.clients[self.current_idx]
        self.current_idx = (self.current_idx + 1) % self.pool_size
        return client
```

**3. Caching Program IDs:**

```python
from functools import lru_cache

class ProgramManager:
    """Manage and cache Nada program IDs."""

    def __init__(self, client: VmClient):
        self.client = client
        self._program_cache = {}

    async def get_program_id(self, program_name: str) -> str:
        """Get program ID, using cache if available."""

        if program_name in self._program_cache:
            return self._program_cache[program_name]

        # Load and store program
        with open(f"target/{program_name}.nada.bin", "rb") as f:
            program_mir = f.read()

        program_id = await self.client.store_program(
            name=program_name,
            program_mir=program_mir
        )

        self._program_cache[program_name] = program_id
        return program_id
```

### nilPay Subscription Setup

```typescript
// For production mainnet access, subscribe to Nillion services
import { NilPayClient } from '@nillion/nilpay-sdk';

async function setupProduction() {
  const nilpay = new NilPayClient({
    apiKey: process.env.NILLION_API_KEY
  });

  // Subscribe to Private Storage
  const storageSubscription = await nilpay.subscribe({
    service: 'nilDB',
    plan: 'professional', // or 'enterprise'
    billingCycle: 'monthly'
  });

  console.log('Subscription ID:', storageSubscription.id);

  // Use subscription in your client
  const client = await createClient({
    network: 'mainnet',
    subscriptionId: storageSubscription.id,
    // ... other config
  });
}
```

---

## Best Practices

### Security

1. **Never expose user/node seeds** in client-side code or version control
2. **Use environment variables** or secure vaults for all credentials
3. **Implement least-privilege permissions** - only grant what's necessary
4. **Audit Nada programs** thoroughly before production deployment
5. **Validate all inputs** before storing or computing
6. **Use HTTPS/TLS** for all network communication
7. **Implement rate limiting** to prevent abuse

### Performance

1. **Reuse client instances** - don't create new clients for each operation
2. **Batch operations** when possible to reduce network overhead
3. **Cache program IDs** instead of re-uploading programs
4. **Use appropriate data types** - SecretBlob for large data, SecretInteger for numbers
5. **Configure multiple bootnodes** for redundancy and load balancing
6. **Monitor operation latencies** and set appropriate timeouts

### Development Workflow

1. **Start with devnet** for local development and testing
2. **Write comprehensive tests** for all Nada programs
3. **Use testnet** for integration testing before mainnet
4. **Version your Nada programs** and track deployments
5. **Document permission models** for your application
6. **Implement proper error handling** at all levels
7. **Use TypeScript** for better type safety in JS/TS projects

### Nada Programming

1. **Keep programs simple** - complex logic increases gas costs and execution time
2. **Minimize secret operations** - public operations are cheaper
3. **Test with various input sizes** to understand performance characteristics
4. **Document party roles clearly** in multi-party programs
5. **Use meaningful variable names** for inputs and outputs
6. **Validate computation results** when possible
7. **Consider privacy leakage** from output values

---

## Common Use Cases

### 1. Private Healthcare Data

```python
async def healthcare_storage_example(client: VmClient):
    """Store patient records with privacy guarantees."""

    # Store patient data as blob
    with open("patient_record.json", "rb") as f:
        patient_data = f.read()

    patient_blob = SecretBlob(patient_data)

    # Only patient and authorized doctors can access
    permissions = Permissions.default_for_user(patient_id)
    permissions.add_retrieve_permissions([doctor_id])
    permissions.add_compute_permissions({
        "diagnostic_program": [ai_service_id]
    })

    store_id = await client.store_secrets(
        {"patient_record": patient_blob},
        permissions=permissions
    )

    return store_id
```

### 2. Confidential Financial Analysis

```python
# Nada program for private financial analysis
from nada_dsl import *

def nada_main():
    bank = Party(name="Bank")
    analyst = Party(name="Analyst")

    # Sensitive financial data
    revenue = SecretInteger(Input(name="revenue", party=bank))
    expenses = SecretInteger(Input(name="expenses", party=bank))

    # Compute profit without revealing individual values
    profit = revenue - expenses
    profit_margin = (profit * 100) / revenue

    # Only return aggregated metric
    return [Output(profit_margin, "profit_margin", analyst)]
```

### 3. Private AI Model Serving

```python
async def private_ml_inference(prompt: str):
    """Run AI inference with privacy guarantees."""

    # Use Nillion's private LLM via OpenAI-compatible API
    client = AsyncOpenAI(
        api_key=os.environ["NILLION_API_KEY"],
        base_url="https://nilai-api.nillion.com/v1"
    )

    response = await client.chat.completions.create(
        model="gpt-4",
        messages=[{"role": "user", "content": prompt}]
    )

    # Both input and output remain private in TEE
    return response.choices[0].message.content
```

### 4. Secure Multi-Party Voting

```python
# Nada program for private voting
from nada_dsl import *
import nada_numpy as na

def nada_main():
    # Multiple voters
    num_voters = 10
    parties = na.parties(num_voters)

    # Each voter submits encrypted vote (0 or 1)
    votes = [
        SecretInteger(Input(name=f"vote_{i}", party=parties[i]))
        for i in range(num_voters)
    ]

    # Count total votes without revealing individual choices
    total = sum(votes)

    # Public party receives the count
    public_party = Party(name="PublicResults")
    return [Output(total, "total_votes", public_party)]
```

---

## Troubleshooting

### Connection Issues

**Problem**: Cannot connect to Nillion network

**Solutions**:
- Verify bootnode address is correct for your network
- Check firewall/network settings allow connections
- Try alternative bootnodes
- Ensure chain ID matches network

```python
# Test connection
try:
    client = await create_nillion_client()
    print(f"Connected! User ID: {client.user_id}")
except Exception as e:
    print(f"Connection failed: {e}")
```

### Permission Errors

**Problem**: "Permission denied" when retrieving or computing

**Solutions**:
- Verify user ID has required permissions
- Check permission type (retrieve/update/delete/compute)
- For compute: ensure program ID is in compute permissions
- Confirm you're using the correct user credentials

```python
# Debug permissions
try:
    secret = await client.retrieve_secret(store_id, "my_secret")
except PermissionError:
    print(f"User {client.user_id} lacks retrieve permission for {store_id}")
```

### Nada Compilation Errors

**Problem**: Nada program won't compile

**Solutions**:
- Check syntax matches Nada DSL specification
- Verify all imports are correct
- Ensure party names are unique
- Validate input/output names are strings
- Check data types match operations

```bash
# Get detailed compilation errors
nada build --verbose
```

### Compute Failures

**Problem**: Computation fails or returns unexpected results

**Solutions**:
- Test Nada program locally first: `nada test program_name`
- Verify secret bindings match program inputs
- Check secret data types match program expectations
- Ensure all required secrets are provided
- Review program logic for edge cases

---

## Resources

### Official Documentation
- **Main Docs**: https://docs.nillion.com
- **LLM Context File**: https://docs.nillion.com/llm.txt
- **Nillion Website**: https://nillion.com

### GitHub Repositories
- **Python Examples**: https://github.com/NillionNetwork/python-examples
- **Python Starter**: https://github.com/NillionNetwork/nillion-python-starter
- **Create Nillion App**: https://github.com/NillionNetwork/create-nillion-app

### Developer Tools
- **NIL Faucet**: Get testnet tokens
- **Network Status**: https://status.nillion.com
- **Collection Explorer**: Schema creation for nilDB
- **nilCC Workload Manager**: Deploy confidential containers

### Community
- **Discord**: Join Nillion developer community
- **GitHub Discussions**: Ask questions and share projects
- **Documentation Issues**: Report documentation bugs

### Getting Help
- **AI-Assisted Development**: Point AI tools to https://docs.nillion.com/llm.txt
- **Specify Your Platform**: Mention Node.js, Next.js, React, or Python for targeted help
- **Include Error Messages**: Provide complete error output when asking for help
- **Share Minimal Examples**: Create minimal reproducible examples for debugging

---

## Version Information

This skill is based on:
- **Nillion SDK**: v0.6.0+ (2024)
- **Python Client**: py-nillion-client
- **TypeScript Client**: @nillion/client-vms, @nillion/client-react-hooks
- **Nada DSL**: Latest version with Nada Numpy support
- **Networks**: Devnet, Testnet, Mainnet

**Note**: Nillion is rapidly evolving. Always check the [official documentation](https://docs.nillion.com) for the latest APIs and features.

---

## Quick Reference

### Common Commands

```bash
# Nada development
nada init my-project          # Create new Nada project
nada build                    # Compile all programs
nada test program_name        # Test a program
nada generate-test program   # Generate test template

# Python environment
python3 -m venv .venv        # Create virtual environment
source .venv/bin/activate    # Activate (Unix)
pip install py-nillion-client  # Install client

# Local devnet
nillion-devnet               # Start local network
```

### Key Python Functions

```python
# Client creation
client = await VmClient.create(userkey, nodekey, bootnodes, chain_id)

# Storage operations
store_id = await client.store_secrets(secrets, permissions)
secret = await client.retrieve_secret(store_id, secret_name)
await client.update_secrets(store_id, secrets)
await client.delete_secrets(store_id)

# Compute operations
program_id = await client.store_program(name, program_mir)
result = await client.compute(program_id, compute_bindings, store_ids)

# Permissions
permissions = Permissions.default_for_user(user_id)
permissions.add_retrieve_permissions([user_id])
permissions.add_compute_permissions({program_id: [user_id]})
```

### Key TypeScript Functions

```typescript
// Client creation
const client = await createClient({ network: 'devnet' });

// React hooks
const { client } = useNillion();
const { storeSecrets } = useStoreSecrets();
const { compute } = useCompute();

// Operations
const storeId = await client.storeSecrets({ secrets, permissions });
const secret = await client.retrieveSecret({ storeId, secretName });
const result = await client.compute({ programId, storeIds });
```

---

**Ready to build privacy-preserving applications with Nillion!** Start with the Quick Start section and explore the examples throughout this skill.
