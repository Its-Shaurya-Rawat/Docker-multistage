# Multi-Stage Docker Build — Node.js + Nginx

A production-ready setup demonstrating **multi-stage Docker builds** to minimise
image size while keeping the build pipeline clean and secure.

---

## Project Structure

```
.
├── Dockerfile            # 3-stage build: deps → builder → production
├── docker-compose.yml    # Orchestrates Node.js app + Nginx reverse proxy
├── .dockerignore         # Keeps build context lean
├── package.json
├── src/
│   └── index.js          # Express API
└── nginx/
    └── default.conf      # Reverse-proxy config
```

---

## Build Stages Explained

| Stage | Base image | Purpose |
|-------|-----------|---------|
| **deps** | `node:20-alpine` | Install all dependencies (cached) |
| **builder** | `deps` | Run tests; compile/bundle if needed |
| **production** | `node:20-alpine` | Lean runtime image — prod deps only |

### Why multi-stage?

| Without multi-stage | With multi-stage |
|--------------------|-----------------|
| ~1 GB+ (full Node + devDeps) | ~150 MB (Alpine + prod deps only) |
| Build tools in final image | Only runtime artefacts shipped |
| Secret/intermediate files may leak | Each stage is isolated |

---

## Quick Start

```bash
# 1. Build & start all services
docker compose up --build

# 2. Test the API (through Nginx on port 80)
curl http://localhost/api/health
curl http://localhost/api/info

# 3. Nginx health check
curl http://localhost/nginx-health
```

---

## Build a standalone image

```bash
# Build only the production stage
docker build --target production -t my-node-app:latest .

# Inspect the final image size
docker image ls my-node-app
```

---

## Key Concepts

### Layer caching
`package.json` is copied **before** source code so that `npm ci` is only
re-run when dependencies change — not on every code edit.

### Non-root user
The production stage creates a dedicated `appuser` and switches to it before
`CMD`, following the principle of least privilege.

### Health checks
Both the Dockerfile `HEALTHCHECK` and the Compose `healthcheck` block verify
the app is ready. Nginx only starts after the app passes its health check
(`depends_on: condition: service_healthy`).

### `.dockerignore`
`node_modules`, `.git`, and other noise are excluded from the build context,
keeping image layers small and build times fast.

---

## Useful Commands

```bash
# View running containers
docker compose ps

# Stream logs
docker compose logs -f

# Stop everything
docker compose down

# Rebuild from scratch (no cache)
docker compose build --no-cache
```
