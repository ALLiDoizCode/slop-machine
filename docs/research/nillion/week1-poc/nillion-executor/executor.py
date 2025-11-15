"""
Nillion Payment-Gated AI Executor
==================================

This service runs inside a Nillion nilCC TEE and provides payment-gated
AI service execution with atomic payment verification via Ethereum smart contract.

ARCHITECTURE:
1. Receive execution request with user signature
2. Verify payment credits via Ethereum contract call
3. Consume credits atomically BEFORE execution
4. Execute AI service (in private TEE environment)
5. Return results or refund on failure

SECURITY MODEL:
- Runs in AMD SEV-SNP or NVIDIA Confidential Compute TEE
- Private key for Ethereum signing stored in TEE-encrypted memory
- Attestation proves code integrity to smart contract
- No external visibility into execution data
"""

import os
import time
import hashlib
import json
from typing import Optional, Dict, Any
from datetime import datetime

from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel, Field
import httpx

from ethereum_client import EthereumClient
from config import Config

# Initialize FastAPI app
app = FastAPI(
    title="Nillion Payment-Gated AI Executor",
    description="TEE-based executor for Permamind M2M marketplace",
    version="1.0.0"
)

# Global state
eth_client: Optional[EthereumClient] = None
config: Config


# ============ Request/Response Models ============

class ExecutionRequest(BaseModel):
    """Request to execute a payment-gated AI service"""
    user_address: str = Field(..., description="Ethereum address of user")
    service_id: str = Field(..., description="Service ID (bytes32 hex)")
    credits_to_consume: int = Field(..., gt=0, description="Credits to consume")
    input_data: Dict[str, Any] = Field(..., description="Input data for AI service")
    user_signature: str = Field(..., description="User signature proving authorization")

class ExecutionResponse(BaseModel):
    """Response from AI service execution"""
    success: bool
    receipt_id: Optional[str] = None
    nillion_tx_id: str
    output_data: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
    execution_time_ms: int
    credits_consumed: int
    refunded: bool = False

class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    tee_attestation_valid: bool
    ethereum_connected: bool
    executor_authorized: bool
    timestamp: str


# ============ Startup/Shutdown ============

@app.on_event("startup")
async def startup_event():
    """Initialize Ethereum client and verify TEE attestation"""
    global eth_client, config

    config = Config()
    eth_client = EthereumClient(
        rpc_url=config.ETHEREUM_RPC_URL,
        contract_address=config.PAYMENT_CONTRACT_ADDRESS,
        executor_private_key=config.EXECUTOR_PRIVATE_KEY
    )

    # Verify executor is authorized in smart contract
    is_authorized = await eth_client.is_executor_authorized()
    if not is_authorized:
        raise RuntimeError("Executor not authorized in payment contract")

    print(f"✅ Nillion Executor started")
    print(f"✅ TEE Environment: {config.TEE_TYPE}")
    print(f"✅ Executor Address: {eth_client.executor_address}")
    print(f"✅ Contract: {config.PAYMENT_CONTRACT_ADDRESS}")


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    print("🛑 Nillion Executor shutting down")


# ============ API Endpoints ============

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    is_authorized = await eth_client.is_executor_authorized()

    return HealthResponse(
        status="healthy",
        tee_attestation_valid=True,  # In production: verify actual TEE attestation
        ethereum_connected=eth_client.is_connected(),
        executor_authorized=is_authorized,
        timestamp=datetime.utcnow().isoformat()
    )


@app.get("/attestation")
async def get_attestation():
    """
    Get TEE attestation proof

    In production, this would return:
    - AMD SEV-SNP attestation report
    - NVIDIA GPU attestation
    - Code measurement hash
    - Public key for verification
    """
    # Placeholder - real implementation would call TEE SDK
    return {
        "tee_type": config.TEE_TYPE,
        "attestation_hash": eth_client.get_attestation_hash(),
        "executor_address": eth_client.executor_address,
        "code_hash": get_code_hash(),
        "timestamp": datetime.utcnow().isoformat()
    }


@app.post("/execute", response_model=ExecutionResponse)
async def execute_service(
    request: ExecutionRequest,
    background_tasks: BackgroundTasks
):
    """
    Execute payment-gated AI service

    FLOW:
    1. Verify user signature
    2. Check and consume credits via Ethereum contract
    3. Execute AI service in TEE
    4. Return results or refund on failure
    """
    start_time = time.time()
    nillion_tx_id = generate_nillion_tx_id(request)

    try:
        # Step 1: Verify user signature
        if not verify_user_signature(request):
            raise HTTPException(status_code=401, detail="Invalid user signature")

        # Step 2: Verify and consume credits ATOMICALLY
        print(f"🔒 Consuming {request.credits_to_consume} credits for user {request.user_address}")

        receipt_id = await eth_client.verify_and_consume_credits(
            user_address=request.user_address,
            service_id=request.service_id,
            credits=request.credits_to_consume,
            nillion_tx_id=nillion_tx_id
        )

        print(f"✅ Credits consumed, receipt: {receipt_id}")

        # Step 3: Execute AI service in TEE
        try:
            output_data = await execute_ai_service(request.input_data)

            execution_time = int((time.time() - start_time) * 1000)

            return ExecutionResponse(
                success=True,
                receipt_id=receipt_id,
                nillion_tx_id=nillion_tx_id,
                output_data=output_data,
                execution_time_ms=execution_time,
                credits_consumed=request.credits_to_consume,
                refunded=False
            )

        except Exception as execution_error:
            # Step 4: Refund on execution failure
            print(f"❌ Execution failed: {execution_error}")

            await eth_client.refund_execution(
                receipt_id=receipt_id,
                reason=f"Execution failed: {str(execution_error)}"
            )

            execution_time = int((time.time() - start_time) * 1000)

            return ExecutionResponse(
                success=False,
                receipt_id=receipt_id,
                nillion_tx_id=nillion_tx_id,
                error=str(execution_error),
                execution_time_ms=execution_time,
                credits_consumed=0,
                refunded=True
            )

    except Exception as e:
        execution_time = int((time.time() - start_time) * 1000)

        return ExecutionResponse(
            success=False,
            nillion_tx_id=nillion_tx_id,
            error=str(e),
            execution_time_ms=execution_time,
            credits_consumed=0,
            refunded=False
        )


# ============ Service Execution Functions ============

async def execute_ai_service(input_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute AI service in TEE

    This is a placeholder - in production this would:
    1. Load AI model (stored in nilDB or local TEE storage)
    2. Run inference on input_data
    3. Return results

    The key is that ALL execution happens in TEE:
    - Input data never leaves encrypted environment
    - Model weights remain private
    - Computation is verifiable via attestation
    """
    # Simulate AI service execution
    await simulate_ai_inference(input_data)

    # Return placeholder results
    return {
        "result": "AI service executed successfully",
        "model": "example-llm-v1",
        "tee_verified": True,
        "execution_node": os.getenv("HOSTNAME", "unknown"),
        "timestamp": datetime.utcnow().isoformat()
    }


async def simulate_ai_inference(input_data: Dict[str, Any]):
    """Simulate AI inference with realistic timing"""
    # Simulate processing time (100-500ms)
    import asyncio
    import random
    await asyncio.sleep(random.uniform(0.1, 0.5))


# ============ Helper Functions ============

def verify_user_signature(request: ExecutionRequest) -> bool:
    """
    Verify user signature proves authorization

    In production, this would:
    1. Reconstruct message hash from request params
    2. Recover signer address from signature
    3. Verify signer matches user_address
    """
    # Placeholder - real implementation would use web3.eth.account.recover_message
    return True


def generate_nillion_tx_id(request: ExecutionRequest) -> str:
    """Generate unique Nillion transaction ID"""
    data = f"{request.user_address}:{request.service_id}:{time.time()}:{os.urandom(16).hex()}"
    return f"nillion_{hashlib.sha256(data.encode()).hexdigest()[:32]}"


def get_code_hash() -> str:
    """
    Get hash of executor code for attestation

    In production TEE:
    - AMD SEV-SNP provides code measurement
    - NVIDIA provides container hash
    - This hash is included in attestation report
    """
    # Placeholder - real implementation would get actual TEE measurement
    code = open(__file__, 'rb').read()
    return hashlib.sha256(code).hexdigest()


# ============ Development/Testing Endpoints ============

@app.get("/debug/config")
async def debug_config():
    """Debug endpoint - shows configuration (REMOVE IN PRODUCTION)"""
    return {
        "ethereum_rpc": config.ETHEREUM_RPC_URL,
        "contract_address": config.PAYMENT_CONTRACT_ADDRESS,
        "executor_address": eth_client.executor_address,
        "tee_type": config.TEE_TYPE
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
