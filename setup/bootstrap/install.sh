#!/usr/bin/env bash
set -euo pipefail

BASEDIR=$(dirname "$0")
export USER=$(whoami)

${BASEDIR}/install-nix.sh
${BASEDIR}/install-home-manager.sh ${USER}
