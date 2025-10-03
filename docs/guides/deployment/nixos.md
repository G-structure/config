# Linux (NixOS) Deployment

Guide to deploying this configuration on NixOS.

---

## Status

**📋 Planned** - NixOS support is designed but not yet fully implemented.

This document describes the planned NixOS deployment strategy.

---

## Overview

This configuration will support NixOS deployment with:
- Shared modules with macOS (nix-darwin)
- Linux-specific base configuration
- Systemd service management
- Multi-architecture support (x86_64, aarch64)

---

## Prerequisites

- NixOS installation media
- x86_64 or aarch64 system
- Administrator access
- Network connectivity

---

## Planned Structure

### Linux Base Module

`nix/modules/linux-base.nix` (placeholder exists):

```nix
{ config, pkgs, lib, ... }:
{
  # NixOS base configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  services.openssh.enable = true;

  system.stateVersion = "24.11";
}
```

### NixOS Configuration

In `flake.nix`:

```nix
nixosConfigurations.linux-workstation = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    ./nix/modules/common.nix
    ./nix/modules/linux-base.nix
    ./nix/profiles/cloud-cli.nix
    ./nix/profiles/developer.nix
    ./hosts/linux-workstation.nix

    home-manager.nixosModules.home-manager
    {
      home-manager.users.wikigen = import ./home/users/wikigen.nix;
    }
  ];
};
```

---

## Installation Steps (Planned)

### 1. Boot NixOS Installer

```bash
# Boot from USB/ISO
# Connect to network
sudo systemctl start wpa_supplicant
```

### 2. Partition Disk

```bash
# UEFI system
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart primary 512MiB 100%

# Format
mkfs.fat -F 32 -n boot /dev/sda1
mkfs.ext4 -L nixos /dev/sda2

# Mount
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
```

### 3. Clone Configuration

```bash
# Clone to /mnt
cd /mnt
git clone https://github.com/yourusername/Config.git /mnt/etc/nixos
cd /mnt/etc/nixos
```

### 4. Install NixOS

```bash
# Install
nixos-install --flake .#linux-workstation

# Set root password
nixos-install --root /mnt --no-root-passwd

# Reboot
reboot
```

### 5. Post-Install

```bash
# Update system
nixos-rebuild switch --flake /etc/nixos#linux-workstation

# Update flake
cd /etc/nixos
nix flake update
nixos-rebuild switch --flake .#linux-workstation
```

---

## Differences from macOS

### Package Manager

```nix
# macOS: Homebrew for GUI apps
homebrew.casks = [ "app" ];

# NixOS: All packages via Nix
environment.systemPackages = [ pkgs.app ];
```

### Services

```nix
# macOS: launchd
launchd.user.agents.myservice = { ... };

# NixOS: systemd
systemd.user.services.myservice = { ... };
```

### User Management

```nix
# NixOS: Declarative users
users.users.wikigen = {
  isNormalUser = true;
  extraGroups = [ "wheel" "networkmanager" ];
  shell = pkgs.zsh;
};
```

---

## Roadmap

### Phase 1: Basic Support
- [ ] Complete linux-base.nix module
- [ ] Test on VM
- [ ] Document installation process
- [ ] Add example NixOS configuration

### Phase 2: Feature Parity
- [ ] All profiles working on Linux
- [ ] Systemd service equivalents
- [ ] Linux-specific optimizations
- [ ] Multi-user support

### Phase 3: Advanced Features
- [ ] Impermanence setup
- [ ] Secure boot
- [ ] Full disk encryption
- [ ] Remote deployment

---

## Testing (When Implemented)

```bash
# Build VM for testing
nix build .#nixosConfigurations.linux-workstation.config.system.build.vm

# Run VM
./result/bin/run-linux-workstation-vm

# Test installation
nixos-rebuild build-vm --flake .#linux-workstation
```

---

## Next Steps

- **[Darwin Deployment](./darwin.md)** - macOS deployment (current)
- **[Cloud Deployment](./cloud.md)** - EC2/GCE deployment (planned)
- **[Design Doc](../../architecture/design.md)** - Architecture details

---

## Related Documentation

- [Structure Guide](../../architecture/structure.md) - Module system
- [Design Philosophy](../../architecture/design.md) - Platform strategy

---

## External References

- [NixOS Manual](https://nixos.org/manual/nixos/stable/) - Official docs
- [NixOS Installation](https://nixos.org/manual/nixos/stable/#sec-installation) - Install guide
- [NixOS Options](https://search.nixos.org/options) - Configuration options

---

**Status:** 📋 Planned - [Contribute on GitHub](#)
