# Windows VM on KVM/Libvirt (with Bridged Networking)

This project provisions a Windows Server VM on Linux (Pop!_OS / Ubuntu) using KVM + QEMU + libvirt, with **bridged networking** so the VM appears as a separate machine on the LAN.

---

## 1. Bridge Setup (Host Networking)

We configure a bridge (`br0`) so the VM has a LAN IP from the router:

```bash
# Create the bridge
sudo nmcli connection add type bridge ifname br0 con-name br0

# Attach your physical NIC (example: enp2s0)
sudo nmcli connection add type bridge-slave ifname enp2s0 master br0

# Bring bridge up
sudo nmcli connection up br0
sudo nmcli connection up bridge-slave-enp2s0

# Assign static/manual IP to host via bridge (adjust values as needed)
sudo nmcli connection modify br0 ipv4.method manual \
  ipv4.addresses 192.168.8.11/24 \
  ipv4.gateway 192.168.8.1 \
  ipv4.dns 192.168.8.1

# Enable autoconnect at boot
sudo nmcli connection modify br0 connection.autoconnect yes
sudo nmcli connection modify bridge-slave-enp2s0 connection.autoconnect yes
```

Check bridge state:

```bash
ip addr show br0
```

---

## 2. QEMU Bridge Helper Setup

QEMU requires explicit permission to attach to bridges.

```bash
# Create config directory and allow br0
sudo mkdir -p /etc/qemu
echo "allow br0" | sudo tee /etc/qemu/bridge.conf
```

Fix helper permissions:

```bash
sudo chgrp kvm /usr/lib/qemu/qemu-bridge-helper
sudo chmod u+s /usr/lib/qemu/qemu-bridge-helper
sudo chmod 4750 /usr/lib/qemu/qemu-bridge-helper
```

Verify:

```bash
ls -l /usr/lib/qemu/qemu-bridge-helper
# Should look like: -rwsr-x--- 1 root kvm ...
```

Ensure user is in `kvm` and `libvirt` groups:

```bash
groups $USER
sudo usermod -aG kvm,libvirt $USER
# Then log out & back in
```

---

## 3. Project Scripts Overview

- **`bin/provision_host.sh`** → Installs required host packages (`qemu`, `libvirt`, `virt-install`, `genisoimage`).
  
- **`bin/detect_host.sh`** → Verifies environment (kernel, bridge, dependencies).
  
- **`bin/gen_autounattend.sh`** → Builds `Autounattend.iso` with XML + PowerShell firstboot provisioning.
  
- **`bin/vmctl.sh`** → Main VM lifecycle manager.
  

All scripts need execution permission:

```bash
chmod +x bin/*.sh
```

---

## 4. Workflow

### Initial Provisioning

```bash
# Install KVM + dependencies
./bin/provision_host.sh

# Verify environment
./bin/detect_host.sh

# Generate unattended ISO for Windows setup
./bin/gen_autounattend.sh

# Create disk and start installation
./bin/vmctl.sh up
```

---

### Managing the VM

```bash
./bin/vmctl.sh start    # Start VM
./bin/vmctl.sh stop     # Graceful shutdown
./bin/vmctl.sh destroy  # Delete domain + disk + autounattend
./bin/vmctl.sh ip       # Show VM’s LAN IP
./bin/vmctl.sh ssh      # SSH into VM as Administrator
```

---

## 5. Monitoring Installation

- Check VM state:
  
  ```bash
  virsh list --all
  ```
  
- Attach console:
  
  ```bash
  virsh console win-core-2022
  # Exit: Ctrl+]
  ```
  
- Get VNC display:
  
  ```bash
  virsh vncdisplay win-core-2022
  # Example output: :0 → connect with vncviewer localhost:5900
  ```
  

---

## 6. Notes

- VM disk stored under: `artifacts/images/win-core-2022.qcow2`
  
- Autounattend ISO under: `artifacts/autounattend/win-core-2022-autounattend.iso`
  
- VM appears as a **separate host on the LAN** (e.g., `192.168.8.xxx`).
  
- After install, connect with:
  
  ```bash
  ssh Administrator@<VM_IP>
  ```
  

---

