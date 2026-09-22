# syntax=docker/dockerfile:1

# ==========================================
# DEPENDENCIES
# ==========================================
FROM node:22-alpine AS deps

RUN apk add --no-cache libc6-compat python3 make g++

WORKDIR /app

RUN corepack enable && corepack prepare pnpm@11.8.0 --activate

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

RUN pnpm install --frozen-lockfile

RUN pnpm store prune


# ==========================================
# BUILDER
# ==========================================
FROM node:22-alpine AS builder

WORKDIR /app

RUN corepack enable && corepack prepare pnpm@11.8.0 --activate

COPY --from=deps /app/node_modules ./node_modules

COPY . .

ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

# ------------------------------------------
# Build-time environment variables
# ------------------------------------------

ARG DATABASE_URL
ARG LINKEDIN_CLIENT_ID
ARG LINKEDIN_CLIENT_SECRET
ARG RECEIVER_EMAIL
ARG CAREERS_EMAIL
ARG BASE_URL
ARG PAYLOAD_SECRET
ARG SMTP_HOST
ARG SMTP_PORT
ARG SMTP_USER
ARG SMTP_PASS
ARG BETTER_AUTH_SECRET
ARG BETTER_AUTH_URL
ARG NEXT_PUBLIC_BASE_URL

ENV DATABASE_URL=$DATABASE_URL
ENV LINKEDIN_CLIENT_ID=$LINKEDIN_CLIENT_ID
ENV LINKEDIN_CLIENT_SECRET=$LINKEDIN_CLIENT_SECRET
ENV RECEIVER_EMAIL=$RECEIVER_EMAIL
ENV CAREERS_EMAIL=$CAREERS_EMAIL
ENV BASE_URL=$BASE_URL
ENV PAYLOAD_SECRET=$PAYLOAD_SECRET
ENV SMTP_HOST=$SMTP_HOST
ENV SMTP_PORT=$SMTP_PORT
ENV SMTP_USER=$SMTP_USER
ENV SMTP_PASS=$SMTP_PASS
ENV BETTER_AUTH_SECRET=$BETTER_AUTH_SECRET
ENV BETTER_AUTH_URL=$BETTER_AUTH_URL
ENV NEXT_PUBLIC_BASE_URL=$NEXT_PUBLIC_BASE_URL

# ------------------------------------------
# Verify variables without exposing values
# ------------------------------------------

RUN echo "========================================" && \
    echo "Checking build environment..." && \
    if [ -n "$DATABASE_URL" ]; then \
      echo "DATABASE_URL: SET"; \
    else \
      echo "DATABASE_URL: MISSING"; \
    fi && \
    if [ -n "$LINKEDIN_CLIENT_ID" ]; then \
      echo "LINKEDIN_CLIENT_ID: SET"; \
    else \
      echo "LINKEDIN_CLIENT_ID: MISSING"; \
    fi && \
    if [ -n "$LINKEDIN_CLIENT_SECRET" ]; then \
      echo "LINKEDIN_CLIENT_SECRET: SET"; \
    else \
      echo "LINKEDIN_CLIENT_SECRET: MISSING"; \
    fi && \
    if [ -n "$RECEIVER_EMAIL" ]; then \
      echo "RECEIVER_EMAIL: SET"; \
    else \
      echo "RECEIVER_EMAIL: MISSING"; \
    fi && \
    if [ -n "$CAREERS_EMAIL" ]; then \
      echo "CAREERS_EMAIL: SET"; \
    else \
      echo "CAREERS_EMAIL: MISSING"; \
    fi && \
    echo "========================================"

# ------------------------------------------
# Build Next.js
# ------------------------------------------

RUN pnpm build


# ==========================================
# PRODUCTION RUNNER
# ==========================================
FROM node:22-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN corepack enable && corepack prepare pnpm@11.8.0 --activate

RUN addgroup --system --gid 1001 nodejs

RUN adduser --system --uid 1001 nextjs

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

RUN pnpm install --prod --frozen-lockfile

RUN pnpm store prune

COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next

COPY --from=builder --chown=nextjs:nodejs /app/public ./public

COPY --from=builder --chown=nextjs:nodejs /app/next.config.ts ./next.config.ts

COPY --from=builder --chown=nextjs:nodejs /app/tsconfig.json ./tsconfig.json

COPY --from=builder --chown=nextjs:nodejs /app/src ./src

RUN mkdir -p /app/public/uploads && \
    chown -R nextjs:nodejs /app/public/uploads

RUN chown -R nextjs:nodejs /app

USER nextjs

EXPOSE 3000

ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["pnpm", "start"]
