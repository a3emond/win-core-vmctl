# win-core-vmctl

CLI tool to create and manage a **headless Windows Server Core VM** on Linux (KVM/libvirt).
Use it to run **ASP.NET .NET Framework** builds in Windows containers without a GUI.

## Quickstart

```bash
git clone https://github.com/you/win-core-vmctl.git
cd win-core-vmctl

# 1. Install dependencies
./bin/provision_host.sh

# 2. Copy Windows ISO
cp ~/Downloads/Windows_Server_2022.iso artifacts/iso/

# 3. Configure
cp .env.example .env
nano .env   # edit settings (bridge, RAM, etc.)

# 4. Generate Autounattend ISO
./bin/gen_autounattend.sh

# 5. Bring up VM
./bin/vmctl.sh up

# 6. Get IP
./bin/vmctl.sh ip

# 7. SSH into Windows Core
./bin/vmctl.sh ssh

# Commands

- `./bin/vmctl.sh up` — create & start VM (idempotent)

- `./bin/vmctl.sh start` — start VM

- `./bin/vmctl.sh stop` — shutdown VM

- `./bin/vmctl.sh destroy` — delete VM + disk

- `./bin/vmctl.sh ip` — show VM IPs

- `./bin/vmctl.sh ssh` — connect to VM

# First run checklist

# 1) install host deps (first time only)
./bin/provision_host.sh

# 2) configure
cp .env.example .env
nano .env   # adjust VM_BRIDGE, RAM/CPU, etc.

# 3) put the Windows Server ISO
cp ~/Downloads/Windows_Server_2022.iso artifacts/iso/

# 4) generate Autounattend
./bin/gen_autounattend.sh

# 5) bring up VM (hands-off install)
./bin/vmctl.sh up

# 6) get the IP (wait 1–2 mins after first boot)
./bin/vmctl.sh ip

# 7) SSH in
./bin/vmctl.sh ssh

