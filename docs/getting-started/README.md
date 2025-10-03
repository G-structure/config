---
title: Getting Started
---


Welcome to your Nix configuration! This section will get you up and running quickly.

---

## Quick Navigation

**Brand new to this config?** → [Quickstart (5 minutes)](./quickstart.md)

**Want detailed setup?** → [Installation Guide](./installation.md)

**Already installed?** → [First Steps](./first-steps.md)

---

## Documentation in This Section

### [Quickstart](./quickstart.md)
Get up and running in 5 minutes with essential commands and quick setup.

**Perfect for:**
- First-time users who want to get started fast
- Experienced Nix users who just need the basics
- Quick reference for installation steps

### [Installation Guide](./installation.md)
Comprehensive installation instructions with detailed explanations.

**Covers:**
- Prerequisites and system requirements
- Step-by-step Nix installation
- Customizing for your machine
- Troubleshooting common issues
- Verification steps

### [First Steps](./first-steps.md)
Learn how to use and customize your newly installed system.

**Learn to:**
- Add and remove packages
- Customize your shell
- Work with profiles and modules
- Manage secrets with SOPS
- Daily workflow patterns

---

## Installation Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Installation Flow                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Install Nix                                             │
│     ↓                                                       │
│  2. Install Homebrew (macOS GUI apps)                       │
│     ↓                                                       │
│  3. Clone this configuration                                │
│     ↓                                                       │
│  4. Customize for your machine                              │
│     ↓                                                       │
│  5. Apply configuration                                     │
│     ↓                                                       │
│  6. Enjoy your reproducible system!                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## What You Get

After installation, you'll have:

### System Configuration
- ✅ Nix package manager with flakes
- ✅ nix-darwin for system management
- ✅ Home Manager for user environment
- ✅ Homebrew for macOS GUI apps

### Installed Tools
- ✅ Development utilities (git, vim, curl, jq, tree)
- ✅ Cloud CLIs (AWS, GCP, Kubernetes, Terraform)
- ✅ Container tools (Colima, Docker, Skopeo, Dive)
- ✅ AI tools (Claude Code, MCP Inspector)

### Optional Features
- ⭐ Ledger hardware wallet support
- ⭐ GPG signing with hardware key
- ⭐ SSH authentication with Ledger
- ⭐ SOPS secrets management

---

## Prerequisites

**Before you begin, you need:**

- macOS 11 (Big Sur) or later
- 10 GB free disk space
- Administrator access (sudo)
- Terminal app
- Optional: Ledger Nano S for hardware security

---

## Quick Start Commands

```bash
# 1. Install Nix (Determinate Systems)
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate

# 2. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. Clone config
git clone https://github.com/yourusername/Config.git ~/Config
cd ~/Config

# 4. First-time setup
sudo nix run nix-darwin -- switch --flake .#wikigen-mac

# 5. Subsequent updates
darwin-rebuild switch --flake .#wikigen-mac
```

See [Quickstart](./quickstart.md) for details.

---

## After Installation

### Essential Next Steps

1. **[First Steps](./first-steps.md)** - Learn daily workflow
2. **[Ledger Setup](../guides/hardware-security/ledger-setup.md)** - Configure hardware wallet
3. **[SOPS Setup](../guides/secrets-management/sops.md)** - Set up secrets

### Learn the System

4. **[Structure Guide](../architecture/structure.md)** - Understand the architecture
5. **[Design Philosophy](../architecture/design.md)** - Learn design decisions
6. **[Nix Fundamentals](../reference/nix-fundamentals.md)** - Deep dive into Nix

### Customize Further

7. **[Adding Packages](../guides/development/adding-packages.md)** - Install software
8. **[Creating Modules](../guides/development/creating-modules.md)** - Write modules
9. **[Creating Profiles](../guides/development/creating-profiles.md)** - Build profiles

---

## Common Questions

### Which installer should I use?

**Recommended:** Determinate Systems installer
- Flakes enabled by default
- Better macOS support
- Optimized for modern Nix

**Alternative:** Official installer
- More conservative
- Requires manual flake configuration

See [Installation Guide](./installation.md) for details.

### Do I need Homebrew?

**Yes**, for macOS-specific GUI applications:
- Ledger Live
- Other cask-only apps

Nix handles all CLI tools and libraries.

### Can I use this on Linux?

**Yes!** This config supports:
- ✅ macOS (Darwin) - Current focus
- 🚧 Linux (NixOS) - Planned
- 🚧 Cloud (EC2/GCE) - Planned

See [Design Doc](../architecture/design.md) for roadmap.

### How do I update my system?

```bash
# Update dependencies
nix flake update

# Apply changes
darwin-rebuild switch --flake .#your-hostname
```

See [First Steps](./first-steps.md) for workflow details.

---

## Troubleshooting

Having issues? Check these resources:

1. **[Troubleshooting Guide](../reference/troubleshooting.md)** - Common problems
2. **[Installation Guide](./installation.md#troubleshooting)** - Install-specific issues
3. **[CLI Commands](../reference/cli-commands.md)** - Command reference
4. **[NixOS Discourse](https://discourse.nixos.org/)** - Community help

---

## Related Documentation

### In This Section
- [Quickstart](./quickstart.md) - 5-minute setup
- [Installation](./installation.md) - Detailed install guide
- [First Steps](./first-steps.md) - Post-install guide

### Next Sections
- [Architecture](../architecture/) - Understanding the design
- [Guides](../guides/) - How-to guides for specific tasks
- [Reference](../reference/) - Technical references
- [Examples](../examples/) - Practical examples

---

## Get Help

- **Documentation:** [docs/README.md](../README.md)
- **Issues:** Report bugs on GitHub
- **Community:** [NixOS Discourse](https://discourse.nixos.org/)
- **Wiki:** [NixOS Wiki](https://nixos.wiki/)

---

**Ready to begin?** Start with the [Quickstart Guide](./quickstart.md)!
