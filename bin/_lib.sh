#!/usr/bin/env bash
set -Eeuo pipefail

log() { printf "[%s] %s\n" "$(date +%H:%M:%S)" "$*"; }
die() { printf "ERROR: %s\n" "$*\n" >&2; exit 1; }
require() { command -v "$1" >/dev/null 2>&1 || die "Missing dependency: $1"; }

load_env() {
  [ -f .env ] || die ".env not found. Copy .env.example to .env and edit."
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
}

ensure_libvirt() {
  require virsh
  require virt-install
  require qemu-img
  [ -S /var/run/libvirt/libvirt-sock ] || die "libvirt daemon not available"
}

dom_exists()  { virsh dominfo "$VM_NAME" >/dev/null 2>&1; }
dom_running() { [ "$(virsh domstate "$VM_NAME" 2>/dev/null || echo 'shut off')" = "running" ]; }

