#!/usr/bin/env bash
set -euo pipefail

BASEDIR=$(dirname "$0")
export USER=$(whoami)

sudo ${BASEDIR}/install-nix.sh
${BASEDIR}/install-home-manager.sh ${USER}
