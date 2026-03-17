# ─────────────────────────────────────────────────────────────
# Stage 1 — deps
#   Install ALL dependencies (including devDependencies).
#   This layer is cached as long as package*.json doesn't change.
# ─────────────────────────────────────────────────────────────
FROM node:20-alpine AS deps

WORKDIR /app

# Copy only the manifest files first to leverage layer caching
COPY package.json package-lock.json* ./

# Install all deps (dev + prod) needed for build / tests
RUN npm install

# ─────────────────────────────────────────────────────────────
# Stage 2 — builder
#   Run tests, linting, and any transpilation / asset bundling.
# ─────────────────────────────────────────────────────────────
FROM deps AS builder

# Copy source code
COPY src/ ./src/

# Run tests (fails the build if tests fail)
RUN npm test

# Optional: compile / bundle here if you use TypeScript or a bundler
# RUN npm run build

# ─────────────────────────────────────────────────────────────
# Stage 3 — production
#   Lean image: only production dependencies + compiled output.
#   No devDependencies, no test files, no build tools.
# ─────────────────────────────────────────────────────────────
FROM node:20-alpine AS production

# Set secure, non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Install only production dependencies
COPY package.json package-lock.json* ./
RUN npm install --omit=dev && npm cache clean --force

# Copy application source from builder stage (not from host)
COPY --from=builder /app/src ./src

# Drop root privileges
USER appuser

# Expose application port
EXPOSE 3000

# Healthcheck so Docker / orchestrators know when the app is ready
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/api/health || exit 1

# Start the application
CMD ["node", "src/index.js"]
