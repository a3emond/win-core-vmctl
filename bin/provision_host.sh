#!/usr/bin/env bash
set -Euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=bin/_lib.sh
. "$here/_lib.sh"; load_env

log "=== Provisioning host for KVM/Libvirt ==="

require sudo

log "Updating package lists..."
sudo apt update -y || die "apt update failed"

log "Installing required packages: qemu-kvm libvirt-daemon libvirt-clients virtinst genisoimage"
sudo apt install -y qemu-kvm libvirt-daemon libvirt-clients virtinst genisoimage || die "apt install failed"

# Add user to libvirt group for permission to manage VMs
if id -nG "$USER" | grep -qw libvirt; then
  log "User $USER is already in libvirt group"
else
  log "Adding $USER to libvirt group"
  sudo usermod -aG libvirt "$USER" || warn "Could not add $USER to libvirt group"
  warn "You must log out and back in (or reboot) for group membership to take effect"
fi

log "Enabling and starting libvirtd service"
sudo systemctl enable --now libvirtd || warn "Could not enable/start libvirtd"

log "=== Provisioning complete ==="

