#!/usr/bin/env bash
set -Eeuo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=bin/_lib.sh
. "$here/_lib.sh"; load_env
require sudo

log "Installing KVM/libvirt/virt tools…"
sudo apt update -y
sudo apt install -y qemu-kvm libvirt-daemon libvirt-clients virtinst genisoimage
sudo usermod -aG libvirt "$USER" || true
log "Provisioning done. If this is your first time, re-login so your user gets libvirt group."

