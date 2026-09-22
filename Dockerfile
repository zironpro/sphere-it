# syntax=docker/dockerfile:1

# =========================
# Dependencies
# =========================
FROM node:22-alpine AS deps

RUN apk add --no-cache libc6-compat python3 make g++

WORKDIR /app

RUN corepack enable && corepack prepare pnpm@11.8.0 --activate

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

RUN pnpm install --frozen-lockfile

RUN pnpm store prune


# =========================
# Builder
# =========================
FROM node:22-alpine AS builder

WORKDIR /app

RUN corepack enable && corepack prepare pnpm@11.8.0 --activate

COPY --from=deps /app/node_modules ./node_modules

COPY . .

ENV NEXT_TELEMETRY_DISABLED=1 \
    NODE_ENV=production

# Load the BuildKit secret into the environment.
# Only variable presence is printed — never the actual values.
RUN --mount=type=secret,id=env_file,target=/app/.env \
    set -a && \
    . /app/.env && \
    set +a && \
    echo "===== Build Environment Check =====" && \
    if [ -n "${DATABASE_URL:-}" ]; then echo "DATABASE_URL: SET"; else echo "DATABASE_URL: MISSING"; fi && \
    if [ -n "${LINKEDIN_CLIENT_ID:-}" ]; then echo "LINKEDIN_CLIENT_ID: SET"; else echo "LINKEDIN_CLIENT_ID: MISSING"; fi && \
    if [ -n "${LINKEDIN_CLIENT_SECRET:-}" ]; then echo "LINKEDIN_CLIENT_SECRET: SET"; else echo "LINKEDIN_CLIENT_SECRET: MISSING"; fi && \
    if [ -n "${RECEIVER_EMAIL:-}" ]; then echo "RECEIVER_EMAIL: SET"; else echo "RECEIVER_EMAIL: MISSING"; fi && \
    if [ -n "${CAREERS_EMAIL:-}" ]; then echo "CAREERS_EMAIL: SET"; else echo "CAREERS_EMAIL: MISSING"; fi && \
    echo "===================================" && \
    pnpm build


# =========================
# Production Runner
# =========================
FROM node:22-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN corepack enable && corepack prepare pnpm@11.8.0 --activate

RUN addgroup --system --gid 1001 nodejs

RUN adduser --system --uid 1001 nextjs

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

RUN pnpm install --prod --frozen-lockfile && pnpm store prune

COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next

COPY --from=builder --chown=nextjs:nodejs /app/public ./public

COPY --from=builder --chown=nextjs:nodejs /app/next.config.ts ./next.config.ts

COPY --from=builder --chown=nextjs:nodejs /app/tsconfig.json ./tsconfig.json

COPY --from=builder --chown=nextjs:nodejs /app/src ./src

RUN mkdir -p /app/public/uploads \
    && chown -R nextjs:nodejs /app/public/uploads

RUN chown -R nextjs:nodejs /app

USER nextjs

EXPOSE 3000

ENV PORT=3000

ENV HOSTNAME="0.0.0.0"

CMD ["pnpm", "start"]
