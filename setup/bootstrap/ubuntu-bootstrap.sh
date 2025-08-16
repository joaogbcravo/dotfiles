#!/usr/bin/env bash
set -euo pipefail

# Requires super user privileges

echo 'kernel.apparmor_restrict_unprivileged_userns = 0' |
  sudo tee /etc/sysctl.d/20-apparmor-donotrestrict.conf