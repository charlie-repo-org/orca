#!/usr/bin/env bash
set -e

echo "[orca-docker] Starting Orca Web Runtime..."
echo "[orca-docker] Binding Port: ${ORCA_SERVE_PORT:-6768}"
echo "[orca-docker] Binding Address: ${ORCA_PAIRING_ADDRESS:-0.0.0.0}"

mkdir -p /root/.config/orca /workspace

export HOME=/root
export ELECTRON_DISABLE_SANDBOX=1
export ORCA_BACKGROUND_LAUNCH=1

exec dbus-run-session -- xvfb-run -a -s "-screen 0 1024x768x24" \
  /app/node_modules/.bin/electron /app \
  --no-sandbox \
  serve \
  --port "${ORCA_SERVE_PORT:-6768}" \
  --pairing-address "${ORCA_PAIRING_ADDRESS:-0.0.0.0}" \
  "$@"
