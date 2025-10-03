# First Steps After Installation

Learn how to customize and use your new Nix configuration.

---

## Table of Contents

- [Overview](#overview)
- [Understanding Your System](#understanding-your-system)
- [Adding Packages](#adding-packages)
- [Customizing Shell](#customizing-shell)
- [Working with Profiles](#working-with-profiles)
- [Managing Secrets](#managing-secrets)
- [Setting Up Hardware Security](#setting-up-hardware-security)
- [Daily Workflow](#daily-workflow)
- [Next Steps](#next-steps)

---

## Overview

You've successfully installed your Nix configuration! This guide covers:

- Understanding your system structure
- Adding and removing packages
- Customizing your environment
- Working with modules and profiles
- Daily usage patterns

---

## Understanding Your System

### Key Directories

```
~/Config/
├── flake.nix              # Main entry point
├── flake.lock             # Locked dependencies
├── nix/
│   ├── modules/           # System-level configuration
│   ├── profiles/          # Feature bundles
│   ├── packages/          # Custom packages
│   └── overlays/          # Package customizations
├── hosts/                 # Host-specific configs
│   └── your-mac.nix       # Your machine
└── home/                  # User configs
    └── users/
        └── yourname.nix   # Your user settings
```

### Configuration Layers

1. **Base Modules** (`nix/modules/`)
   - `common.nix` - Shared across all platforms
   - `darwin-base.nix` - macOS-specific settings

2. **Feature Profiles** (`nix/profiles/`)
   - `cloud-cli.nix` - AWS, GCP, Kubernetes tools
   - `developer.nix` - Development utilities
   - `hardware-security.nix` - Ledger, GPG, SSH

3. **Host Config** (`hosts/your-mac.nix`)
   - Machine-specific settings
   - User definitions
   - System packages

4. **User Config** (`home/users/yourname.nix`)
   - Shell configuration
   - Git settings
   - User packages

---

## Adding Packages

### System-Wide Packages

Edit your host configuration (`hosts/your-mac.nix`):

```nix
{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Development
    python3
    nodejs
    go

    # Utilities
    htop
    ripgrep
    fd

    # Your additions here
  ];
}
```

### User Packages

Edit your user configuration (`home/users/yourname.nix`):

```nix
{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    # User-specific tools
    fzf
    bat
    exa

    # Your additions here
  ];
}
```

### Apply Changes

```bash
cd ~/Config
darwin-rebuild switch --flake .#your-hostname
```

### Finding Packages

```bash
# Search nixpkgs
nix search nixpkgs python

# Search with description
nix search nixpkgs --json python | jq '.[].description'

# Browse online
# https://search.nixos.org/packages
```

---

## Customizing Shell

### Zsh Configuration

Your shell is configured in `home/users/yourname.nix`:

```nix
programs.zsh = {
  enable = true;
  enableCompletion = true;

  # Add aliases
  shellAliases = {
    ll = "ls -la";
    g = "git";
    d = "docker";
  };

  # Add init content
  initContent = ''
    # Custom prompt
    export PS1="%F{blue}%n@%m%f %F{yellow}%~%f %# "

    # Custom functions
    mkcd() { mkdir -p "$1" && cd "$1"; }
  '';
};
```

### Shell Aliases

```nix
programs.zsh.shellAliases = {
  # Nix shortcuts
  nb = "darwin-rebuild switch --flake ~/Config";
  nu = "nix flake update ~/Config";

  # Git shortcuts
  gs = "git status";
  gc = "git commit";
  gp = "git push";

  # Docker/Colima
  dc = "docker compose";
  dps = "docker ps";
};
```

### Environment Variables

```nix
home.sessionVariables = {
  EDITOR = "vim";
  BROWSER = "open";
  LANG = "en_US.UTF-8";

  # Custom paths
  MY_PROJECT = "$HOME/Projects";
};
```

---

## Working with Profiles

### Enable a Profile

Profiles are composable feature bundles. Add to your host config:

```nix
# In hosts/your-mac.nix or flake.nix imports
{
  imports = [
    ./nix/profiles/cloud-cli.nix      # ✅ Already enabled
    ./nix/profiles/developer.nix      # ✅ Already enabled
    ./nix/profiles/hardware-security.nix  # Optional
  ];
}
```

### Create Custom Profile

Create `nix/profiles/my-profile.nix`:

```nix
{ config, pkgs, ... }:
{
  # System packages
  environment.systemPackages = with pkgs; [
    package1
    package2
  ];

  # Home-manager config (if in user context)
  home.packages = with pkgs; [
    user-package1
  ];

  # System settings
  programs.myapp.enable = true;
}
```

Add to your host:

```nix
imports = [
  ./nix/profiles/my-profile.nix
];
```

### Available Profiles

- **cloud-cli** - AWS, GCP, Kubernetes, Terraform
- **developer** - jq, yq, tree, just
- **hardware-security** - Ledger, GPG, SSH agents

---

## Managing Secrets

### Set Up SOPS

1. **Install Ledger (optional)** - See [Ledger Setup](../guides/hardware-security/ledger-setup.md)

2. **Configure SOPS module:**
   ```nix
   # In flake.nix imports
   imports = [
     ./nix/modules/secrets/sops.nix
   ];
   ```

3. **Create secret file:**
   ```bash
   # Set GPG home
   export GNUPGHOME=~/.gnupg-ledger

   # Create encrypted secret
   sops nix/secrets/secrets.yaml
   ```

4. **Use secret in config:**
   ```nix
   # Declare secret
   sops.secrets."myapp/api-key" = {};

   # Reference in config
   environment.variables = {
     API_KEY_FILE = config.sops.secrets."myapp/api-key".path;
   };
   ```

See [SOPS Guide](../guides/secrets-management/sops.md) for details.

---

## Setting Up Hardware Security

### Ledger Configuration

For GPG signing and SSH authentication with Ledger:

1. **Follow setup guide:** [Ledger Setup](../guides/hardware-security/ledger-setup.md)

2. **Enable in your user config:**
   ```nix
   # In home/users/yourname.nix
   imports = [
     ../../nix/profiles/hardware-security.nix
   ];
   ```

3. **Rebuild:**
   ```bash
   darwin-rebuild switch --flake .#your-hostname
   ```

### Features Included

- ✅ GPG signing for git commits
- ✅ SSH authentication with hardware key
- ✅ SOPS secrets encrypted with Ledger GPG
- ✅ Physical confirmation for all operations

---

## Daily Workflow

### Making Changes

1. **Edit configuration files**
   ```bash
   cd ~/Config
   nano hosts/your-mac.nix  # or home/users/yourname.nix
   ```

2. **Test build (dry run)**
   ```bash
   darwin-rebuild build --flake .#your-hostname
   ```

3. **Apply changes**
   ```bash
   darwin-rebuild switch --flake .#your-hostname
   ```

4. **Commit changes**
   ```bash
   git add .
   git commit -m "Add package X"
   git push
   ```

### Updating Dependencies

```bash
# Update all flake inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs

# Apply updates
darwin-rebuild switch --flake .#your-hostname
```

### Cleaning Up

```bash
# Remove old generations (30+ days)
nix-collect-garbage --delete-older-than 30d

# Remove all old generations
nix-collect-garbage -d

# Optimize store (deduplicate)
nix-store --optimise
```

### Viewing System State

```bash
# List generations
darwin-rebuild list-generations

# Show current generation
ls -l /run/current-system

# View generation diff
darwin-rebuild --list-generations | head -2 | \
  xargs -n1 nix store diff-closures
```

---

## Common Tasks

### Add Homebrew Cask

```nix
# In nix/modules/darwin/homebrew.nix
homebrew.casks = [
  "ledger-live"
  "visual-studio-code"  # Add here
];
```

### Change System Settings

```nix
# In nix/modules/darwin-base.nix
system.defaults = {
  dock = {
    autohide = true;
    orientation = "bottom";
    show-recents = false;
  };

  NSGlobalDomain = {
    AppleShowAllExtensions = true;
    InitialKeyRepeat = 15;
    KeyRepeat = 2;
  };
};
```

### Add Overlay

Create `nix/overlays/my-overlay.nix`:

```nix
final: prev: {
  my-package = prev.my-package.overrideAttrs (old: {
    version = "1.2.3";
    # ... customizations
  });
}
```

Reference in flake.nix:

```nix
nixpkgs.overlays = [
  (import ./nix/overlays/my-overlay.nix)
];
```

---

## Troubleshooting

### Build Errors

```bash
# Check for syntax errors
nix flake check

# Verbose build output
darwin-rebuild switch --flake .#your-hostname --show-trace

# Check recent changes
git diff HEAD~1
```

### Package Conflicts

```bash
# Find conflicting packages
nix-store --query --requisites /run/current-system | grep package-name

# Remove from both user and system configs
```

### Rollback Changes

```bash
# List generations
darwin-rebuild list-generations

# Rollback to previous
darwin-rebuild switch --rollback

# Switch to specific generation
darwin-rebuild switch --switch-generation 42
```

---

## Next Steps

### Learn More

1. **[Structure Guide](../architecture/structure.md)** - Deep dive into architecture
2. **[Development Guides](../guides/development/)** - Extend your config
3. **[Nix Fundamentals](../reference/nix-fundamentals.md)** - Understand Nix internals

### Advanced Topics

4. **[Creating Modules](../guides/development/creating-modules.md)** - Write custom modules
5. **[Working with Overlays](../guides/development/working-with-overlays.md)** - Customize packages
6. **[Cloud Deployment](../guides/deployment/cloud.md)** - Deploy to EC2/GCE

### Examples

7. **[Adding New Host](../examples/adding-new-host.md)** - Set up another machine
8. **[Custom Profile](../examples/creating-custom-profile.md)** - Build feature bundles
9. **[Multi-User Setup](../examples/multi-user-setup.md)** - Configure for teams

---

## Quick Reference

### Essential Commands

```bash
# Apply changes
darwin-rebuild switch --flake .#hostname

# Test build
darwin-rebuild build --flake .#hostname

# Update flake
nix flake update

# Clean up
nix-collect-garbage -d

# Search packages
nix search nixpkgs package-name

# View package info
nix eval nixpkgs#package-name.meta.description
```

### File Locations

```
~/Config/hosts/your-mac.nix     # System config
~/Config/home/users/you.nix     # User config
~/.nix-profile                   # User profile
/run/current-system              # Active system
```

---

**Happy configuring! 🚀**

See [CLI Commands Reference](../reference/cli-commands.md) for more commands.
