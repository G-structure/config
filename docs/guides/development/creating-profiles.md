---
title: Creating Profiles
---


Learn how to build reusable feature profiles for your Nix configuration.

---

## Table of Contents

- [Overview](#overview)
- [What is a Profile?](#what-is-a-profile)
- [Profile Structure](#profile-structure)
- [Creating a Simple Profile](#creating-a-simple-profile)
- [Advanced Profiles](#advanced-profiles)
- [Using Profiles](#using-profiles)
- [Best Practices](#best-practices)
- [Examples](#examples)

---

## Overview

**Profiles** are composable feature bundles that group related configuration. They:
- Bundle packages, settings, and services
- Enable/disable entire feature sets at once
- Can be shared across machines
- Promote configuration reuse

---

## What is a Profile?

### Profile vs Module

**Module** - Building block with options
```nix
# Defines HOW something works
options.myapp.enable = ...;
config = lib.mkIf config.myapp.enable { ... };
```

**Profile** - Pre-configured feature bundle
```nix
# Defines WHAT you get
environment.systemPackages = [ pkgs.tool1 pkgs.tool2 ];
programs.tool1.enable = true;
```

### When to Use Profiles

Use profiles for:
- ✅ Feature sets (cloud tools, development tools)
- ✅ Role-based configs (developer, ops, security)
- ✅ Platform-specific bundles (macOS apps, Linux tools)
- ✅ Shareable configurations

Use modules for:
- ✅ Configurable services
- ✅ System-wide settings
- ✅ Reusable abstractions

---

## Profile Structure

### Basic Profile Template

```nix
{ config, pkgs, lib, ... }:
{
  # System packages
  environment.systemPackages = with pkgs; [
    package1
    package2
  ];

  # Program configuration
  programs.tool.enable = true;

  # Services
  services.myservice.enable = true;

  # Environment variables
  environment.variables = {
    VAR = "value";
  };
}
```

### File Organization

```
nix/profiles/
├── cloud-cli.nix          # Cloud provider tools
├── developer.nix          # Development utilities
├── hardware-security.nix  # Ledger, GPG, SSH
├── python-dev.nix         # Python development
└── frontend-dev.nix       # Frontend tools
```

---

## Creating a Simple Profile

### Example: Cloud CLI Profile

Already in your config at `nix/profiles/cloud-cli.nix`:

```nix
{ config, pkgs, ... }:
{
  # Cloud CLI tools
  environment.systemPackages = with pkgs; [
    # AWS
    awscli2

    # GCP
    google-cloud-sdk

    # Kubernetes
    kubectl
    kubectx
    k9s
    helm

    # Infrastructure
    terraform
    terragrunt

    # Container tools
    skopeo
    dive
  ];
}
```

### Example: Developer Profile

Already in your config at `nix/profiles/developer.nix`:

```nix
{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # JSON/YAML tools
    jq
    yq-go

    # File utilities
    tree
    fd
    ripgrep

    # Build tools
    just
    gnumake
  ];
}
```

---

## Advanced Profiles

### Profile with Options

Profiles can define their own options:

```nix
{ config, pkgs, lib, ... }:

let
  cfg = config.profiles.python-dev;
in {
  options.profiles.python-dev = {
    enable = lib.mkEnableOption "Python development profile";

    includeDataScience = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Include data science tools";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Base Python tools
    {
      environment.systemPackages = with pkgs; [
        python3
        python3Packages.pip
        python3Packages.virtualenv
        poetry
        black
        ruff
      ];
    }

    # Data science tools (conditional)
    (lib.mkIf cfg.includeDataScience {
      environment.systemPackages = with pkgs; [
        python3Packages.numpy
        python3Packages.pandas
        python3Packages.matplotlib
        python3Packages.jupyter
      ];
    })
  ]);
}
```

### Profile with Home Manager

Profiles can configure both system and user:

```nix
{ config, pkgs, ... }:
{
  # System-level packages
  environment.systemPackages = with pkgs; [
    docker
    kubectl
  ];

  # User-level configuration
  home-manager.users.${config.system.primaryUser} = {
    home.packages = with pkgs; [
      k9s
      dive
    ];

    programs.git = {
      aliases = {
        k = "!kubectl";
        d = "!docker";
      };
    };
  };
}
```

### Platform-Specific Profiles

```nix
{ config, pkgs, lib, ... }:
{
  # Common tools
  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  # macOS specific
  environment.systemPackages = lib.optionals pkgs.stdenv.isDarwin [
    pkgs.darwin.trash
  ];

  # Linux specific
  environment.systemPackages = lib.optionals pkgs.stdenv.isLinux [
    pkgs.systemd
  ];

  # macOS Homebrew casks
  homebrew = lib.mkIf pkgs.stdenv.isDarwin {
    casks = [
      "visual-studio-code"
      "docker"
    ];
  };
}
```

---

## Using Profiles

### Enable in Host Configuration

Add to `hosts/your-mac.nix`:

```nix
{
  imports = [
    ../nix/profiles/cloud-cli.nix
    ../nix/profiles/developer.nix
    ../nix/profiles/python-dev.nix
  ];
}
```

### Enable in Flake

Add to `flake.nix`:

```nix
darwinConfigurations.your-mac = darwin.lib.darwinSystem {
  modules = [
    ./nix/modules/common.nix
    ./nix/modules/darwin-base.nix

    # Profiles
    ./nix/profiles/cloud-cli.nix
    ./nix/profiles/developer.nix
    ./nix/profiles/hardware-security.nix

    ./hosts/your-mac.nix
  ];
};
```

### Conditional Profiles

```nix
{
  imports = [
    # Always enabled
    ../nix/profiles/developer.nix
  ]
  # Conditional
  ++ lib.optional config.work.enable ../nix/profiles/cloud-cli.nix
  ++ lib.optional config.gaming.enable ../nix/profiles/gaming.nix;
}
```

---

## Best Practices

### Single Responsibility

```nix
# ✅ Good: Focused profile
# nix/profiles/python-dev.nix
{
  environment.systemPackages = [
    pkgs.python3
    pkgs.poetry
    pkgs.black
  ];
}

# ❌ Bad: Kitchen sink
# nix/profiles/everything.nix
{
  environment.systemPackages = [
    pkgs.python3  # Python
    pkgs.nodejs   # Node
    pkgs.go       # Go
    pkgs.awscli   # Cloud
    # Too much!
  ];
}
```

### Composition Over Duplication

```nix
# ✅ Good: Compose smaller profiles
{
  imports = [
    ./base-dev.nix
    ./python-dev.nix
    ./frontend-dev.nix
  ];
}

# ❌ Bad: Duplicate everything
# nix/profiles/fullstack.nix
{
  environment.systemPackages = [
    # Duplicates from base-dev
    pkgs.git
    pkgs.vim
    # Python stuff
    pkgs.python3
    # Frontend stuff
    pkgs.nodejs
  ];
}
```

### Clear Naming

```nix
# ✅ Good: Descriptive names
nix/profiles/
├── python-dev.nix       # Python development
├── cloud-aws.nix        # AWS tools
├── frontend-react.nix   # React development

# ❌ Bad: Vague names
nix/profiles/
├── dev.nix              # What kind?
├── tools.nix            # Which tools?
├── stuff.nix            # ???
```

### Documentation

```nix
# Good: Document what profile provides
{ config, pkgs, ... }:
{
  # Frontend Development Profile
  #
  # Provides:
  # - Node.js and package managers (npm, pnpm, yarn)
  # - Build tools (webpack, vite)
  # - Linters and formatters (eslint, prettier)
  # - Browser tools (playwright)

  environment.systemPackages = with pkgs; [
    # ... packages
  ];
}
```

---

## Examples

### Example 1: Language Profile

```nix
# nix/profiles/go-dev.nix
{ config, pkgs, ... }:
{
  # Go development tools
  environment.systemPackages = with pkgs; [
    # Compiler and tools
    go
    gopls          # Language server
    gotools        # go fmt, go imports, etc
    golangci-lint  # Linting
    delve          # Debugger

    # Database tools (for Go apps)
    sqlite
    postgresql
  ];

  # Environment variables
  environment.variables = {
    GOPATH = "$HOME/go";
    GOBIN = "$HOME/go/bin";
  };

  # Shell configuration
  programs.zsh.shellAliases = {
    got = "go test ./...";
    gob = "go build";
    gor = "go run .";
  };
}
```

### Example 2: Role-Based Profile

```nix
# nix/profiles/devops.nix
{ config, pkgs, ... }:
{
  # DevOps engineer profile
  environment.systemPackages = with pkgs; [
    # Cloud
    awscli2
    google-cloud-sdk
    azure-cli

    # Containers
    docker
    kubectl
    helm
    k9s

    # Infrastructure
    terraform
    ansible
    packer

    # Monitoring
    prometheus
    grafana

    # Scripting
    python3
    bash
  ];

  # Kubernetes config
  environment.variables = {
    KUBECONFIG = "$HOME/.kube/config";
  };
}
```

### Example 3: Security Profile

```nix
# nix/profiles/security.nix
{ config, pkgs, ... }:
{
  # Security tools profile
  environment.systemPackages = with pkgs; [
    # Scanning
    nmap
    masscan
    rustscan

    # Analysis
    wireshark
    tcpdump
    burpsuite

    # Cryptography
    gnupg
    age
    sops
    openssl

    # Password management
    pass
    gopass
  ];

  # Security-focused settings
  environment.variables = {
    GNUPGHOME = "$HOME/.gnupg";
  };

  programs.gnupg.agent.enable = true;
}
```

### Example 4: AI/ML Profile

```nix
# nix/profiles/ai-ml.nix
{ config, pkgs, ... }:
{
  # AI/ML development profile
  environment.systemPackages = with pkgs; [
    # Python for ML
    python3
    python3Packages.pip

    # ML frameworks (via pip/poetry)
    poetry

    # Jupyter
    python3Packages.jupyter
    python3Packages.ipython

    # GPU tools (if available)
    cudaPackages.cudatoolkit
  ];

  # Python packages via overlay
  nixpkgs.overlays = [
    (final: prev: {
      python3 = prev.python3.override {
        packageOverrides = pyfinal: pyprev: {
          # Custom Python packages
        };
      };
    })
  ];
}
```

### Example 5: Minimal Profile

```nix
# nix/profiles/minimal.nix
{ config, pkgs, ... }:
{
  # Minimal base profile
  environment.systemPackages = with pkgs; [
    # Essential tools only
    git
    vim
    curl
    wget
    tree
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
  };
}
```

---

## Testing Profiles

### Test Build

```bash
# Build without applying
darwin-rebuild build --flake .#your-hostname

# Check what packages are added
nix-store -q --tree ./result | grep -v "^/"
```

### Enable/Disable

```nix
# Easy to toggle
{
  imports = [
    ../nix/profiles/developer.nix
    # ../nix/profiles/cloud-cli.nix  # Disabled
  ];
}
```

### Profile Variants

```nix
# Create variants
imports =
  if config.work.enable
  then [
    ../nix/profiles/cloud-aws.nix
    ../nix/profiles/devops.nix
  ]
  else [
    ../nix/profiles/minimal.nix
  ];
```

---

## Next Steps

- **[Creating Modules](./creating-modules.md)** - Write custom modules
- **[Adding Packages](./adding-packages.md)** - Install software
- **[Working with Overlays](./working-with-overlays.md)** - Customize packages
- **[Custom Profile Example](../../examples/creating-custom-profile.md)** - Complete walkthrough

---

## Related Documentation

- [Structure Guide](../../architecture/structure.md) - Profile system explained
- [Profiles Reference](../../reference/profiles-reference.md) - All profiles documented
- [Examples](../../examples/) - Practical examples

---

## External References

- [NixOS Profiles](https://nixos.wiki/wiki/Profiles) - Wiki documentation
- [Nix Modules](https://nixos.org/manual/nixos/stable/#sec-writing-modules) - Module system
- [Configuration Patterns](https://nixos.org/guides/nix-pills/) - Nix Pills

---

**Ready to create profiles?** Start with a [simple profile](#creating-a-simple-profile)!
