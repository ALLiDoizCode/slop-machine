#!/bin/bash

# Nillion Micropayment Protocol - Local Development Setup Script
# This script automates the initial setup for local development

set -e  # Exit on error

echo "🏗️  Nillion Micropayment Protocol - Development Setup"
echo "======================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check Node.js version
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed${NC}"
    echo "Please install Node.js 18+ from https://nodejs.org/"
    exit 1
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo -e "${RED}❌ Node.js version must be 18 or higher (found v$NODE_VERSION)${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Node.js $(node -v)"

# Check pnpm
if ! command -v pnpm &> /dev/null; then
    echo -e "${YELLOW}⚠ pnpm is not installed. Installing pnpm...${NC}"
    npm install -g pnpm
fi
echo -e "${GREEN}✓${NC} pnpm $(pnpm -v)"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    echo "Please install Docker from https://www.docker.com/get-started"
    exit 1
fi
echo -e "${GREEN}✓${NC} Docker $(docker -v | cut -d' ' -f3 | cut -d',' -f1)"

# Check Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Docker Compose installed"

echo ""
echo "📦 Installing dependencies..."
pnpm install

echo ""
echo "🔧 Setting up environment variables..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo -e "${GREEN}✓${NC} Created .env file from .env.example"
    echo -e "${YELLOW}⚠ Please edit .env and add your API keys (Infura, Alchemy, etc.)${NC}"
else
    echo -e "${YELLOW}⚠ .env file already exists, skipping${NC}"
fi

echo ""
echo "🐳 Starting Docker services (PostgreSQL + Redis)..."
docker-compose up -d postgres redis

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
    if docker-compose exec -T postgres pg_isready -U postgres &> /dev/null; then
        echo -e "${GREEN}✓${NC} PostgreSQL is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}❌ PostgreSQL failed to start${NC}"
        exit 1
    fi
    sleep 1
done

# Wait for Redis to be ready
echo "⏳ Waiting for Redis to be ready..."
for i in {1..30}; do
    if docker-compose exec -T redis redis-cli ping &> /dev/null; then
        echo -e "${GREEN}✓${NC} Redis is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}❌ Redis failed to start${NC}"
        exit 1
    fi
    sleep 1
done

echo ""
echo "🗄️  Running database migrations..."
# Note: This will be replaced with actual migration command once migrations are created
# pnpm run migrate
echo -e "${YELLOW}⚠ Database migrations not yet created. Run 'pnpm run migrate' when ready.${NC}"

echo ""
echo "🔨 Generating Protocol Buffer types..."
# Note: This will be replaced with actual protobuf generation once .proto files exist
# pnpm run proto:generate
echo -e "${YELLOW}⚠ Protocol Buffer schemas not yet created. Run 'pnpm run proto:generate' when ready.${NC}"

echo ""
echo "======================================================="
echo -e "${GREEN}✅ Development environment setup complete!${NC}"
echo ""
echo "📝 Next steps:"
echo ""
echo "1. Edit .env and add your API keys:"
echo "   - INFURA_PROJECT_ID (get free key at https://infura.io/)"
echo "   - ALCHEMY_API_KEY (get free key at https://www.alchemy.com/)"
echo ""
echo "2. Start the development servers:"
echo "   ${GREEN}pnpm run dev${NC}"
echo ""
echo "3. Access the services:"
echo "   - Dashboard: http://localhost:3000"
echo "   - API Server: http://localhost:8080"
echo "   - PostgreSQL: localhost:5432 (user: postgres, password: postgres)"
echo "   - Redis: localhost:6379"
echo ""
echo "4. Optional: Start management UIs with:"
echo "   ${GREEN}docker-compose --profile tools up -d${NC}"
echo "   - pgAdmin: http://localhost:5050 (admin@nillion.dev / admin)"
echo "   - Redis Commander: http://localhost:8081"
echo ""
echo "📚 For more information, see:"
echo "   - docs/architecture.md - Full architecture documentation"
echo "   - README.md - Project overview"
echo ""
echo "🎉 Happy coding!"
echo ""
