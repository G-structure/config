---
title: Adding Packages
---


Learn how to add software packages to your Nix configuration.

---

## Table of Contents

- [Overview](#overview)
- [Finding Packages](#finding-packages)
- [System-Wide Packages](#system-wide-packages)
- [User Packages](#user-packages)
- [Homebrew Casks](#homebrew-casks)
- [Custom Packages](#custom-packages)
- [Package Versions](#package-versions)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

---

## Overview

Nix packages can be added at different levels:
- **System-level** - Available to all users
- **User-level** - Specific to your user account
- **Homebrew** - macOS GUI applications
- **Custom** - Packages you build yourself

---

## Finding Packages

### Search Online

**[NixOS Package Search](https://search.nixos.org/packages)**
- Browse all available packages
- View package details and options
- See available versions

### Search via CLI

```bash
# Basic search
nix search nixpkgs python

# Search with details
nix search nixpkgs --json python | jq '.[] | {name, description}'

# Search by attribute path
nix search nixpkgs#python3Packages.flask
```

### Check Package Info

```bash
# View package metadata
nix eval nixpkgs#python3.meta.description

# Show package version
nix eval nixpkgs#python3.version

# List package outputs
nix show-derivation nixpkgs#python3
```

---

## System-Wide Packages

Packages available to all users, installed system-wide.

### Add to Host Configuration

Edit your host file (`hosts/wikigen-mac.nix`):

```nix
{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Development tools
    python3
    nodejs_20
    go
    rustc
    cargo

    # Utilities
    htop
    ripgrep
    fd
    bat
    exa

    # Network tools
    curl
    wget
    httpie

    # System tools
    tree
    just
    direnv
  ];
}
```

### Apply Changes

```bash
cd ~/Config
darwin-rebuild switch --flake .#your-hostname
```

### Verify Installation

```bash
# Check version
python3 --version
node --version

# Check location
which python3
# /run/current-system/sw/bin/python3
```

---

## User Packages

Packages specific to your user account, managed by Home Manager.

### Add to User Configuration

Edit your user file (`home/users/yourname.nix`):

```nix
{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    # User-specific CLI tools
    fzf
    zoxide
    starship

    # Development
    gh              # GitHub CLI
    delta           # Git diff tool
    lazygit         # Git TUI

    # Productivity
    neovim
    tmux
    alacritty
  ];
}
```

### Apply Changes

```bash
darwin-rebuild switch --flake .#your-hostname
```

### Verify Installation

```bash
# User packages in profile
which fzf
# /Users/you/.nix-profile/bin/fzf
```

---

## Homebrew Casks

For macOS GUI applications not available in Nix.

### Add Cask

Edit `nix/modules/darwin/homebrew.nix`:

```nix
{ config, pkgs, ... }:
{
  homebrew = {
    enable = true;

    brews = [
      "colima"
      "docker"
      "docker-compose"
    ];

    casks = [
      # Hardware
      "ledger-live"

      # Development
      "visual-studio-code"
      "iterm2"
      "docker"

      # Productivity
      "slack"
      "notion"

      # Browsers
      "firefox"
      "google-chrome"
    ];
  };
}
```

### Apply Changes

```bash
darwin-rebuild switch --flake .#your-hostname
```

### Verify Installation

```bash
# List installed casks
brew list --cask

# Launch app
open -a "Visual Studio Code"
```

---

## Custom Packages

### Using buildNpmPackage

Create `nix/packages/my-npm-tool.nix`:

```nix
{ pkgs, lib }:

pkgs.buildNpmPackage {
  pname = "my-tool";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "user";
    repo = "my-tool";
    rev = "v1.0.0";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  npmDepsHash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";

  meta = with lib; {
    description = "My custom tool";
    homepage = "https://github.com/user/my-tool";
    license = licenses.mit;
  };
}
```

### Using buildGoModule

Create `nix/packages/my-go-tool.nix`:

```nix
{ pkgs, lib }:

pkgs.buildGoModule {
  pname = "my-go-tool";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "user";
    repo = "my-go-tool";
    rev = "v1.0.0";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  vendorHash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";

  meta = with lib; {
    description = "My Go tool";
    license = licenses.asl20;
  };
}
```

### Add to Flake Outputs

In `flake.nix`:

```nix
{
  outputs = { self, nixpkgs, ... }: {
    packages.aarch64-darwin = {
      my-npm-tool = import ./nix/packages/my-npm-tool.nix {
        inherit (nixpkgs.legacyPackages.aarch64-darwin) pkgs lib;
      };

      my-go-tool = import ./nix/packages/my-go-tool.nix {
        inherit (nixpkgs.legacyPackages.aarch64-darwin) pkgs lib;
      };
    };
  };
}
```

### Build and Install

```bash
# Build package
nix build .#my-npm-tool

# Install to profile
nix profile install .#my-npm-tool

# Or add to system/user packages
environment.systemPackages = [
  self.packages.${system}.my-npm-tool
];
```

See [Packaging Custom App](../../examples/packaging-custom-app.md) for complete example.

---

## Package Versions

### Specific Version from nixpkgs

```nix
{
  environment.systemPackages = with pkgs; [
    # Latest Python 3
    python3

    # Specific Python version
    python311
    python310

    # Latest Node.js LTS
    nodejs

    # Specific Node version
    nodejs_20
    nodejs_18
  ];
}
```

### Version from Different Channel

```nix
{
  # In flake.nix, add input
  inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  # Use in configuration
  environment.systemPackages = [
    inputs.nixpkgs-unstable.legacyPackages.${system}.package-name
  ];
}
```

### Pin Specific Commit

```nix
{
  # In flake.nix
  inputs.nixpkgs-pinned.url = "github:NixOS/nixpkgs/abc123commithas";

  # Use in config
  environment.systemPackages = [
    inputs.nixpkgs-pinned.legacyPackages.${system}.package-name
  ];
}
```

### Override Package Version

```nix
{
  environment.systemPackages = [
    (pkgs.python3.override {
      packageOverrides = self: super: {
        # Use specific Python version
      };
    })
  ];
}
```

See [Working with Overlays](./working-with-overlays.md) for advanced version control.

---

## Troubleshooting

### Package Not Found

```bash
# Update flake to get latest packages
nix flake update

# Search again
nix search nixpkgs package-name

# Check if it's in a different attribute
nix search nixpkgs --json package | jq 'keys'
```

### Build Fails

```bash
# Check build log
darwin-rebuild switch --flake .#hostname --show-trace

# Try building package alone
nix build nixpkgs#package-name --show-trace

# Check package is available for your system
nix eval nixpkgs#package-name.meta.platforms
```

### Conflicting Packages

```bash
# Find conflict
nix-store --query --requisites /run/current-system | grep package-name

# Remove from one location (system or user)
# Keep in only one place
```

### Hash Mismatch (Custom Packages)

```bash
# Use fake hash to get correct one
sha256 = lib.fakeSha256;

# Build will fail with correct hash
# Copy and paste the correct hash
```

---

## Best Practices

### Organization

```nix
# Group related packages
environment.systemPackages = with pkgs; [
  # Development
  git vim neovim

  # Cloud tools
  awscli2 kubectl terraform

  # Containers
  docker skopeo dive
];
```

### System vs User

**System packages** - Infrastructure, shared tools
```nix
# hosts/your-mac.nix
environment.systemPackages = [ git docker terraform ];
```

**User packages** - Personal preferences, CLI tools
```nix
# home/users/you.nix
home.packages = [ fzf bat exa starship ];
```

### Avoid Duplicates

```nix
# ❌ Bad: Package in both places
environment.systemPackages = [ htop ];
home.packages = [ htop ];  # Conflict!

# ✅ Good: Pick one location
environment.systemPackages = [ htop ];
```

### Use Profiles

For feature sets, create profiles:

```nix
# nix/profiles/python-dev.nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    python3
    python3Packages.pip
    python3Packages.virtualenv
    poetry
  ];
}
```

See [Creating Profiles](./creating-profiles.md).

---

## Next Steps

- **[Creating Modules](./creating-modules.md)** - Write custom modules
- **[Creating Profiles](./creating-profiles.md)** - Build feature bundles
- **[Working with Overlays](./working-with-overlays.md)** - Customize packages
- **[Packaging Custom App](../../examples/packaging-custom-app.md)** - Complete example

---

## Related Documentation

- [Nix Fundamentals](../../reference/nix-fundamentals.md) - Understanding Nix
- [Structure Guide](../../architecture/structure.md) - Config architecture
- [Troubleshooting](../../reference/troubleshooting.md) - Common issues

---

## External References

- [NixOS Packages](https://search.nixos.org/packages) - Package search
- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/) - Package documentation
- [Nix Language](https://nixos.org/manual/nix/stable/language/) - Language reference

---

**Ready to add packages?** Start with [Finding Packages](#finding-packages)!
