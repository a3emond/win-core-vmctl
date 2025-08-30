#!/usr/bin/env bash
set -Eeuo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=bin/_lib.sh
. "$here/_lib.sh"; load_env; ensure_libvirt

create_disk() {
  mkdir -p "$(dirname "$VM_DISK")"
  if [ ! -f "$VM_DISK" ]; then
    log "Creating disk $VM_DISK (${VM_DISK_GB}G)"
    qemu-img create -f qcow2 "$VM_DISK" "${VM_DISK_GB}G" >/dev/null
  fi
}

define_install() {
  [ -f "$WIN_ISO" ]  || die "Windows ISO not found at $WIN_ISO"
  [ -f "$AUTO_ISO" ] || die "Autounattend ISO not found; run: ./bin/gen_autounattend.sh"
  create_disk

  log "Launching virt-install (hands-off)…"
  virt-install \
    --name "$VM_NAME" \
    --memory "$VM_RAM_MB" \
    --vcpus "$VM_VCPUS" \
    --os-variant win2k22 \
    --cpu host-passthrough \
    --disk path="$VM_DISK",bus=virtio,format=qcow2 \
    --cdrom "$WIN_ISO" \
    --disk path="$AUTO_ISO",device=cdrom \
    --network bridge="$VM_BRIDGE",model=virtio \
    --graphics none \
    --noautoconsole \
    --boot cdrom,hd,menu=on \
    --wait -1
}

cmd="${1:-help}"
case "$cmd" in
  up)
    if dom_exists; then
      log "Domain exists: $VM_NAME"
    else
      define_install
    fi
    if ! dom_running; then
      virsh start "$VM_NAME" >/dev/null
      log "Started $VM_NAME"
    fi
    virsh autostart "$VM_NAME" >/dev/null 2>&1 || true
    log "VM up. Windows will reboot once after firstboot provisioning."
    ;;
  start)
    virsh start "$VM_NAME" || true
    ;;
  stop)
    virsh shutdown "$VM_NAME" || true
    ;;
  destroy)
    virsh destroy "$VM_NAME" >/dev/null 2>&1 || true
    virsh undefine "$VM_NAME" --remove-all-storage || true
    rm -f "$VM_DISK" "$AUTO_ISO"
    log "Destroyed domain and removed disk/autounattend."
    ;;
  ip)
    virsh domifaddr "$VM_NAME" || true
    ;;
  ssh)
    ip=$(virsh domifaddr "$VM_NAME" | awk '/ipv4/ {print $4}' | sed 's#/.*##' | head -n1)
    [ -n "$ip" ] || die "No IP yet. Try again in a minute."
    exec ssh Administrator@"$ip"
    ;;
  help|*)
    cat <<EOF
Usage: $0 <command>
  up        Create (if needed), install, and start the VM
  start     Start the VM
  stop      Graceful shutdown
  destroy   Destroy and remove disk/autounattend
  ip        Show VM IPs
  ssh       SSH into VM as Administrator
EOF
    ;;
esac

