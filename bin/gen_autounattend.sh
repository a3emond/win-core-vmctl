#!/usr/bin/env bash
set -Euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=bin/_lib.sh
. "$here/_lib.sh"; load_env

log "=== Generating unattended ISO for $VM_NAME ==="

require genisoimage
if ! command -v envsubst >/dev/null 2>&1; then
  warn "envsubst not installed, falling back to simple sed"
fi

# Prepare output directory
outdir="artifacts/autounattend"
mkdir -p "$outdir"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
log "Working in temp dir: $tmpdir"

# Render Autounattend.xml from template
if command -v envsubst >/dev/null 2>&1; then
  log "Rendering Autounattend.xml with envsubst"
  envsubst < templates/Autounattend.xml.tmpl > "$tmpdir/Autounattend.xml"
else
  log "Rendering Autounattend.xml with sed substitution"
  sed -e "s#\${VM_NAME}#$VM_NAME#g" \
      -e "s#\${ADMIN_PASSWORD}#$ADMIN_PASSWORD#g" \
      -e "s#\${TZ}#$TZ#g" \
      templates/Autounattend.xml.tmpl > "$tmpdir/Autounattend.xml"
fi
log "Rendered: $tmpdir/Autounattend.xml"

# Copy first boot script
cp templates/firstboot.ps1.tmpl "$tmpdir/firstboot.ps1"
log "Copied firstboot.ps1 provisioning script"

# Build the ISO
log "Building unattended ISO: $AUTO_ISO"
genisoimage -quiet -V AUTOUNATTEND -o "$AUTO_ISO" -J -R \
  "$tmpdir/Autounattend.xml" "$tmpdir/firstboot.ps1"

log "=== Unattended ISO generated successfully at $AUTO_ISO ==="

