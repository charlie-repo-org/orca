# Stage 1: Build Web & Desktop Bundles
FROM node:24-bookworm AS builder

WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive \
    HUSKY=0

# Install build dependencies for native modules and Electron rebuild
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    python3 \
    git \
    libasound2 \
    libatk-bridge2.0-0 \
    libatspi2.0-0 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnss3 \
    libsecret-1-dev \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    libxss1 \
    pkg-config \
    rpm \
    && rm -rf /var/lib/apt/lists/*

# Enable pnpm
RUN corepack enable && corepack prepare pnpm@12.0.0 --activate

# Copy dependency definitions and config/patches needed by pnpm install & rebuild
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml* ./
COPY config ./config

RUN pnpm install --frozen-lockfile

# Copy remaining application source
COPY . .

# Build cli, electron bundles, and web client
RUN pnpm run build:cli
RUN pnpm run build:electron-vite
RUN pnpm run build:web-from-renderer

# Stage 2: Production Runner
FROM node:24-bookworm-slim AS runner

WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive \
    ELECTRON_ENABLE_LOGGING=1 \
    ORCA_BACKGROUND_LAUNCH=1 \
    ELECTRON_DISABLE_SANDBOX=1 \
    NODE_ENV=production

# Install runtime dependencies for Electron, Xvfb, Git, and terminal utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    xvfb \
    dbus-x11 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatspi2.0-0 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnss3 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    libxss1 \
    procps \
    util-linux \
    xauth \
    && rm -rf /var/lib/apt/lists/*

# Copy built application & dependencies from builder
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/out ./out
COPY --from=builder /app/src ./src

# Create workspace directory for projects and configuration
RUN mkdir -p /workspace /root/.config/orca

WORKDIR /app

EXPOSE 6768

# Run Orca in headless serve mode with Xvfb
CMD ["xvfb-run", "--auto-servernum", "--server-args=-screen 0 1024x768x24", "npx", "electron", ".", "--no-sandbox", "--headless", "--serve", "--serve-ws-port=6768", "--serve-pairing-address=0.0.0.0"]
