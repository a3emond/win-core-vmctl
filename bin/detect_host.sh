#!/usr/bin/env bash
set -Euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=bin/_lib.sh
. "$here/_lib.sh"; load_env

# --- Host detection / sanity checks ---

log "=== Host Environment Detection ==="

# Check dependencies
require uname
ensure_libvirt
if command -v genisoimage >/dev/null 2>&1; then
  log "Dependency OK: genisoimage"
else
  warn "genisoimage not installed (needed for unattended ISO build)"
fi

# Kernel version
log "Kernel: $(uname -r)"

# Bridge check
log "Checking network bridge: $VM_BRIDGE"
if ip link show "$VM_BRIDGE" >/dev/null 2>&1; then
  state=$(ip -o link show "$VM_BRIDGE" | awk '{print $9}')
  log "Bridge $VM_BRIDGE exists (state=$state)"
else
  warn "Bridge $VM_BRIDGE not found. Use virbr0 (NAT) or create a proper LAN bridge (e.g. br0)."
fi

log "=== Host detection complete: All essential checks passed ==="

