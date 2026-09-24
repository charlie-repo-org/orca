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

# Configure Git user if not already configured
if [ -n "${GIT_USER_NAME:-}" ]; then
  git config --global user.name "$GIT_USER_NAME"
elif ! git config --global user.name >/dev/null 2>&1; then
  git config --global user.name "Orca User"
fi

if [ -n "${GIT_USER_EMAIL:-}" ]; then
  git config --global user.email "$GIT_USER_EMAIL"
elif ! git config --global user.email >/dev/null 2>&1; then
  git config --global user.email "orca@localhost"
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
