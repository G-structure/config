---
title: Quickstart Guide
---


Get your Nix configuration up and running in 5 minutes.

---

## Prerequisites

- macOS system (for Darwin setup)
- Terminal access
- 10 GB free disk space

---

## Step 1: Install Nix (2 minutes)

Use the Determinate Systems installer for the best experience:

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
```

**Why Determinate Nix?**
- Includes flakes by default
- Better macOS support
- No daemon management needed

---

## Step 2: Install Homebrew (1 minute)

Required for macOS-specific GUI apps:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

---

## Step 3: Clone This Config (1 minute)

```bash
cd ~
git clone https://github.com/yourusername/Config.git
cd Config
```

---

## Step 4: Apply Configuration (1 minute)

### First-Time Setup

```bash
# Backup existing shell config
mv ~/.zshrc ~/.zshrc.backup 2>/dev/null || true

# Apply Nix configuration
sudo nix run nix-darwin -- switch --flake .#wikigen-mac
```

### Subsequent Updates

After the first setup, use:

```bash
darwin-rebuild switch --flake .#wikigen-mac
```

---

## What You Just Got

✅ **System Packages**
- Nix development tools (git, vim, curl, wget)
- Cloud CLIs (AWS, GCP, Kubernetes)
- Container tools (Colima, Docker, Skopeo)
- AI tools (Claude Code, MCP Inspector)

✅ **Hardware Security** (optional setup)
- Ledger wallet support
- GPG signing
- SSH authentication
- SOPS secrets management

✅ **Shell Configuration**
- Zsh with completions
- Colima auto-start
- GPG/SSH agent integration

---

## Quick Verification

```bash
# Check Nix installation
nix --version

# Check installed packages
which aws kubectl docker

# View system configuration
darwin-rebuild --help
```

---

## Next Steps

1. **Customize for your machine** - Edit `hosts/wikigen-mac.nix` with your username
2. **Set up Ledger** - See [Ledger Setup Guide](../guides/hardware-security/ledger-setup.md)
3. **Add secrets** - See [SOPS Guide](../guides/secrets-management/sops.md)
4. **Explore structure** - Read [Architecture Guide](../architecture/structure.md)

---

## Troubleshooting

### "Command not found" after install

Restart your shell:
```bash
exec zsh
```

### Homebrew not found

Add to PATH:
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### Build fails with version mismatch

Ensure you're using the latest flake lock:
```bash
nix flake update
darwin-rebuild switch --flake .#wikigen-mac
```

---

## Common First Tasks

**Add a package:**
```nix
# In hosts/wikigen-mac.nix
environment.systemPackages = with pkgs; [
  # ... existing packages
  htop  # Add your package here
];
```

**Rebuild:**
```bash
darwin-rebuild switch --flake .#wikigen-mac
```

---

## Related Documentation

- [Detailed Installation Guide](./installation.md) - Step-by-step setup
- [First Steps](./first-steps.md) - What to do after installation
- [Structure Guide](../architecture/structure.md) - Understanding the config

---

## Get Help

- [Troubleshooting Guide](../reference/troubleshooting.md) - Common issues
- [NixOS Discourse](https://discourse.nixos.org/) - Community forum
- [GitHub Issues](https://github.com/yourusername/Config/issues) - Report bugs

---

**You're all set! 🚀**

Continue with [First Steps](./first-steps.md) to learn how to customize your setup.
