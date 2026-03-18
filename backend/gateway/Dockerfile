# ─────────────────────────────────────────
# Build stage
# Context: backend/ (workspace root)
# ─────────────────────────────────────────
FROM node:20-alpine AS builder
WORKDIR /app

# 1. Copy workspace manifests first (for layer caching of npm ci)
COPY package*.json tsconfig.base.json ./
COPY shared/package.json             ./shared/
COPY auth-service/package.json       ./auth-service/
COPY profile-service/package.json    ./profile-service/
COPY feed-service/package.json       ./feed-service/
COPY messaging-service/package.json  ./messaging-service/
COPY gateway/package.json            ./gateway/

# 2. Install all workspace dependencies (uses root package-lock.json)
RUN npm ci

# 3. Build @interaedu/shared first (gateway uses shared JWT guard)
COPY shared/ ./shared/
RUN npm run build -w @interaedu/shared

# 4. Build gateway
COPY gateway/ ./gateway/
RUN cd gateway && npx nest build

# ─────────────────────────────────────────
# Runtime stage
# ─────────────────────────────────────────
FROM node:20-alpine AS runtime
WORKDIR /app

RUN addgroup -g 1001 -S appgroup && adduser -S appuser -u 1001 -G appgroup

COPY --from=builder --chown=appuser:appgroup /app/gateway/dist ./dist
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app/shared ./shared
COPY --from=builder --chown=appuser:appgroup /app/gateway/package.json ./

USER appuser
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/api/v1/health || exit 1
CMD ["node", "dist/main.js"]
