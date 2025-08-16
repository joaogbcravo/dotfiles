#!/usr/bin/env bash
set -euo pipefail

# Determine the OS and environment
detect_platform() {
  unameOut="$(uname -s)"
  case "${unameOut}" in
      Linux*)     os=Linux;;
      Darwin*)    os=Mac;;
      *)          os="UNKNOWN:${unameOut}"
  esac

  echo "${os}"
}


is_docker() {
  local container=/run/systemd/container
  test -f "$container" && grep -qE '^docker$' "$container"
}


has_systemd() {
  command -v systemctl >/dev/null 2>&1 && \
  [ "$(ps -p 1 -o comm=)" = "systemd" ]
}

install_nix() {
  local extra_flags=()
  # Check environment specifics
  if [[ "$1" == "Linux" ]]; then
    if is_docker && ! has_systemd; then
      echo "Detected Docker without systemd: installing Nix in --no-daemon mode."
      extra_flags+=(linux --no-start-daemon --init none --extra-conf "sandbox = false")
    fi
  fi

  # Run the Determinate installer
  if ! which nix ; then
    curl --proto '=https' --tlsv1.2 -sSf -L  https://install.determinate.systems/nix > /tmp/install-nix
    sh /tmp/install-nix install "${extra_flags[@]}" --no-confirm
  else
    echo "Nix already installed. Skipping"
  fi

  if [[ "$1" == "Linux" ]]; then
    if is_docker && ! has_systemd; then
      chown -R sandbox /nix
      sudo tee /etc/nix/nix.conf > /dev/null <<'EOF'
# WARNING: this file is generated from the nix.* options in
# your nix-darwin configuration. Do not edit it!
allowed-users = *
auto-optimise-store = false
build-users-group = nixbld
builders =
cores = 0
experimental-features = nix-command flakes
max-jobs = auto
require-sigs = true
sandbox = false
sandbox-fallback = false
substituters = https://cache.nixos.org/
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
trusted-substituters =
trusted-users = root
extra-sandbox-paths =
EOF

      #source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      source /nix/var/nix/profiles/default/etc/profile.d/nix.sh
    fi
  fi

}

main() {
  platform=$(detect_platform)
  echo "Detected platform: $platform"

  install_nix "$platform"

  echo "✅ Nix installation completed."
  echo "👉 Please restart your shell or run: source /nix/var/nix/profiles/default/etc/profile.d/nix.sh"
}

main "$@"