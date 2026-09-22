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

ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

RUN --mount=type=secret,id=env_file,target=/tmp/build.env \
    echo "===== Checking Build Environment =====" && \
    if grep -q '^DATABASE_URL=' /tmp/build.env; then echo "DATABASE_URL: PRESENT"; else echo "DATABASE_URL: MISSING"; fi && \
    if grep -q '^LINKEDIN_CLIENT_ID=' /tmp/build.env; then echo "LINKEDIN_CLIENT_ID: PRESENT"; else echo "LINKEDIN_CLIENT_ID: MISSING"; fi && \
    if grep -q '^LINKEDIN_CLIENT_SECRET=' /tmp/build.env; then echo "LINKEDIN_CLIENT_SECRET: PRESENT"; else echo "LINKEDIN_CLIENT_SECRET: MISSING"; fi && \
    if grep -q '^RECEIVER_EMAIL=' /tmp/build.env; then echo "RECEIVER_EMAIL: PRESENT"; else echo "RECEIVER_EMAIL: MISSING"; fi && \
    if grep -q '^CAREERS_EMAIL=' /tmp/build.env; then echo "CAREERS_EMAIL: PRESENT"; else echo "CAREERS_EMAIL: MISSING"; fi && \
    echo "=====================================" && \
    cp /tmp/build.env /app/.env && \
    set -a && \
    . /app/.env && \
    set +a && \
    export DATABASE_URL LINKEDIN_CLIENT_ID LINKEDIN_CLIENT_SECRET RECEIVER_EMAIL CAREERS_EMAIL && \
    pnpm build && \
    rm -f /app/.env


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
