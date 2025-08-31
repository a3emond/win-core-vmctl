#!/usr/bin/env bash
set -Euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=bin/_lib.sh
. "$here/_lib.sh"; load_env; ensure_libvirt

# --- Create VM disk ---
create_disk() {
  mkdir -p "$(dirname "$VM_DISK")"
  if [ ! -f "$VM_DISK" ]; then
    log "Creating VM disk at $VM_DISK (${VM_DISK_GB}G)"
    qemu-img create -f qcow2 "$VM_DISK" "${VM_DISK_GB}G" >/dev/null
  else
    log "Reusing existing disk: $VM_DISK"
  fi
}

# --- Define and install VM ---
define_install() {
  [ -f "$WIN_ISO" ]   || die "Windows ISO not found at $WIN_ISO"
  [ -f "$AUTO_ISO" ]  || die "Autounattend ISO not found at $AUTO_ISO (run ./bin/gen_autounattend.sh first)"

  create_disk

  log "Launching virt-install for $VM_NAME…"
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
  log "virt-install completed"
}

# --- Commands ---
cmd="${1:-help}"
case "$cmd" in
  up)
    if dom_exists; then
      log "Domain already exists: $VM_NAME"
    else
      define_install
    fi

    if dom_running; then
      log "VM $VM_NAME is already running"
    else
      virsh start "$VM_NAME" >/dev/null || die "Failed to start VM $VM_NAME"
      log "Started VM $VM_NAME"
    fi

    virsh autostart "$VM_NAME" >/dev/null 2>&1 || true
    log "VM $VM_NAME set to autostart on host boot"
    ;;
  start)
    virsh start "$VM_NAME" >/dev/null || die "Failed to start VM $VM_NAME"
    log "Started VM $VM_NAME"
    ;;
  stop)
    virsh shutdown "$VM_NAME" >/dev/null || die "Failed to shutdown VM $VM_NAME"
    log "Shutdown signal sent to VM $VM_NAME"
    ;;
  destroy)
    virsh destroy "$VM_NAME" >/dev/null 2>&1 || true
    virsh undefine "$VM_NAME" --remove-all-storage || true
    rm -f "$VM_DISK" "$AUTO_ISO"
    log "Destroyed domain and removed disk/autounattend"
    ;;
  ip)
    log "Fetching IP for $VM_NAME"
    virsh domifaddr "$VM_NAME" || warn "No IP assigned yet (DHCP may take a moment)"
    ;;
  ssh)
    ip=$(virsh domifaddr "$VM_NAME" | awk '/ipv4/ {print $4}' | sed 's#/.*##' | head -n1)
    [ -n "$ip" ] || die "No IP yet. Try again in a minute."
    log "Connecting via SSH to Administrator@$ip"
    exec ssh Administrator@"$ip"
    ;;
  help|*)
    cat <<EOF
Usage: $0 <command>

Commands:
  up       Create (if needed), install, and start the VM
  start    Start the VM
  stop     Graceful shutdown
  destroy  Destroy VM and remove disk/autounattend
  ip       Show VM IP addresses
  ssh      SSH into VM as Administrator
EOF
    ;;
esac


