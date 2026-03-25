#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NODE_VERSION="$(tr -d '[:space:]' < "$REPO_ROOT/.nvmrc")"
FLUTTER_DIR="${FLUTTER_DIR:-$HOME/flutter}"
FLUTTER_BIN="$FLUTTER_DIR/bin/flutter"
BASHRC_FILE="${HOME}/.bashrc"

APT_PACKAGES=(
  build-essential
  curl
  file
  git
  jq
  libglu1-mesa
  unzip
  xz-utils
  zip
)

log() {
  printf '[setup-wsl-dev] %s\n' "$*"
}

append_once() {
  local line="$1"
  local file="$2"

  if ! grep -Fqx "$line" "$file" 2>/dev/null; then
    printf '\n%s\n' "$line" >> "$file"
  fi
}

require_wsl() {
  if ! grep -qi microsoft /proc/version 2>/dev/null; then
    log "This script is intended for WSL. Aborting."
    exit 1
  fi
}

install_apt_packages() {
  log "Installing base apt packages."
  sudo apt-get update
  sudo apt-get install -y "${APT_PACKAGES[@]}"
}

install_nvm() {
  if [ -s "${HOME}/.nvm/nvm.sh" ]; then
    log "nvm already installed."
    return
  fi

  log "Installing nvm."
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
}

setup_node() {
  # shellcheck disable=SC1091
  source "${HOME}/.nvm/nvm.sh"

  log "Installing and activating Node ${NODE_VERSION}."
  nvm install "${NODE_VERSION}"
  nvm alias default "${NODE_VERSION}"
  nvm use "${NODE_VERSION}"

  append_once 'export NVM_DIR="$HOME/.nvm"' "$BASHRC_FILE"
  append_once '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' "$BASHRC_FILE"
}

install_flutter() {
  if [ -x "$FLUTTER_BIN" ]; then
    log "Flutter SDK already present at ${FLUTTER_DIR}."
  else
    log "Installing Flutter stable SDK to ${FLUTTER_DIR}."
    rm -rf "$FLUTTER_DIR"
    git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_DIR"
  fi

  append_once 'export PATH="$HOME/flutter/bin:$PATH"' "$BASHRC_FILE"
  export PATH="$FLUTTER_DIR/bin:$PATH"

  log "Running flutter precache and doctor."
  "$FLUTTER_BIN" config --enable-web
  "$FLUTTER_BIN" precache --web
  "$FLUTTER_BIN" doctor
}

check_docker_desktop_bridge() {
  if command -v docker.exe >/dev/null 2>&1; then
    log "docker.exe detected. Checking Docker Desktop bridge."
    docker.exe version >/dev/null
    docker.exe compose version >/dev/null
    log "Docker Desktop bridge is available from WSL."
    return
  fi

  log "docker.exe not found. Install Docker Desktop on Windows and enable WSL integration."
}

bootstrap_repo() {
  log "Preparing repo env files."
  if [ ! -f "$REPO_ROOT/.env" ]; then
    cp "$REPO_ROOT/.env.example" "$REPO_ROOT/.env"
  fi

  if [ ! -f "$REPO_ROOT/services/api/.env" ]; then
    cp "$REPO_ROOT/services/api/.env.example" "$REPO_ROOT/services/api/.env"
  fi

  # shellcheck disable=SC1091
  source "${HOME}/.nvm/nvm.sh"
  nvm use "${NODE_VERSION}" >/dev/null

  log "Installing API dependencies and generating Prisma client."
  (
    cd "$REPO_ROOT/services/api"
    npm install
    npm run prisma:generate
  )

  log "Installing Flutter app dependencies."
  (
    cd "$REPO_ROOT/apps/mobile_flutter"
    "$FLUTTER_BIN" pub get
  )
}

print_next_steps() {
  cat <<EOF

WSL setup is complete.

Installed / prepared:
- apt base packages
- nvm + Node ${NODE_VERSION}
- Flutter SDK at ${FLUTTER_DIR}
- repo .env files
- API npm dependencies + Prisma client
- Flutter pub dependencies

Next recommended commands:
1. cd "$REPO_ROOT"
2. docker.exe compose -f docker-compose.yml up -d postgres
3. cd "$REPO_ROOT/services/api" && source ~/.nvm/nvm.sh && nvm use ${NODE_VERSION} && npm run db:reset:seed
4. In VS Code Remote WSL, run "Full Stack: WSL Debug"

If flutter is not found in a new shell, run:
source ~/.bashrc
EOF
}

main() {
  require_wsl
  install_apt_packages
  install_nvm
  setup_node
  install_flutter
  check_docker_desktop_bridge
  bootstrap_repo
  print_next_steps
}

main "$@"
