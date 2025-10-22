# syntax=docker/dockerfile:1

FROM node:20-slim AS base

WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1

RUN corepack enable && corepack prepare pnpm@10.5.1 --activate

FROM base AS deps

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

FROM base AS builder

COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN pnpm run build

FROM base AS runner

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --prod=false

LABEL org.opencontainers.image.source="https://github.com/104corp/agent-chat-ui"

COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/next.config.mjs ./next.config.mjs

ENV NODE_ENV=production
ENV PORT=80

USER node

EXPOSE 80

CMD ["pnpm", "start"]
