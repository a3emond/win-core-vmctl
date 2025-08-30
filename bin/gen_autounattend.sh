#!/usr/bin/env bash
set -Eeuo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=bin/_lib.sh
. "$here/_lib.sh"; load_env
require genisoimage
require envsubst || true

mkdir -p artifacts/autounattend
tmpdir="$(mktemp -d)"; trap 'rm -rf "$tmpdir"' EXIT

# Render templates (prefer envsubst if present, else simple sed)
if command -v envsubst >/dev/null 2>&1; then
  envsubst < templates/Autounattend.xml.tmpl > "$tmpdir/Autounattend.xml"
else
  sed -e "s#\${VM_NAME}#${VM_NAME}#g" \
      -e "s#\${ADMIN_PASSWORD}#${ADMIN_PASSWORD}#g" \
      -e "s#\${TZ}#${TZ}#g" templates/Autounattend.xml.tmpl > "$tmpdir/Autounattend.xml"
fi

cp templates/firstboot.ps1.tmpl "$tmpdir/firstboot.ps1"

genisoimage -quiet -V AUTOUNATTEND -o "$AUTO_ISO" -J -R \
  "$tmpdir/Autounattend.xml" "$tmpdir/firstboot.ps1"

log "Generated $AUTO_ISO"

