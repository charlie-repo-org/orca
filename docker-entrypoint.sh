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
