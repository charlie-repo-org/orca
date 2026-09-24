#!/usr/bin/env bash
set -e

PORT="${ORCA_SERVE_PORT:-6768}"
PAIRING_ADDRESS="${ORCA_PAIRING_ADDRESS:-0.0.0.0}"

echo "[orca-docker] Starting Orca Web Runtime..."
echo "[orca-docker] Binding Port: ${PORT}"
echo "[orca-docker] Binding Address: ${PAIRING_ADDRESS}"

mkdir -p /root/.config/orca /workspace

export HOME=/root
export ELECTRON_DISABLE_SANDBOX=1
export ORCA_BACKGROUND_LAUNCH=1

# Configure Git user identity and credentials from environment variables
GIT_NAME="${GIT_USER_NAME:-${GIT_USERNAME:-${GIT_USER:-${GITHUB_USER:-${GITHUB_USERNAME:-}}}}}"
GIT_MAIL="${GIT_USER_EMAIL:-${GIT_EMAIL:-${GITHUB_EMAIL:-}}}"
GIT_PASS="${GIT_PASSWORD:-${GIT_TOKEN:-${GITHUB_TOKEN:-${GH_TOKEN:-${GIT_PAT:-}}}}}"

if [ -n "$GIT_NAME" ]; then
  git config --global user.name "$GIT_NAME"
elif ! git config --global user.name >/dev/null 2>&1; then
  git config --global user.name "Orca User"
fi

if [ -n "$GIT_MAIL" ]; then
  git config --global user.email "$GIT_MAIL"
elif ! git config --global user.email >/dev/null 2>&1; then
  git config --global user.email "orca@localhost"
fi

# Auto-authenticate Git HTTPS operations if password / token is provided
if [ -n "$GIT_PASS" ]; then
  git config --global credential.helper store
  AUTH_USER="${GIT_NAME:-x-access-token}"
  mkdir -p /root
  touch /root/.git-credentials
  chmod 600 /root/.git-credentials
  if ! grep -q "github.com" /root/.git-credentials 2>/dev/null; then
    echo "https://${AUTH_USER}:${GIT_PASS}@github.com" >> /root/.git-credentials
  fi
  export GITHUB_TOKEN="${GITHUB_TOKEN:-$GIT_PASS}"
  export GH_TOKEN="${GH_TOKEN:-$GIT_PASS}"
fi

# Start Tailscale if configured or existing state exists
TS_KEY="${TS_AUTHKEY:-${TAILSCALE_AUTHKEY:-}}"
TS_HOST="${TS_HOSTNAME:-${TAILSCALE_HOSTNAME:-orca-server}}"
if [ -n "$TS_KEY" ] || [ -f "/var/lib/tailscale/tailscaled.state" ]; then
  echo "[orca-docker] Starting Tailscale daemon..."
  mkdir -p /var/lib/tailscale /run/tailscale
  tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock > /var/log/tailscaled.log 2>&1 &
  sleep 2
  if [ -n "$TS_KEY" ]; then
    echo "[orca-docker] Connecting Tailscale with auth key..."
    tailscale --socket=/run/tailscale/tailscaled.sock up --authkey="$TS_KEY" --hostname="$TS_HOST" --accept-routes=true || true
  fi
fi

EXTRA_ARGS=()
if [[ "${ORCA_NO_PAIRING:-0}" == "1" || "${ORCA_NO_PAIRING:-false}" == "true" ]]; then
  EXTRA_ARGS+=(--serve-no-pairing)
fi

exec dbus-run-session -- xvfb-run -a -s "-screen 0 1024x768x24" \
  /app/node_modules/.bin/electron /app \
  --no-sandbox \
  --headless \
  --serve \
  --serve-port="${PORT}" \
  --serve-pairing-address="${PAIRING_ADDRESS}" \
  "${EXTRA_ARGS[@]}" \
  "$@"
