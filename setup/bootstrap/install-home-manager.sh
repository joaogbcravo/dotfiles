#!/usr/bin/env bash
set -euo pipefail

USER=$1

echo "Install Home-Manager..."
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
cd ~/.dotfiles

if [ ! -f  $HOME/.config/home-manager/home.nix ]; then
    echo "Installing Home Manager..."
    nix --extra-experimental-features "nix-command flakes" \
        run github:nix-community/home-manager/release-24.05 -- \
            switch --flake .#$(hostname) --show-trace -b backup

else
    echo "Home Manager already installed."
fi

export PATH=$HOME/.nix-profile/bin:$PATH
#export USER=sandbox
home-manager switch --flake .#$(hostname) --show-trace
echo "✅ Home-Manager installed."

zsh
