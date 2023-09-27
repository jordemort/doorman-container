#!/usr/bin/env bash
set -euo pipefail

while [ ! -e /mnt/doorman/pts ]; do
  sleep 0.1
done
