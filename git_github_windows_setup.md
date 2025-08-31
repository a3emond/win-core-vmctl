# Git + GitHub Setup on Windows Server VM (via SSH)

This procedure configures Git and GitHub access inside your Windows VM, accessed exclusively via SSH (PowerShell terminal).

---

## 1. Install Git

If `winget` is available:

```powershell
winget install --id Git.Git -e --source winget
```

Otherwise, download and install Git manually:

```powershell
Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/latest/download/Git-2.45.2-64-bit.exe" -OutFile "$env:TEMP\git-installer.exe"
Start-Process "$env:TEMP\git-installer.exe" -ArgumentList '/VERYSILENT' -Wait
```

Verify:

```powershell
git --version
```

---

## 2. Configure Git Identity

```powershell
git config --global user.name "Your Name"
git config --global user.email "your_email@example.com"
```

---

## 3. Generate SSH Key

```powershell
ssh-keygen -t ed25519 -C "your_email@example.com"
```

* Save in default path: `C:\Users\Administrator\.ssh\id_ed25519`
* Optionally add a passphrase (Enter for none).

---

## 4. Start SSH Agent and Add Key

```powershell
Start-Service ssh-agent
Get-Service ssh-agent
ssh-add $env:USERPROFILE\.ssh\id_ed25519
```

---

## 5. Add Public Key to GitHub

```powershell
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub
```

* Copy the full key.
* Go to GitHub → **Settings → SSH and GPG keys → New SSH key** → Paste → Save.

---

## 6. Test GitHub SSH Access

```powershell
ssh -T git@github.com
```

Expected:

```
Hi <your-username>! You've successfully authenticated, but GitHub does not provide shell access.
```

---

## 7. Use GitHub

Clone a repo:

```powershell
git clone git@github.com:yourusername/yourrepo.git
cd yourrepo
```

Commit & push:

```powershell
git add .
git commit -m "Initial commit from Windows VM"
git push origin main
```

---

✅ Your Windows VM is now configured for Git + GitHub via SSH keys, just like a Linux dev box.

