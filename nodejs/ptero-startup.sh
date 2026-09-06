#!/usr/bin/env bash

set -u

cd /home/container
export PATH="/home/container/.local/bin:${PATH}"

# Older revisions generated this helper inside the server data volume. The
# helper now ships in the image, so remove only that obsolete generated file.
rm -f /home/container/.ptero/startup.sh
rmdir /home/container/.ptero 2>/dev/null || true

is_enabled() {
  case "${1:-0}" in
    1|true|TRUE|on|ON|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

if [[ -d .git ]] && is_enabled "${AUTO_UPDATE:-0}"; then
  git pull || echo "Git auto-update failed; using the current project files."
fi

if [[ -n "${NODE_PACKAGES:-}" ]]; then
  read -r -a node_packages <<<"${NODE_PACKAGES}"
  /usr/local/bin/npm install "${node_packages[@]}"
fi

if [[ -n "${UNNODE_PACKAGES:-}" ]]; then
  read -r -a unnode_packages <<<"${UNNODE_PACKAGES}"
  /usr/local/bin/npm uninstall "${unnode_packages[@]}"
fi

if [[ -f /home/container/package.json ]]; then
  /usr/local/bin/npm install
fi

ensure_ytdlp() {
  if command -v yt-dlp >/dev/null 2>&1; then
    return 0
  fi

  echo "yt-dlp is missing from the selected Docker image."
  return 1
}

ensure_ytdlp || true

start_cloudflare_tunnel() {
  local cloudflare_dir="/home/container/.cloudflare"
  local cloudflared_bin

  cloudflared_bin="$(command -v cloudflared || true)"

  mkdir -p "$cloudflare_dir" || return 1
  touch "$cloudflare_dir/tunnel.log" || return 1
  chmod 700 "$cloudflare_dir"
  chmod 600 "$cloudflare_dir/tunnel.log"

  if [[ -z "${TUNNEL_TOKEN:-}" ]]; then
    echo "Cloudflare Tunnel is enabled, but TUNNEL_TOKEN is empty." | tee -a "$cloudflare_dir/tunnel.log"
    return 1
  fi

  if [[ -z "$cloudflared_bin" ]]; then
    echo "cloudflared is missing from the selected Docker image." | tee -a "$cloudflare_dir/tunnel.log"
    return 1
  fi

  echo "Starting Cloudflare Tunnel connector..." >>"$cloudflare_dir/tunnel.log"
  (
    "$cloudflared_bin" tunnel --no-autoupdate --loglevel info run >>"$cloudflare_dir/tunnel.log" 2>&1
    cloudflared_status=$?
    echo "Cloudflare Tunnel process exited (code ${cloudflared_status}). Check .cloudflare/tunnel.log." \
      | tee -a "$cloudflare_dir/tunnel.log"
  ) &

  echo "Cloudflare Tunnel launched; check .cloudflare/tunnel.log for connection status."
}

if is_enabled "${CLOUDFLARE_TUNNEL_ENABLED:-0}"; then
  start_cloudflare_tunnel || echo "Cloudflare Tunnel setup failed; application startup will continue."
else
  echo "Cloudflare Tunnel is disabled."
fi

if [[ -z "${STARTUP_COMMAND:-}" ]]; then
  echo "STARTUP_COMMAND is empty; cannot start the Node.js application."
  exit 1
fi

if [[ ! -f /home/container/package.json ]] \
  && [[ "$STARTUP_COMMAND" =~ ^[[:space:]]*(npm|pnpm|yarn)([[:space:]]|$) ]]; then
  echo "package.json was not found in /home/container."
  echo "Set Git Repo Address and reinstall, or upload the project files before starting the server."
  exit 1
fi

echo "Starting Node.js application..."
exec /bin/bash -c "$STARTUP_COMMAND"
