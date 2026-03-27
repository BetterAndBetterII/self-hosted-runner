#!/bin/bash

set -euo pipefail

: "${REPO:?REPO is required}"
: "${REG_TOKEN:?REG_TOKEN is required}"
: "${NAME:?NAME is required}"

cd /home/runner/actions-runner || exit
./config.sh --unattended --replace --url "https://github.com/${REPO}" --token "${REG_TOKEN}" --name "${NAME}"

cleanup() {
  echo "Removing runner..."
  ./config.sh remove --unattended --token "${REG_TOKEN}"
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!
