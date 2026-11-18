# syntax=docker/dockerfile:1

# --- Build: compile the Vite app ---------------------------------------------
FROM node:24-alpine AS build
WORKDIR /app
RUN corepack enable

# Install dependencies first to benefit from layer caching.
COPY inkline-town/package.json inkline-town/pnpm-lock.yaml ./
RUN --mount=type=cache,id=pnpm,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile

COPY inkline-town/ ./
RUN pnpm build

# Precompress assets so the server sends them without compressing at runtime.
RUN apk add --no-cache brotli \
 && find dist -type f -regex '.*\.\(html\|js\|mjs\|css\|svg\|json\|txt\|xml\|wasm\|glb\|gltf\|obj\)$' \
      -exec gzip -9 -k {} \; -exec brotli -q 11 -k {} \;

# --- Runtime: tiny static server (scratch based, ~5 MB) ----------------------
FROM joseluisq/static-web-server:2 AS runtime
COPY --from=build /app/dist /public

ENV SERVER_PORT=80 \
    SERVER_ROOT=/public \
    SERVER_COMPRESSION=false \
    SERVER_COMPRESSION_STATIC=true \
    SERVER_CACHE_CONTROL_HEADERS=true \
    SERVER_SECURITY_HEADERS=false \
    SERVER_DIRECTORY_LISTING=false \
    SERVER_THREADS_MULTIPLIER=1 \
    SERVER_LOG_LEVEL=warn

EXPOSE 80
