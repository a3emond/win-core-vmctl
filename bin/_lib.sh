#!/usr/bin/env bash
set -Euo pipefail

# --- Logging helpers ---
log() {
  printf "\033[1;32m[%s] %s\033[0m\n" "$(date +%H:%M:%S)" "$*"
}
warn() {
  printf "\033[1;33m[%s] WARNING: %s\033[0m\n" "$(date +%H:%M:%S)" "$*"
}
die() {
  printf "\033[1;31m[%s] ERROR: %s\033[0m\n" "$(date +%H:%M:%S)" "$*" >&2
  exit 1
}

# --- Dependency check ---
require() {
  if command -v "$1" >/dev/null 2>&1; then
    log "Dependency OK: $1"
  else
    die "Missing dependency: $1"
  fi
}

# --- Load environment ---
load_env() {
  [ -f .env ] || die ".env not found. Copy .env.example to .env and edit."
  set -a
  . ./.env
  set +a
  log "Environment loaded: VM_NAME=$VM_NAME, BRIDGE=$VM_BRIDGE, RAM=${VM_RAM_MB}MB, vCPUs=$VM_VCPUS"
}

# --- Libvirt availability check ---
ensure_libvirt() {
  require virsh
  require virt-install
  require qemu-img
  if [ -S /var/run/libvirt/libvirt-sock ]; then
    log "libvirt daemon is available"
  else
    die "libvirt daemon not available"
  fi
}

# --- VM existence check ---
dom_exists() {
  if virsh dominfo "$VM_NAME" >/dev/null 2>&1; then
    log "VM $VM_NAME exists"
    return 0
  else
    log "VM $VM_NAME does not exist"
    return 1
  fi
}

# --- VM running state check ---
dom_running() {
  if [ "$(virsh domstate "$VM_NAME" 2>/dev/null || echo 'shut off')" = "running" ]; then
    log "VM $VM_NAME is running"
    return 0
  else
    log "VM $VM_NAME is not running"
    return 1
  fi
}

