#!/usr/bin/env bash
set -euo pipefail

USER_NAME="sandbox"
USER_HOME=$(eval echo "~$USER_NAME")

# Ensure sandbox user exists
if ! id "$USER_NAME" &>/dev/null; then
    echo "User '$USER_NAME' does not exist. Exiting."
    exit 1
fi

echo '. /nix/var/nix/profiles/default/etc/profile.d/nix.sh' >> /home/sandbox/.bashrc
source /home/sandbox/.bashrc

if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix.sh'
fi

# Check if Nix is installed for sandbox user
if ! nix --version &>/dev/null; then
    
    echo "Nix not found for $USER_NAME. Installing via Determinate Systems installer..."
    nix
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux \
        --extra-conf "sandbox = false" \
        --init none \
        --no-start-daemon \
        --no-confirm
else
    echo "Nix already installed for $USER_NAME."
fi

# Ensure nix profile is sourced in .bashrc
if ! grep -q ". /nix/var/nix/profiles/default/etc/profile.d/nix.sh" "$USER_HOME/.bashrc"; then
    echo "Adding nix.sh to $USER_HOME/.bashrc"
    echo ". /nix/var/nix/profiles/default/etc/profile.d/nix.sh" >> "$USER_HOME/.bashrc"
fi

# Setup Home Manager via flakes for user
echo "Installing Home Manager using flakes..."

# Enable flakes
mkdir -p "$HOME/.config/nix"
echo 'experimental-features = nix-command flakes' >> "$HOME/.config/nix/nix.conf"

# Home Manager config
HM_DIR="$HOME/home"
HM_CONFIG_DIR="$HOME/.config/home-manager"

/home/sandbox/.nix-profile/bin/home-manager switch --flake .#linux-sandbox

# Run whatever the user provided (bash by default)
exec "$@"

