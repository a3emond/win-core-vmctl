#!/usr/bin/env bash
set -Eeuo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=bin/_lib.sh
. "$here/_lib.sh"; load_env

require uname
ensure_libvirt
require genisoimage || log "Note: genisoimage not installed yet"

log "Kernel: $(uname -r)"
log "Bridge check: $VM_BRIDGE"
if ! ip link show "$VM_BRIDGE" >/dev/null 2>&1; then
  log "Note: $VM_BRIDGE not found. Use virbr0 (NAT) or create a bridge."
fi

log "All good. Dependencies present."

