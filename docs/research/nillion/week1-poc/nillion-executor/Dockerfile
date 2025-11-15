# Nillion nilCC Executor - Payment-Gated AI Service
# This container runs in a TEE (AMD SEV-SNP or NVIDIA Confidential Compute)

FROM python:3.11-slim

WORKDIR /app

# Install dependencies
RUN pip install --no-cache-dir \
    web3==6.11.0 \
    fastapi==0.104.1 \
    uvicorn==0.24.0 \
    pydantic==2.5.0 \
    httpx==0.25.0 \
    python-dotenv==1.0.0

# Copy application code
COPY executor.py /app/
COPY ethereum_client.py /app/
COPY config.py /app/

# Expose API port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import httpx; httpx.get('http://localhost:8000/health')"

# Run the executor service
CMD ["uvicorn", "executor:app", "--host", "0.0.0.0", "--port", "8000"]
