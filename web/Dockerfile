# syntax=docker/dockerfile:1
FROM node:22-slim AS base
RUN apt-get update && apt-get install -y --no-install-recommends openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app

FROM base AS deps
COPY package.json package-lock.json* ./
COPY prisma ./prisma
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

FROM base AS build
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# Build-time placeholders only; real values are provided at runtime.
ENV DATABASE_URL="file:/app/data/build.db" SESSION_SECRET="build-time-placeholder-build-time-placeholder" NEXT_TELEMETRY_DISABLED=1
ARG NEXT_PUBLIC_SITE_URL
ARG NEXT_PUBLIC_PURCHASE_URL
ENV NEXT_PUBLIC_SITE_URL=$NEXT_PUBLIC_SITE_URL NEXT_PUBLIC_PURCHASE_URL=$NEXT_PUBLIC_PURCHASE_URL
RUN npm run build

FROM base AS run
ENV NODE_ENV=production NEXT_TELEMETRY_DISABLED=1 DATABASE_URL="file:/app/data/nuvio.db"
COPY --from=build /app ./
RUN mkdir -p /app/data
VOLUME ["/app/data"]
EXPOSE 3000
# Create / update the SQLite schema, then start the server.
CMD ["sh", "-c", "npx prisma db push --skip-generate && npm start"]
