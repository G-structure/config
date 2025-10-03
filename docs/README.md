# Documentation Index

Welcome to the comprehensive documentation for this modular Nix configuration. This guide covers macOS (Darwin), Linux (NixOS), and cloud deployment (AWS EC2, GCP GCE).

---

## Quick Navigation

**New to this config?** Start with [Quickstart](getting-started/quickstart.md)

**Want to extend it?** See [Development Guides](guides/development/)

**Having issues?** Check [Troubleshooting](reference/troubleshooting.md)

**Understanding the architecture?** Read [Structure Guide](architecture/structure.md)

---

## Documentation Structure

### 🚀 [Getting Started](getting-started/)

New to this Nix configuration? Start here.

- **[Quickstart](getting-started/quickstart.md)** - Get up and running in 5 minutes
- **[Installation](getting-started/installation.md)** - Detailed installation guide
- **[First Steps](getting-started/first-steps.md)** - What to do after installation

### 🏗️ [Architecture](architecture/)

Understand how this configuration is organized and designed.

- **[Design Philosophy](architecture/design.md)** - Future roadmap and architectural decisions
- **[Structure Guide](architecture/structure.md)** - Modular organization explained
- **[Nix Concepts](architecture/nix-concepts.md)** - Nix fundamentals, store hashes, derivations

### 📚 [Guides](guides/)

Step-by-step guides for specific tasks and features.

#### Hardware Security
- **[Overview](guides/hardware-security/)** - Hardware wallet integration
- **[Ledger Deep Dive](guides/hardware-security/ledger-overview.md)** - Comprehensive hardware security guide
- **[Ledger Setup](guides/hardware-security/ledger-setup.md)** - Step-by-step Ledger configuration
- **[GPG Signing](guides/hardware-security/gpg-signing.md)** - GPG and git commit signing
- **[SSH Authentication](guides/hardware-security/ssh-authentication.md)** - SSH with hardware wallet

#### Secrets Management
- **[Overview](guides/secrets-management/)** - Secure secrets handling
- **[SOPS](guides/secrets-management/sops.md)** - Complete SOPS guide with Ledger
- **[age Encryption](guides/secrets-management/age.md)** - Modern encryption (future)

#### Development
- **[Overview](guides/development/)** - Extending and customizing the config
- **[Adding Packages](guides/development/adding-packages.md)** - Package management
- **[Creating Modules](guides/development/creating-modules.md)** - Writing new modules
- **[Creating Profiles](guides/development/creating-profiles.md)** - Building feature profiles
- **[Working with Overlays](guides/development/working-with-overlays.md)** - Package customization
- **[Testing Builds](guides/development/testing-builds.md)** - Dry runs and CI patterns

#### Deployment
- **[Overview](guides/deployment/)** - Deploying to different platforms
- **[macOS (Darwin)](guides/deployment/darwin.md)** - macOS deployment guide
- **[Linux (NixOS)](guides/deployment/nixos.md)** - NixOS deployment (planned)
- **[Cloud (EC2/GCE)](guides/deployment/cloud.md)** - Cloud deployment (planned)

### 📖 [Reference](reference/)

Technical references and quick lookups.

- **[Nix Fundamentals](reference/nix-fundamentals.md)** - Hashes, derivations, store explained
- **[Modules Reference](reference/modules-reference.md)** - All modules documented
- **[Profiles Reference](reference/profiles-reference.md)** - All profiles documented
- **[CLI Commands](reference/cli-commands.md)** - Common command reference
- **[Troubleshooting](reference/troubleshooting.md)** - Common issues and solutions

### 💡 [Examples](examples/)

Practical examples for common tasks.

- **[Adding a New Host](examples/adding-new-host.md)** - Step-by-step host setup
- **[Creating a Custom Profile](examples/creating-custom-profile.md)** - Profile creation walkthrough
- **[Packaging a Custom App](examples/packaging-custom-app.md)** - Custom package example
- **[Multi-User Setup](examples/multi-user-setup.md)** - Multiple users/machines

---

## Common Tasks

### I want to...

**Get started quickly**
→ [Quickstart Guide](getting-started/quickstart.md)

**Install on a new macOS machine**
→ [macOS Deployment](guides/deployment/darwin.md)

**Set up my Ledger hardware wallet**
→ [Ledger Setup Guide](guides/hardware-security/ledger-setup.md)

**Manage secrets securely**
→ [SOPS Guide](guides/secrets-management/sops.md)

**Add a new package to my system**
→ [Adding Packages](guides/development/adding-packages.md)

**Create a reusable feature bundle**
→ [Creating Profiles](guides/development/creating-profiles.md)

**Add a new machine to this config**
→ [Adding a New Host](examples/adding-new-host.md)

**Understand the module system**
→ [Structure Guide](architecture/structure.md)

**Sign git commits with my Ledger**
→ [GPG Signing Guide](guides/hardware-security/gpg-signing.md)

**Fix a build error**
→ [Troubleshooting](reference/troubleshooting.md)

**Deploy to the cloud**
→ [Cloud Deployment](guides/deployment/cloud.md)

---

## Status Legend

Throughout the documentation, you'll see status indicators:

- **✅ Current** - Implemented and tested
- **🚧 In Progress** - Partially implemented
- **📋 Planned** - Designed but not yet implemented
- **🔮 Future** - Ideas for future expansion

---

## Documentation Standards

All documentation in this repository follows these conventions:

### Structure
- **Table of contents** for docs > 100 lines
- **Section separators** (`---`) between major sections
- **References section** with external links
- **Related docs** footer with internal links

### Formatting
- **Bold** for emphasis and UI elements
- *Italic* for file paths and technical terms
- `code` for commands, file names, and code snippets
- Links as `[Text](path.md)` for internal, `[Text](url)` for external

### Code Examples
- Include comments explaining what code does
- Show expected output where helpful
- Use real examples from this config when possible

---

## Contributing

When adding or updating documentation:

1. **Follow the structure** - Place docs in the appropriate folder
2. **Add wiki links** - Link to related documentation
3. **Update this index** - Add new docs to the relevant section
4. **Keep it current** - Mark planned features clearly
5. **Test examples** - Verify code examples actually work

---

## External Resources

### Nix Ecosystem
- [Nix Manual](https://nixos.org/manual/nix/stable/) - Core Nix documentation
- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/) - Package repository
- [NixOS Manual](https://nixos.org/manual/nixos/stable/) - Linux distribution
- [nix-darwin](https://daiderd.com/nix-darwin/manual/) - macOS support
- [Home Manager](https://nix-community.github.io/home-manager/) - User environment

### Community
- [NixOS Discourse](https://discourse.nixos.org/) - Community forum
- [NixOS Wiki](https://nixos.wiki/) - Community documentation
- [Zero to Nix](https://zero-to-nix.com/) - Beginner guide

### Tools Used
- [flake-parts](https://github.com/hercules-ci/flake-parts) - Flake organization
- [SOPS](https://github.com/getsops/sops) - Secrets management
- [trezor-agent](https://github.com/romanz/trezor-agent) - Hardware wallet agent

---

## Quick Reference

### Important Paths

```
Config/
├── flake.nix                   # Main configuration entry point
├── nix/
│   ├── modules/                # Base system modules
│   ├── profiles/               # Feature profiles
│   ├── overlays/               # Package overlays
│   ├── packages/               # Custom packages
│   └── secrets/                # Encrypted secrets
├── hosts/                      # Host-specific configurations
├── home/                       # Home-manager user configs
└── docs/                       # This documentation
```

### Key Commands

```bash
# Apply configuration changes
darwin-rebuild switch --flake .#wikigen-mac

# Build packages
nix build .#ai-clis

# Enter dev shell
nix develop

# Update dependencies
nix flake update

# Check configuration
nix flake check
```

---

**[Return to Main README](../README.md)**
