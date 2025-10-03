---
title: Deployment Guides
---


Platform-specific deployment guides for this Nix configuration.

---

## Overview

This section covers deploying your Nix configuration across different platforms:
- macOS (Darwin) - ✅ Current
- Linux (NixOS) - 📋 Planned
- Cloud (EC2/GCE) - 📋 Planned

---

## Documentation in This Section

### [macOS (Darwin)](./darwin.md) ⭐
**Fully implemented** - Complete macOS deployment guide.

**Covers:**
- Initial deployment on macOS
- System updates and management
- Generation management
- Rollback and recovery
- Multi-machine setup

**Status:** ✅ Production ready

---

### [Linux (NixOS)](./nixos.md)
**Planned** - NixOS deployment guide.

**Will cover:**
- NixOS installation
- Shared configuration with macOS
- Systemd service management
- Linux-specific optimizations

**Status:** 📋 Designed, not yet implemented

---

### [Cloud Deployment](./cloud.md)
**Planned** - AWS EC2 and GCP GCE deployment.

**Will cover:**
- Building cloud images
- AWS EC2 deployment
- GCP GCE deployment
- Terraform integration
- Auto-scaling

**Status:** 📋 Designed, not yet implemented

---

## Quick Start

### Deploy on macOS

```bash
# 1. Install Nix
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate

# 2. Clone config
git clone https://github.com/yourusername/Config.git ~/Config
cd ~/Config

# 3. First-time setup
sudo nix run nix-darwin -- switch --flake .#your-mac

# 4. Subsequent updates
darwin-rebuild switch --flake .#your-mac
```

See [Darwin Deployment](./darwin.md) for details.

### Deploy on NixOS (Planned)

```bash
# Boot NixOS installer
# Partition and mount disks

# Clone config
git clone https://github.com/yourusername/Config.git /mnt/etc/nixos
cd /mnt/etc/nixos

# Install
nixos-install --flake .#linux-workstation
```

See [NixOS Deployment](./nixos.md) for planned approach.

### Deploy to Cloud (Planned)

```bash
# Build AMI
nix build .#images.aws

# Deploy with Terraform
terraform apply

# Or deploy remotely
nixos-rebuild switch --flake .#ec2-instance \
  --target-host user@instance-ip
```

See [Cloud Deployment](./cloud.md) for planned approach.

---

## Platform Comparison

| Feature | macOS (Darwin) | Linux (NixOS) | Cloud |
|---------|----------------|---------------|-------|
| **Status** | ✅ Current | 📋 Planned | 📋 Planned |
| **Package Manager** | Nix + Homebrew | Nix only | Nix only |
| **Service Manager** | launchd | systemd | systemd |
| **Boot Manager** | macOS | GRUB/systemd-boot | Cloud boot |
| **User Management** | macOS native | Declarative | Declarative |
| **Remote Deploy** | ✅ Yes | ✅ Yes | ✅ Yes |

---

## Deployment Workflows

### macOS Workflow

```
1. Install Nix + Homebrew
   ↓
2. Clone configuration
   ↓
3. Customize for machine
   ↓
4. First-time activation (sudo)
   ↓
5. Subsequent updates (no sudo)
```

### NixOS Workflow (Planned)

```
1. Boot NixOS installer
   ↓
2. Partition disks
   ↓
3. Clone configuration
   ↓
4. nixos-install
   ↓
5. Reboot and manage
```

### Cloud Workflow (Planned)

```
1. Build cloud image
   ↓
2. Upload to AWS/GCP
   ↓
3. Launch instance
   ↓
4. Remote deployment
   ↓
5. Auto-scaling (optional)
```

---

## Common Tasks

### Update System

**macOS:**
```bash
nix flake update && darwin-rebuild switch --flake .#your-mac
```

**NixOS (planned):**
```bash
nix flake update && nixos-rebuild switch --flake .#hostname
```

### Rollback

**macOS:**
```bash
darwin-rebuild switch --rollback
```

**NixOS (planned):**
```bash
nixos-rebuild switch --rollback
```

### Add New Machine

**macOS:**
```bash
# Create host config
cp hosts/wikigen-mac.nix hosts/new-mac.nix

# Add to flake.nix
# Deploy on new machine
```

**NixOS (planned):**
```bash
# Create host config
# Add to flake.nix
# Install from ISO
```

---

## Multi-Platform Configuration

### Shared Configuration

```nix
# Common across all platforms
# nix/modules/common.nix
{
  environment.systemPackages = [ pkgs.git pkgs.vim ];

  programs.zsh.enable = true;
}
```

### Platform-Specific

```nix
# macOS only
# nix/modules/darwin-base.nix
{
  homebrew.enable = true;
  system.defaults.dock.autohide = true;
}

# Linux only
# nix/modules/linux-base.nix
{
  boot.loader.systemd-boot.enable = true;
  services.openssh.enable = true;
}
```

### Conditional Configuration

```nix
# Works on both platforms
{
  environment.systemPackages = with pkgs; [
    git
    vim
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.trash
  ] ++ lib.optionals stdenv.isLinux [
    systemd
  ];
}
```

---

## Troubleshooting

### macOS Issues

See [Darwin Deployment - Troubleshooting](./darwin.md#troubleshooting)

Common issues:
- Build failures
- Permission errors
- Homebrew conflicts

### NixOS Issues (Planned)

Common issues:
- Boot loader problems
- Network configuration
- Driver issues

### Cloud Issues (Planned)

Common issues:
- Image build failures
- Network connectivity
- Cloud-init problems

---

## Best Practices

### Version Control

```bash
# Always commit before major changes
git add .
git commit -m "Update configuration"

# Test build
darwin-rebuild build --flake .#hostname

# If good, apply
darwin-rebuild switch --flake .#hostname
```

### Testing

```bash
# Test in VM first
nix build .#nixosConfigurations.test-vm.config.system.build.vm
./result/bin/run-test-vm-vm

# Then deploy to production
```

### Backup

```bash
# Backup generations
darwin-rebuild --list-generations

# Keep configuration in git
git push origin main

# Export flake for offline use
nix flake archive
```

---

## Roadmap

### ✅ Phase 1: macOS (Complete)
- ✅ nix-darwin integration
- ✅ Home Manager support
- ✅ Homebrew integration
- ✅ Multi-machine support

### 📋 Phase 2: NixOS (Planned)
- [ ] linux-base module
- [ ] NixOS configurations
- [ ] VM testing
- [ ] Documentation

### 📋 Phase 3: Cloud (Planned)
- [ ] nixos-generators setup
- [ ] AWS AMI builds
- [ ] GCP image builds
- [ ] Terraform integration

### 🔮 Phase 4: Advanced (Future)
- [ ] Kubernetes manifests
- [ ] GitOps with Flux
- [ ] Automated CI/CD
- [ ] Multi-cloud support

---

## Related Documentation

### In This Section
- [Darwin Deployment](./darwin.md) - macOS guide
- [NixOS Deployment](./nixos.md) - Linux guide (planned)
- [Cloud Deployment](./cloud.md) - Cloud guide (planned)

### Other Sections
- [Getting Started](../../getting-started/) - Initial setup
- [Architecture](../../architecture/) - Design docs
- [Examples](../../examples/) - Practical examples

---

## External Resources

- [nix-darwin](https://github.com/LnL7/nix-darwin) - macOS support
- [NixOS](https://nixos.org/) - Linux distribution
- [nixos-generators](https://github.com/nix-community/nixos-generators) - Image builder
- [Terranix](https://terranix.org/) - Terraform in Nix

---

**Ready to deploy?** Start with [Darwin Deployment](./darwin.md)!
