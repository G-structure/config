---
title: Installation Guide
---


Detailed installation instructions for this Nix configuration on macOS.

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Step 1: Install Nix](#step-1-install-nix)
- [Step 2: Install Homebrew](#step-2-install-homebrew)
- [Step 3: Clone Configuration](#step-3-clone-configuration)
- [Step 4: Customize for Your System](#step-4-customize-for-your-system)
- [Step 5: First-Time Activation](#step-5-first-time-activation)
- [Step 6: Verify Installation](#step-6-verify-installation)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

---

## Overview

This guide walks you through installing this modular Nix configuration on macOS. The setup includes:

- **Nix package manager** - Reproducible system configuration
- **nix-darwin** - macOS system management
- **Home Manager** - User environment management
- **Homebrew** - macOS GUI applications
- **Hardware security** - Optional Ledger wallet integration
- **Secrets management** - Optional SOPS setup

**Estimated time:** 15-30 minutes

---

## Prerequisites

### System Requirements

- **OS:** macOS 11 (Big Sur) or later
- **Architecture:** Apple Silicon (M1/M2/M3) or Intel
- **Disk Space:** 10 GB free space
- **Permissions:** Administrator access (sudo)

### Before You Begin

- [ ] Backup important files
- [ ] Have Terminal.app ready
- [ ] Know your GitHub username (if forking this repo)
- [ ] Optional: Ledger Nano S device for hardware security

---

## Step 1: Install Nix

### Choose Your Installer

We recommend the **Determinate Systems installer** for macOS:

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
```

#### Why Determinate Nix?

✅ Flakes enabled by default
✅ Better macOS integration
✅ No systemd/daemon complexity
✅ Optimized for Apple Silicon
✅ Includes nix-darwin support

#### Alternative: Official Installer

If you prefer the official installer:

```bash
sh <(curl -L https://nixos.org/nix/install)
```

Then enable flakes manually:

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Verify Nix Installation

```bash
# Check Nix version
nix --version

# Should show: nix (Nix) 2.18.x or later

# Test Nix command
nix run nixpkgs#hello
```

---

## Step 2: Install Homebrew

Homebrew is used for macOS-specific GUI applications (Ledger Live, etc.):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Add Homebrew to PATH

The installer will show instructions. Typically:

```bash
# For Apple Silicon
eval "$(/opt/homebrew/bin/brew shellenv)"

# For Intel
eval "$(/usr/local/bin/brew shellenv)"
```

Add to your `~/.zshrc`:

```bash
# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"  # or /usr/local for Intel
```

### Verify Homebrew

```bash
brew --version
# Should show: Homebrew 4.x.x or later
```

---

## Step 3: Clone Configuration

### Option A: Fork This Repository (Recommended)

1. Fork on GitHub: `https://github.com/original-repo/Config`
2. Clone your fork:
   ```bash
   cd ~
   git clone https://github.com/YOUR-USERNAME/Config.git
   cd Config
   ```

### Option B: Clone Directly

```bash
cd ~
git clone https://github.com/original-repo/Config.git
cd Config
```

### Verify Clone

```bash
ls -la
# Should see: flake.nix, nix/, hosts/, home/, docs/
```

---

## Step 4: Customize for Your System

### Create Your Host Configuration

1. **Copy the example:**
   ```bash
   cp hosts/wikigen-mac.nix hosts/YOUR-HOSTNAME.nix
   ```

2. **Edit your host file:**
   ```bash
   nano hosts/YOUR-HOSTNAME.nix
   ```

3. **Update the configuration:**
   ```nix
   { config, pkgs, self, ... }:
   {
     # Change to your username
     system.primaryUser = "yourusername";

     users.users.yourusername = {
       name = "yourusername";
       home = "/Users/yourusername";
     };

     # System-specific packages (optional)
     environment.systemPackages = with pkgs; [
       # Add any additional packages here
     ];
   }
   ```

### Create Your User Configuration

1. **Copy the example:**
   ```bash
   cp home/users/wikigen.nix home/users/YOUR-USERNAME.nix
   ```

2. **Edit your user file:**
   ```bash
   nano home/users/YOUR-USERNAME.nix
   ```

3. **Update git config:**
   ```nix
   programs.git = {
     enable = true;
     userName = "Your Name";
     userEmail = "your.email@example.com";
   };
   ```

### Update flake.nix

Add your host configuration to `flake.nix`:

```nix
# In darwinConfigurations
your-hostname = darwin.lib.darwinSystem {
  system = "aarch64-darwin";  # or "x86_64-darwin" for Intel
  modules = [
    ./nix/modules/common.nix
    ./nix/modules/darwin-base.nix
    ./nix/modules/darwin/homebrew.nix
    ./nix/profiles/cloud-cli.nix
    ./nix/profiles/developer.nix
    # Optional: ./nix/modules/secrets/sops.nix
    ./hosts/your-hostname.nix

    home-manager.darwinModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.yourusername = import ./home/users/yourusername.nix;
    }
  ];
  specialArgs = { inherit self; };
};
```

---

## Step 5: First-Time Activation

### Backup Existing Configuration

```bash
# Backup zsh config
mv ~/.zshrc ~/.zshrc.backup 2>/dev/null || true

# Backup other configs (optional)
cp -r ~/.config ~/.config.backup 2>/dev/null || true
```

### Run First-Time Setup

```bash
# First activation requires sudo and nix run
sudo nix run nix-darwin -- switch --flake .#your-hostname
```

This will:
1. Build your system configuration
2. Install all packages
3. Set up shell configuration
4. Configure system settings
5. Install Homebrew casks

**Note:** First build may take 10-20 minutes as it downloads all dependencies.

### Activate Your Shell

```bash
# Reload shell to pick up new config
exec zsh
```

---

## Step 6: Verify Installation

### Check System Configuration

```bash
# View current system
darwin-rebuild --help

# Check system generation
ls -l /run/current-system

# View installed packages
darwin-rebuild list-generations
```

### Test Installed Tools

```bash
# Nix tools
nix --version
darwin-rebuild --help

# Cloud CLIs
aws --version
kubectl version --client
terraform --version

# Development tools
git --version
jq --version

# Container tools (requires Colima start)
colima version
docker --version
```

### Verify Homebrew Apps

```bash
# List installed casks
brew list --cask

# Launch Ledger Live (if installed)
open -a "Ledger Live"
```

### Test Nix Commands

```bash
# Build a package
nix build .#ai-clis

# Enter dev shell
nix develop

# Update flake
nix flake update
```

---

## Troubleshooting

### Build Fails with "version mismatch"

**Problem:** nix-darwin version doesn't match nixpkgs

**Solution:**
```bash
# Update flake lock
nix flake update

# Rebuild
darwin-rebuild switch --flake .#your-hostname
```

### "Command not found" after install

**Problem:** Shell hasn't reloaded new PATH

**Solution:**
```bash
# Reload shell
exec zsh

# Or source the profile
source ~/.zshrc
```

### Homebrew not in PATH

**Problem:** Homebrew shellenv not configured

**Solution:**
```bash
# Add to ~/.zshrc
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc

# Reload
exec zsh
```

### Permission denied errors

**Problem:** Missing sudo for first activation

**Solution:**
```bash
# First time MUST use sudo
sudo nix run nix-darwin -- switch --flake .#your-hostname

# Subsequent builds don't need sudo
darwin-rebuild switch --flake .#your-hostname
```

### Build takes forever

**Problem:** Building from source instead of using binary cache

**Solution:**
```bash
# Check substituters are configured
nix show-config | grep substituters

# Should include: https://cache.nixos.org
```

### Flake lock permission issues

**Problem:** flake.lock owned by root

**Solution:**
```bash
# Fix ownership
sudo chown $USER:staff flake.lock

# Or regenerate
rm flake.lock
nix flake update
```

---

## Next Steps

### Essential Configuration

1. **[First Steps Guide](./first-steps.md)** - Learn to customize your setup
2. **[Ledger Setup](../guides/hardware-security/ledger-setup.md)** - Configure hardware wallet
3. **[SOPS Setup](../guides/secrets-management/sops.md)** - Set up secrets management

### Learn the Architecture

4. **[Structure Guide](../architecture/structure.md)** - Understand modular organization
5. **[Design Philosophy](../architecture/design.md)** - Learn architectural decisions
6. **[Nix Fundamentals](../reference/nix-fundamentals.md)** - Deep dive into Nix

### Extend Your Config

7. **[Adding Packages](../guides/development/adding-packages.md)** - Install new software
8. **[Creating Modules](../guides/development/creating-modules.md)** - Write custom modules
9. **[Creating Profiles](../guides/development/creating-profiles.md)** - Build feature bundles

---

## Daily Usage

After installation, update your system with:

```bash
# Apply configuration changes
darwin-rebuild switch --flake .#your-hostname

# Update dependencies
nix flake update
darwin-rebuild switch --flake .#your-hostname

# Garbage collect old generations
nix-collect-garbage --delete-older-than 30d
```

---

## Get Help

- **[Troubleshooting Guide](../reference/troubleshooting.md)** - Common issues
- **[CLI Commands](../reference/cli-commands.md)** - Command reference
- **[NixOS Discourse](https://discourse.nixos.org/)** - Community forum
- **[GitHub Issues](https://github.com/yourusername/Config/issues)** - Report bugs

---

**Installation complete! 🎉**

Continue with [First Steps](./first-steps.md) to customize your new system.
