# Nillion Micropayment Protocol - Backend Server Dockerfile
# Multi-stage build for optimal image size

# Stage 1: Dependencies
FROM node:18-alpine AS deps
RUN apk add --no-cache libc6-compat
RUN npm install -g pnpm@8

WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/server/package.json ./apps/server/
COPY packages/*/package.json ./packages/

# Install dependencies
RUN pnpm install --frozen-lockfile --prod=false

# Stage 2: Builder
FROM node:18-alpine AS builder
RUN npm install -g pnpm@8

WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/apps ./apps
COPY --from=deps /app/packages ./packages

# Copy source code
COPY . .

# Generate Protocol Buffer types
RUN pnpm run proto:generate

# Build all packages and server
RUN pnpm run build --filter=server

# Stage 3: Runner
FROM node:18-alpine AS runner
RUN npm install -g pnpm@8

WORKDIR /app

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nillion

# Copy built artifacts
COPY --from=builder --chown=nillion:nodejs /app/apps/server/dist ./apps/server/dist
COPY --from=builder --chown=nillion:nodejs /app/apps/server/package.json ./apps/server/
COPY --from=builder --chown=nillion:nodejs /app/packages ./packages
COPY --from=builder --chown=nillion:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nillion:nodejs /app/package.json ./

# Set production environment
ENV NODE_ENV=production
ENV PORT=8080

# Switch to non-root user
USER nillion

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8080/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start server
CMD ["node", "apps/server/dist/index.js"]
