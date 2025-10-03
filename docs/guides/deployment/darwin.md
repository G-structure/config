# macOS (Darwin) Deployment

Complete guide to deploying this Nix configuration on macOS.

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Initial Deployment](#initial-deployment)
- [System Updates](#system-updates)
- [Managing Generations](#managing-generations)
- [Rollback and Recovery](#rollback-and-recovery)
- [Multi-Machine Setup](#multi-machine-setup)
- [Troubleshooting](#troubleshooting)

---

## Overview

This guide covers deploying and managing your Nix configuration on macOS using nix-darwin.

**Status:** ✅ Fully implemented and tested

---

## Prerequisites

- macOS 11 (Big Sur) or later
- Apple Silicon (M1/M2/M3) or Intel
- Administrator access
- 10 GB free disk space

See [Installation Guide](../../getting-started/installation.md) for initial setup.

---

## Initial Deployment

### First-Time Setup

```bash
# 1. Install Nix
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate

# 2. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. Clone config
git clone https://github.com/yourusername/Config.git ~/Config
cd ~/Config

# 4. Customize for your machine
cp hosts/wikigen-mac.nix hosts/your-mac.nix
nano hosts/your-mac.nix  # Update username

# 5. First activation (requires sudo)
sudo nix run nix-darwin -- switch --flake .#your-mac
```

### Verify Deployment

```bash
# Check system generation
darwin-rebuild --list-generations

# View current system
ls -l /run/current-system

# Test commands
which darwin-rebuild
nix --version
```

---

## System Updates

### Daily Update Workflow

```bash
cd ~/Config

# 1. Update flake inputs
nix flake update

# 2. Test build
darwin-rebuild build --flake .#your-mac

# 3. Check changes
nix store diff-closures /run/current-system ./result

# 4. Apply if good
darwin-rebuild switch --flake .#your-mac
```

### Selective Updates

```bash
# Update specific input
nix flake lock --update-input nixpkgs

# Update darwin only
nix flake lock --update-input nix-darwin

# Update home-manager only
nix flake lock --update-input home-manager
```

### Update and Rebuild

```bash
# One command: update + rebuild
nix flake update && darwin-rebuild switch --flake .#your-mac
```

---

## Managing Generations

### List Generations

```bash
# Show all generations
darwin-rebuild --list-generations

# Example output:
#   1   2024-01-15 10:30:45
#   2   2024-01-20 14:22:10
#   3   2024-01-25 09:15:33   (current)
```

### Switch Generations

```bash
# Switch to specific generation
darwin-rebuild switch --switch-generation 2

# Rollback to previous
darwin-rebuild switch --rollback
```

### Delete Old Generations

```bash
# Delete generations older than 30 days
nix-collect-garbage --delete-older-than 30d

# Delete all old generations
nix-collect-garbage -d

# Keep last N generations
darwin-rebuild --list-generations | head -n -3 | awk '{print $1}' | xargs darwin-rebuild delete-generations
```

---

## Rollback and Recovery

### Quick Rollback

```bash
# Rollback to previous generation
darwin-rebuild switch --rollback
```

### Manual Recovery

```bash
# If system is broken, boot into recovery

# 1. List available generations
ls -l /nix/var/nix/profiles/system-*-link

# 2. Activate specific generation
/nix/var/nix/profiles/system-2-link/activate

# 3. Or rollback
/nix/var/nix/profiles/system/bin/darwin-rebuild switch --rollback
```

### Backup Configuration

```bash
# Backup current generation
cp -r /run/current-system ~/system-backup-$(date +%Y%m%d)

# Export configuration
nix flake archive --to file://~/config-backup.tar.gz
```

---

## Multi-Machine Setup

### Add New macOS Machine

1. **Create host config**
   ```bash
   cp hosts/wikigen-mac.nix hosts/new-mac.nix
   ```

2. **Update configuration**
   ```nix
   # hosts/new-mac.nix
   {
     system.primaryUser = "newuser";
     users.users.newuser = {
       name = "newuser";
       home = "/Users/newuser";
     };
   }
   ```

3. **Add to flake.nix**
   ```nix
   darwinConfigurations.new-mac = darwin.lib.darwinSystem {
     system = "aarch64-darwin";  # or x86_64-darwin
     modules = [
       ./nix/modules/common.nix
       ./nix/modules/darwin-base.nix
       ./hosts/new-mac.nix
       # ... home-manager config
     ];
   };
   ```

4. **Deploy**
   ```bash
   # On new machine
   git clone https://github.com/yourusername/Config.git ~/Config
   cd ~/Config
   sudo nix run nix-darwin -- switch --flake .#new-mac
   ```

### Shared Configuration

```nix
# Share profiles across machines
# In both host configs:
imports = [
  ../nix/profiles/developer.nix
  ../nix/profiles/cloud-cli.nix
];

# Machine-specific differences
environment.systemPackages = lib.optionals
  (config.networking.hostName == "work-mac")
  [ pkgs.work-specific-tool ];
```

---

## Troubleshooting

### Build Fails

```bash
# Verbose output
darwin-rebuild switch --flake .#your-mac --show-trace

# Check for errors
nix flake check

# Test specific package
nix build .#package-name
```

### Activation Fails

```bash
# Check activation script
cat /run/current-system/activate

# Run manually
/run/current-system/activate

# Check logs
tail -f /var/log/system.log
```

### Rollback Broken System

```bash
# If current generation is broken
darwin-rebuild switch --rollback

# If darwin-rebuild is broken
/nix/var/nix/profiles/system/bin/darwin-rebuild switch --rollback

# If everything is broken, boot to recovery and:
# 1. Activate previous generation manually
/nix/var/nix/profiles/system-1-link/activate
```

### Permission Issues

```bash
# Fix Nix store permissions
sudo chown -R root:nixbld /nix

# Fix user permissions
sudo chown -R $USER ~/.nix-profile

# Fix flake.lock
sudo chown $USER:staff flake.lock
```

---

## Advanced Topics

### Remote Deployment

```bash
# Build on local machine, deploy to remote
darwin-rebuild switch --flake .#remote-mac \
  --target-host user@remote-mac.local \
  --use-remote-sudo
```

### Binary Cache Setup

```bash
# Use custom binary cache
darwin-rebuild switch --flake .#your-mac \
  --option substituters "https://cache.nixos.org https://your-cache.com" \
  --option trusted-public-keys "your-cache-key"
```

### Declarative User Management

```nix
# Full user management in Nix
users.users.developer = {
  uid = 501;
  home = "/Users/developer";
  shell = pkgs.zsh;
  description = "Developer Account";
};
```

---

## Daily Commands

```bash
# Update and rebuild
nix flake update && darwin-rebuild switch --flake .#your-mac

# Test before applying
darwin-rebuild build --flake .#your-mac
nix store diff-closures /run/current-system ./result

# Garbage collect
nix-collect-garbage --delete-older-than 30d

# List generations
darwin-rebuild --list-generations

# Rollback
darwin-rebuild switch --rollback
```

---

## Next Steps

- **[NixOS Deployment](./nixos.md)** - Linux deployment (planned)
- **[Cloud Deployment](./cloud.md)** - EC2/GCE deployment (planned)
- **[Multi-Machine Example](../../examples/adding-new-host.md)** - Add another host
- **[Troubleshooting](../../reference/troubleshooting.md)** - Fix issues

---

## Related Documentation

- [Installation Guide](../../getting-started/installation.md) - Initial setup
- [First Steps](../../getting-started/first-steps.md) - Post-install guide
- [Structure Guide](../../architecture/structure.md) - Config architecture

---

## External References

- [nix-darwin Manual](https://daiderd.com/nix-darwin/manual/) - Official docs
- [Nix Manual](https://nixos.org/manual/nix/stable/) - Nix documentation
- [Determinate Nix](https://zero-to-nix.com/) - Installer docs

---

**Ready to deploy?** Start with [Initial Deployment](#initial-deployment)!
