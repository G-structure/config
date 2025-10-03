# Nix Configuration Structure: Modular Multi-Platform Architecture

A comprehensive guide to understanding and extending this modular Nix configuration supporting macOS (Darwin), Linux (NixOS), and cloud deployments (AWS EC2, GCP GCE).

---

## Contents

* [Philosophy & Design Principles](#philosophy--design-principles)
* [Directory Structure Deep Dive](#directory-structure-deep-dive)
* [Configuration Flow & Module Loading](#configuration-flow--module-loading)
* [Platform-Specific Modules](#platform-specific-modules)
* [Profiles: Composable Feature Bundles](#profiles-composable-feature-bundles)
* [Adding New Components](#adding-new-components)
* [Multi-Platform Support](#multi-platform-support)
* [Best Practices & Patterns](#best-practices--patterns)
* [Decision Matrix: When to Use What](#decision-matrix-when-to-use-what)
* [Practical Examples](#practical-examples)
* [Appendix: Additional Resources](#appendix-additional-resources)

---

## Philosophy & Design Principles

This configuration is built on four core principles that guide all architectural decisions:

**1. Modularity**
Separate concerns into small, focused modules that do one thing well. Each module should be independently testable and maintainable. Base modules handle platform fundamentals, profiles bundle related features, and hosts compose these pieces.

**2. Composability**
Mix and match profiles to create different system configurations. A development workstation imports `cloud-cli.nix` + `developer.nix`, while a production server might only import `server-base.nix`. The same profile works across Darwin and NixOS.

**3. Multi-Platform from Day One**
Support multiple platforms (macOS, Linux, cloud) from a single flake. Use conditional logic (`lib.mkIf`, `pkgs.stdenv.isDarwin`) rather than separate repositories. Share as much as possible via `common.nix`, specialize only when necessary.

**4. Future-Ready Architecture**
Structure anticipates expansion to Kubernetes manifests (Kubenix), Infrastructure as Code (Terranix), OCI image builds (dockerTools), and GitOps (Flux/ArgoCD). Today's configuration should make tomorrow's features easy to add.

References: [flake-parts](https://github.com/hercules-ci/flake-parts), [nix-darwin](https://github.com/LnL7/nix-darwin), [NixOS modules](https://nixos.org/manual/nixos/stable/#sec-writing-modules)

---

## Directory Structure Deep Dive

### `/nix/modules/` — Platform Base Modules

**Purpose**: Core system configuration shared or platform-specific

```
nix/modules/
├── common.nix              # Cross-platform Nix settings, gc, env vars
├── darwin-base.nix         # macOS system defaults, state version
├── linux-base.nix          # NixOS boot, networking, SSH baseline
├── darwin/
│   └── homebrew.nix        # Homebrew casks and brews
├── cloud/
│   ├── ec2-base.nix        # AWS EC2 boot, cloud-init, SSM
│   └── gce-base.nix        # GCP GCE boot, guest agent
└── secrets/
    └── sops.nix            # SOPS secrets management with GPG/age
```

**What belongs here**:
- Nix daemon configuration (`nix.settings`, `nix.gc`)
- Platform boot configuration (`boot.loader`, `fileSystems`)
- Network fundamentals (`networking.firewall`)
- System-level defaults (macOS `system.defaults`, NixOS `services.openssh`)
- Secrets infrastructure (SOPS setup, key paths)

**What does NOT belong here**:
- User-specific packages (those go in profiles or home-manager)
- Application-level configuration (unless system-wide daemon)
- Host-specific overrides (hostname, hardware-configuration)

**Key files**:

`common.nix` — Settings shared across all platforms
```nix
{ lib, pkgs, config, ... }:
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "@admin" ];
    # ... cache configuration
  };

  # Conditional GC (only if nix.enable = true)
  nix.gc = lib.mkIf config.nix.enable {
    automatic = true;
    options = "--delete-older-than 14d";
  };

  environment.systemPackages = with pkgs; [ git vim curl wget ];
}
```

`darwin-base.nix` — macOS-specific system configuration
```nix
{ config, pkgs, lib, ... }:
{
  system.stateVersion = 5;
  nixpkgs.config.allowUnfree = true;

  # When using Determinate Nix
  nix.enable = false;

  system.defaults = {
    NSGlobalDomain.AppleShowAllExtensions = true;
    dock.autohide = true;
    finder.FXEnableExtensionChangeWarning = false;
  };
}
```

`linux-base.nix` — NixOS baseline
```nix
{ config, pkgs, lib, ... }:
{
  system.stateVersion = "24.05";

  services.openssh = {
    enable = lib.mkDefault true;
    settings.PasswordAuthentication = lib.mkDefault false;
  };

  networking.firewall.enable = lib.mkDefault true;
}
```

References: [NixOS options search](https://search.nixos.org/options), [nix-darwin options](https://daiderd.com/nix-darwin/manual/index.html)

---

### `/nix/profiles/` — Composable Feature Bundles

**Purpose**: Reusable collections of related packages and configuration

```
nix/profiles/
├── cloud-cli.nix           # AWS, GCP, K8s, Terraform
├── developer.nix           # jq, yq, tree, just
└── hardware-security.nix   # Ledger GPG/SSH agents (home-manager)
```

**Profile design philosophy**:
- Each profile is a **complete feature** that can stand alone
- Profiles should work on any compatible platform (use conditionals)
- Keep profiles focused (cloud tools vs dev tools vs security)
- Profiles compose cleanly (no conflicts when importing multiple)

**Example: cloud-cli.nix**
```nix
{ config, pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [
    awscli2       # AWS CLI
    terraform     # Infrastructure as Code
    kubectl       # Kubernetes CLI
    skopeo        # OCI image operations (daemonless)
    dive          # Docker image exploration
  ];
}
```

**Example: developer.nix**
```nix
{ config, pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [
    jq            # JSON processor
    yq            # YAML processor
    tree          # Directory visualization
    just          # Command runner
  ];
}
```

**When to create a new profile**:
- You have 3+ related packages that form a coherent feature
- Multiple hosts will need this exact combination
- The feature is optional (not every host needs it)
- Configuration is mostly package installation (minimal options)

**When NOT to create a profile**:
- Single package (just add to host directly)
- Platform-specific fundamentals (those go in base modules)
- Highly host-specific configuration (those go in hosts/)

References: [Nixpkgs package search](https://search.nixos.org/packages)

---

### `/nix/overlays/` — Package Customization

**Purpose**: Modify existing packages or add custom builds

```
nix/overlays/
├── ledger-agent.nix         # Custom build from trezor-agent repo
└── ledger-ssh-agent.nix     # Python 2→3 migration for Ledger app
```

**What overlays do**:
- Override package definitions from nixpkgs
- Add patches or build flags
- Change dependencies
- Create entirely new packages (alternative to `/nix/packages/`)

**Example overlay structure**:
```nix
final: prev: {
  # Override existing package
  python312 = prev.python312.override {
    packageOverrides = pyFinal: pyPrev: {
      ledgerblue = pyPrev.ledgerblue.overridePythonAttrs (old: {
        pythonRemoveDeps = [ "bleak" ];  # Remove macOS-incompatible dep
        postPatch = /* ... */;
      });
    };
  };

  # Add new package
  ledger-agent = final.python312.pkgs.buildPythonApplication {
    pname = "ledger-agent";
    version = "0.9.0";
    # ... build instructions
  };
}
```

**When to use overlays**:
- Upstream package has bugs you need to patch
- Need different build configuration than default
- Package isn't in nixpkgs yet
- Want to apply changes across your entire configuration

**Applied automatically** in `flake.nix`:
```nix
pkgs = import nixpkgs {
  inherit system;
  config.allowUnfree = true;
  overlays = [
    (import ./nix/overlays/ledger-agent.nix)
    (import ./nix/overlays/ledger-ssh-agent.nix)
  ];
};
```

References: [Nixpkgs overlays manual](https://nixos.org/manual/nixpkgs/stable/#chap-overlays), [Python packaging guide](https://nixos.org/manual/nixpkgs/stable/#python)

---

### `/nix/packages/` — Custom Package Definitions

**Purpose**: Standalone package definitions for in-house or specialized tools

```
nix/packages/
└── ai-clis.nix             # AI CLI tools bundle
```

**Difference from overlays**:
- **Overlays**: Modify nixpkgs or add to `pkgs.*`
- **Packages**: Standalone derivations exposed via `nix build .#name`

**Example package**:
```nix
# nix/packages/ai-clis.nix
{ pkgs, ... }:
pkgs.buildEnv {
  name = "ai-clis";
  paths = with pkgs; [
    # AI development tools
    # (custom or vendored packages)
  ];
}
```

**Exposed in flake**:
```nix
perSystem = { system, pkgs, ... }: {
  packages = {
    ai-clis = pkgs.callPackage ./nix/packages/ai-clis.nix { };
    default = self.packages.${system}.ai-clis;
  };
};
```

**Usage**:
```bash
nix build .#ai-clis
nix build      # Builds default package
```

References: [Nix flakes packages](https://nixos.wiki/wiki/Flakes#Output_schema), [pkgs.buildEnv](https://nixos.org/manual/nixpkgs/stable/#trivial-builder-buildEnv)

---

### `/nix/secrets/` — SOPS Encrypted Secrets

**Purpose**: Store sensitive data encrypted with GPG or age

```
nix/secrets/
├── README.md
├── secrets.yaml.example
└── test-secret.yaml
```

**How SOPS works**:
1. Secrets encrypted with GPG (Ledger hardware wallet) or age
2. Stored in Git as encrypted YAML/JSON
3. Decrypted at runtime on target systems
4. Never appear in Nix store in plaintext

**Example workflow**:
```bash
# Configure recipients in .sops.yaml
cat > .sops.yaml <<EOF
creation_rules:
  - path_regex: nix/secrets/.*\.yaml
    pgp: 'D2A7EC63E350CC488197CB2ED369B07E00FB233E'  # Your GPG key
EOF

# Create and edit secret
sops nix/secrets/secrets.yaml

# Commit encrypted file
git add nix/secrets/secrets.yaml
git commit -m "Add encrypted secrets"
```

**NixOS integration** via `nix/modules/secrets/sops.nix`:
```nix
{ config, pkgs, lib, ... }:
{
  sops = {
    gnupg.home = "~/.gnupg-ledger";
    defaultSopsFile = ../../secrets/secrets.yaml;
  };

  # Secrets decrypted at boot, available as files
  # sops.secrets."api-key".path = "/run/secrets/api-key";
}
```

References: [SOPS](https://github.com/getsops/sops), [sops-nix](https://github.com/Mic92/sops-nix), [age](https://github.com/FiloSottile/age)

---

### `/hosts/` — Host-Specific Configuration

**Purpose**: Machine-specific settings and hardware configuration

```
hosts/
├── wikigen-mac.nix          # MacBook Pro
├── linux-workstation.nix    # Placeholder for NixOS workstation
└── README.md
```

**What goes in host files**:
- Hostname and networking configuration
- User accounts and home directories
- Hardware-specific settings (on NixOS: `hardware-configuration.nix`)
- Machine-specific packages (e.g., laptop tools vs server tools)
- Host-specific service configuration

**Example host file**:
```nix
# hosts/wikigen-mac.nix
{ config, pkgs, self, ... }:
{
  system.primaryUser = "wikigen";

  users.users.wikigen = {
    name = "wikigen";
    home = "/Users/wikigen";
  };

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    self.packages.aarch64-darwin.ai-clis
  ];
}
```

**Minimal host file** (most config comes from modules/profiles):
```nix
{ config, pkgs, ... }:
{
  networking.hostName = "my-machine";
  # Everything else from imported modules
}
```

**Registered in flake.nix**:
```nix
darwinConfigurations.wikigen-mac = darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  modules = [
    ./nix/modules/common.nix
    ./nix/modules/darwin-base.nix
    ./nix/profiles/cloud-cli.nix
    ./nix/profiles/developer.nix
    ./hosts/wikigen-mac.nix  # <-- Host-specific config
    # ... home-manager, etc.
  ];
};
```

References: [NixOS hardware configuration](https://nixos.org/manual/nixos/stable/#sec-installation-manual-partitioning), hosts/README.md

---

### `/home/users/` — Home Manager Configuration

**Purpose**: User-level dotfiles, shell configuration, and user packages

```
home/users/
└── wikigen.nix             # User-specific home-manager config
```

**What belongs in home-manager**:
- Shell configuration (zsh, bash, fish)
- Git config (user, email, signing)
- Terminal emulator settings
- User-specific packages (not system-wide)
- Dotfiles (vim, tmux, etc.)
- User services (gpg-agent, ssh-agent)

**Example user configuration**:
```nix
# home/users/wikigen.nix
{ config, pkgs, ... }:
{
  imports = [
    ../../nix/profiles/hardware-security.nix  # Ledger GPG/SSH setup
  ];

  home.stateVersion = "24.11";

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    initContent = ''
      # Colima autostart
      if command -v colima &>/dev/null; then
        if ! colima status &>/dev/null; then
          echo "Starting Colima..."
          colima start --cpu 4 --memory 8 --disk 100
        fi
      fi
    '';
  };

  programs.git = {
    enable = true;
    userName = "Luc Chartier";
    userEmail = "luc@distorted.media";
  };
}
```

**Activated in flake.nix**:
```nix
darwinConfigurations.wikigen-mac = darwin.lib.darwinSystem {
  modules = [
    # ... other modules
    home-manager.darwinModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.users.wikigen = import ./home/users/wikigen.nix;
    }
  ];
};
```

References: [Home Manager manual](https://nix-community.github.io/home-manager/), [Home Manager options](https://nix-community.github.io/home-manager/options.xhtml)

---

## Configuration Flow & Module Loading

Understanding how modules are loaded and evaluated is key to debugging and extending the configuration.

### Loading Order

```
1. flake.nix inputs (nixpkgs, darwin, home-manager, etc.)
   ↓
2. Overlays applied to create custom pkgs
   ↓
3. darwinConfiguration or nixosConfiguration created
   ↓
4. Modules imported in order:
   - common.nix (cross-platform fundamentals)
   - darwin-base.nix or linux-base.nix (platform base)
   - Platform-specific modules (homebrew, cloud config)
   - Profiles (cloud-cli, developer, etc.)
   - Secrets (sops.nix)
   - Host-specific (hosts/wikigen-mac.nix)
   - Home Manager (home/users/wikigen.nix)
   ↓
5. Module system merges all options
   ↓
6. Assertions checked (e.g., nix.gc requires nix.enable)
   ↓
7. Final system configuration built
```

### Module Composition Pattern

**Good: Clear separation of concerns**
```nix
# hosts/my-host.nix
{ config, pkgs, ... }:
{
  imports = [
    ../nix/modules/common.nix          # Step 1: Platform fundamentals
    ../nix/modules/darwin-base.nix     # Step 2: OS-specific base
    ../nix/profiles/cloud-cli.nix      # Step 3: Feature profiles
    ../nix/profiles/developer.nix
  ];

  # Step 4: Host-specific overrides
  networking.hostName = "my-host";
  users.users.myuser.home = "/Users/myuser";
}
```

**Bad: Everything in one file**
```nix
# Don't do this - monolithic configuration
{ config, pkgs, ... }:
{
  # Hundreds of lines mixing platform, profile, and host config
  nix.settings = { ... };
  system.defaults = { ... };
  environment.systemPackages = [ ... ];
  homebrew.brews = [ ... ];
  # ... becomes unmaintainable
}
```

### Conditional Configuration

**Platform-specific packages**:
```nix
environment.systemPackages = with pkgs; [
  git
  vim
] ++ lib.optionals pkgs.stdenv.isDarwin [
  pinentry_mac      # macOS only
] ++ lib.optionals pkgs.stdenv.isLinux [
  pinentry-curses   # Linux only
];
```

**Conditional module options**:
```nix
# Only enable GC if nix.enable = true
nix.gc = lib.mkIf config.nix.enable {
  automatic = true;
  options = "--delete-older-than 14d";
};
```

**Darwin vs NixOS service**:
```nix
# Darwin launchd agent
launchd.agents.my-service = lib.mkIf pkgs.stdenv.isDarwin {
  # ... service config
};

# NixOS systemd service
systemd.services.my-service = lib.mkIf pkgs.stdenv.isLinux {
  # ... service config
};
```

References: [NixOS module system](https://nixos.org/manual/nixos/stable/#sec-writing-modules), [lib.mkIf documentation](https://nixos.org/manual/nixpkgs/stable/#function-library-lib.modules.mkIf)

---

## Platform-Specific Modules

### macOS (Darwin) Stack

**Required modules**:
- `nix/modules/common.nix` — Cross-platform Nix settings
- `nix/modules/darwin-base.nix` — macOS system defaults

**Optional modules**:
- `nix/modules/darwin/homebrew.nix` — GUI apps and macOS-specific tools
- `nix/modules/darwin/colima.nix` — Declarative Colima configuration (future)

**Key Darwin-specific settings**:
```nix
system.defaults = {
  NSGlobalDomain = {
    AppleShowAllExtensions = true;
    InitialKeyRepeat = 14;
    KeyRepeat = 1;
  };
  dock = {
    autohide = true;
    show-recents = false;
  };
  finder = {
    AppleShowAllExtensions = true;
    FXEnableExtensionChangeWarning = false;
  };
};
```

**Homebrew integration**:
```nix
homebrew = {
  enable = true;
  brews = [ "colima" "docker" ];
  casks = [ "ledger-live" ];
  onActivation.cleanup = "zap";
};
```

References: [nix-darwin manual](https://daiderd.com/nix-darwin/manual/index.html), [nix-darwin options](https://daiderd.com/nix-darwin/manual/index.html#sec-options)

---

### Linux (NixOS) Stack

**Required modules**:
- `nix/modules/common.nix` — Cross-platform Nix settings
- `nix/modules/linux-base.nix` — Boot, networking, SSH

**Optional modules**:
- `nix/modules/linux/docker.nix` — Docker configuration (future)
- `nix/modules/linux/podman.nix` — Podman configuration (future)

**Key NixOS-specific settings**:
```nix
boot.loader = {
  systemd-boot.enable = true;
  efi.canTouchEfiVariables = true;
};

networking = {
  hostName = "nixos-machine";
  networkmanager.enable = true;
  firewall.enable = true;
};

users.users.myuser = {
  isNormalUser = true;
  extraGroups = [ "wheel" "networkmanager" ];
};
```

References: [NixOS manual](https://nixos.org/manual/nixos/stable/), [NixOS options search](https://search.nixos.org/options)

---

### Cloud Stack (EC2 / GCE)

**AWS EC2 modules**:
- `nix/modules/common.nix` — Nix fundamentals
- `nix/modules/linux-base.nix` — Linux baseline
- `nix/modules/cloud/ec2-base.nix` — EC2-specific boot and cloud-init

**GCP GCE modules**:
- `nix/modules/common.nix` — Nix fundamentals
- `nix/modules/linux-base.nix` — Linux baseline
- `nix/modules/cloud/gce-base.nix` — GCE-specific boot and guest agent

**EC2 example configuration**:
```nix
# nix/modules/cloud/ec2-base.nix
{ lib, pkgs, ... }:
{
  boot.growPartition = true;
  boot.kernelParams = [ "console=ttyS0" ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };

  services.cloud-init.enable = true;
  # services.amazon-ssm-agent.enable = true;

  networking.usePredictableInterfaceNames = false;  # eth0

  environment.defaultPackages = [ ];
  documentation.enable = false;
}
```

**Building cloud images** (future):
```bash
# AWS EC2 AMI
nix build .#ec2Image

# GCP GCE image
nix build .#gceImage
```

References: [nixos-generators](https://github.com/nix-community/nixos-generators), design.md

---

## Profiles: Composable Feature Bundles

Profiles are the key to reusability. Import only what each host needs.

### Current Profiles

**cloud-cli.nix** — Cloud and infrastructure tools
```nix
environment.systemPackages = with pkgs; [
  awscli2       # AWS CLI (from nixpkgs-unstable)
  terraform     # Infrastructure as Code
  kubectl       # Kubernetes control
  skopeo        # Daemonless container operations
  dive          # Container image analysis
];
```

**developer.nix** — Development utilities
```nix
environment.systemPackages = with pkgs; [
  jq            # JSON manipulation
  yq            # YAML manipulation
  tree          # Directory visualization
  just          # Command runner
];
```

**hardware-security.nix** — Ledger hardware wallet (home-manager)
```nix
home.packages = with pkgs; [
  ledger-ssh-agent
  ledger-agent
];

programs.gpg.enable = true;
services.gpg-agent = {
  enable = true;
  enableSshSupport = true;
  pinentry.package = pkgs.pinentry_mac;
};
```

### Profile Usage Patterns

**Workstation** (developer + cloud access):
```nix
imports = [
  ../nix/profiles/developer.nix
  ../nix/profiles/cloud-cli.nix
  ../nix/profiles/hardware-security.nix
];
```

**Server** (minimal production):
```nix
imports = [
  ../nix/profiles/server-base.nix  # (future)
];
```

**CI/Build node** (build tools only):
```nix
imports = [
  ../nix/profiles/build-tools.nix  # (future)
];
```

---

## Adding New Components

### Adding a New Profile

**Step 1**: Create the profile file
```bash
cat > nix/profiles/database-tools.nix <<'EOF'
# Database administration tools
{ config, pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [
    postgresql_16
    pgcli
    redis
    mongosh
  ];
}
EOF
```

**Step 2**: Import in host or flake
```nix
# hosts/my-host.nix
{
  imports = [
    ../nix/profiles/database-tools.nix
  ];
}
```

**Step 3**: Apply configuration
```bash
darwin-rebuild switch --flake .#my-host
```

---

### Adding a New Module

**Step 1**: Create module with options
```bash
cat > nix/modules/monitoring.nix <<'EOF'
{ config, lib, pkgs, ... }:
with lib;
{
  options.monitoring = {
    enable = mkEnableOption "system monitoring";

    prometheusPort = mkOption {
      type = types.port;
      default = 9090;
      description = "Prometheus metrics port";
    };
  };

  config = mkIf config.monitoring.enable {
    # Conditional configuration based on option
    environment.systemPackages = with pkgs; [ prometheus ];
  };
}
EOF
```

**Step 2**: Import in flake or host
```nix
darwinConfigurations.my-host = darwin.lib.darwinSystem {
  modules = [
    ./nix/modules/monitoring.nix
    {
      monitoring.enable = true;
      monitoring.prometheusPort = 9100;
    }
  ];
};
```

---

### Adding a New Host

**Step 1**: Create host file
```bash
cat > hosts/my-laptop.nix <<'EOF'
{ config, pkgs, self, ... }:
{
  system.primaryUser = "myuser";

  users.users.myuser = {
    name = "myuser";
    home = "/Users/myuser";
  };

  networking.hostName = "my-laptop";
}
EOF
```

**Step 2**: Register in flake.nix
```nix
darwinConfigurations.my-laptop = darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  modules = [
    ./nix/modules/common.nix
    ./nix/modules/darwin-base.nix
    ./nix/modules/darwin/homebrew.nix
    ./nix/profiles/developer.nix
    ./hosts/my-laptop.nix
    home-manager.darwinModules.home-manager
    {
      home-manager.users.myuser = import ./home/users/myuser.nix;
    }
  ];
};
```

**Step 3**: Build and activate
```bash
darwin-rebuild switch --flake .#my-laptop
```

---

## Multi-Platform Support

### Supported Systems

The flake targets three system architectures:

```nix
systems = [
  "aarch64-darwin"   # Apple Silicon (M1/M2/M3/M4)
  "x86_64-linux"     # Intel/AMD Linux
  "aarch64-linux"    # ARM Linux (EC2 Graviton, etc.)
];
```

### Platform Detection Patterns

**Package selection**:
```nix
environment.systemPackages = with pkgs; [
  # Universal packages
  git vim curl wget

  # Platform-specific
] ++ lib.optionals stdenv.isDarwin [
  pinentry_mac
  darwin.apple_sdk.frameworks.Security
] ++ lib.optionals stdenv.isLinux [
  pinentry-curses
  systemd
];
```

**Service configuration**:
```nix
# macOS launchd
launchd.user.agents.my-service = lib.mkIf stdenv.isDarwin {
  serviceConfig = {
    ProgramArguments = [ "${pkgs.myapp}/bin/myapp" ];
    RunAtLoad = true;
  };
};

# Linux systemd
systemd.user.services.my-service = lib.mkIf stdenv.isLinux {
  description = "My Service";
  serviceConfig = {
    ExecStart = "${pkgs.myapp}/bin/myapp";
  };
  wantedBy = [ "default.target" ];
};
```

### Cross-Platform Testing

**Test Darwin build**:
```bash
nix build .#darwinConfigurations.wikigen-mac.system --dry-run
```

**Test NixOS build** (if Linux host available):
```bash
nix build .#nixosConfigurations.linux-workstation.config.system.build.toplevel --dry-run
```

**Test packages on all systems**:
```bash
nix flake check
```

References: [Cross-compilation](https://nixos.org/manual/nixpkgs/stable/#chap-cross), [Platform detection](https://nixos.org/manual/nixpkgs/stable/#sec-platform-detection)

---

## Best Practices & Patterns

### Module Organization

**Do**: Separate concerns clearly
```
nix/modules/darwin-base.nix     — macOS system settings
nix/profiles/developer.nix       — Development packages
hosts/my-host.nix                — Host-specific config
```

**Don't**: Mix concerns in single file
```
hosts/my-host.nix containing platform base + profiles + host config
```

---

### Import Strategy

**Good: Explicit imports, clear dependencies**
```nix
{ config, pkgs, ... }:
{
  imports = [
    ../nix/modules/common.nix
    ../nix/modules/darwin-base.nix
    ../nix/profiles/developer.nix
  ];

  networking.hostName = "my-machine";
}
```

**Bad: Implicit dependencies, unclear load order**
```nix
{ config, pkgs, ... }:
{
  # Hoping another module loaded first
  networking.hostName = "my-machine";
}
```

---

### Conditional Logic

**Good: Use lib.mkIf for options**
```nix
nix.gc = lib.mkIf config.nix.enable {
  automatic = true;
  options = "--delete-older-than 14d";
};
```

**Good: Use lib.optionals for lists**
```nix
environment.systemPackages = with pkgs; [
  git
] ++ lib.optionals stdenv.isDarwin [
  pinentry_mac
];
```

**Bad: Manual conditionals everywhere**
```nix
environment.systemPackages = with pkgs;
  if stdenv.isDarwin then [ git pinentry_mac ]
  else [ git pinentry-curses ];
```

---

### Secrets Management

**Good: Never commit plaintext secrets**
```yaml
# nix/secrets/secrets.yaml (encrypted with SOPS)
api_key: ENC[AES256_GCM,data:xxx,type:str]
```

**Good: Use runtime decryption**
```nix
sops.secrets."api-key".path = "/run/secrets/api-key";
```

**Bad: Hardcoded secrets**
```nix
environment.variables.API_KEY = "sk-1234567890";  # Never do this!
```

References: [SOPS](https://github.com/getsops/sops), [sops-nix](https://github.com/Mic92/sops-nix), docs/sops.md

---

## Decision Matrix: When to Use What

| Component Type | Use Case | Location | Example |
|----------------|----------|----------|---------|
| **Base Module** | Platform fundamentals, system-wide config | `/nix/modules/` | Boot settings, Nix daemon config, SSH defaults |
| **Profile** | Reusable feature bundle, 3+ related packages | `/nix/profiles/` | Cloud CLI tools, development utilities |
| **Overlay** | Modify existing package, add custom build | `/nix/overlays/` | Patch ledgerblue, build custom Python package |
| **Package** | Standalone derivation | `/nix/packages/` | AI CLI tools bundle, custom app |
| **Host Config** | Machine-specific settings | `/hosts/` | Hostname, users, hardware-configuration |
| **Home Config** | User dotfiles, shell, git | `/home/users/` | Zsh config, git signing, user packages |
| **Secret** | Encrypted sensitive data | `/nix/secrets/` | API keys, passwords, certificates |

---

## Practical Examples

### Example 1: Developer Workstation (macOS)

**Goal**: Full-featured development machine with cloud access and hardware security

```nix
# hosts/dev-mac.nix
{ config, pkgs, self, ... }:
{
  system.primaryUser = "developer";

  users.users.developer = {
    name = "developer";
    home = "/Users/developer";
  };
}
```

**Flake configuration**:
```nix
darwinConfigurations.dev-mac = darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  modules = [
    ./nix/modules/common.nix
    ./nix/modules/darwin-base.nix
    ./nix/modules/darwin/homebrew.nix
    ./nix/profiles/developer.nix
    ./nix/profiles/cloud-cli.nix
    ./nix/modules/secrets/sops.nix
    ./hosts/dev-mac.nix
    home-manager.darwinModules.home-manager
    {
      home-manager.users.developer = import ./home/users/developer.nix;
    }
  ];
};
```

**Result**: Developer gets jq, yq, tree, just, awscli2, terraform, kubectl, Ledger GPG/SSH support, and SOPS secrets management.

---

### Example 2: Minimal Cloud Server (NixOS on EC2)

**Goal**: Lightweight production server with SSH access and cloud tooling

```nix
# hosts/prod-server.nix
{ config, pkgs, ... }:
{
  networking.hostName = "prod-server";

  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAA... admin@workstation"
    ];
  };
}
```

**Flake configuration**:
```nix
nixosConfigurations.prod-server = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    ./nix/modules/common.nix
    ./nix/modules/linux-base.nix
    ./nix/modules/cloud/ec2-base.nix
    ./hosts/prod-server.nix
  ];
};
```

**Result**: Minimal server with SSH, cloud-init, SSM agent, automatic boot configuration.

---

### Example 3: Adding Kubernetes Tools

**Step 1**: Create profile
```bash
cat > nix/profiles/kubernetes.nix <<'EOF'
{ config, pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [
    kubectl
    kubectx
    k9s
    helm
    kustomize
  ];
}
EOF
```

**Step 2**: Import in workstation
```nix
# hosts/dev-mac.nix
{
  imports = [
    ../nix/profiles/kubernetes.nix
  ];
}
```

**Step 3**: Rebuild
```bash
darwin-rebuild switch --flake .#dev-mac
```

---

## Appendix: Additional Resources

### Official Documentation

**Nix Ecosystem**
- [Nix Manual](https://nixos.org/manual/nix/stable/) — Core Nix language and tooling
- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/) — Package repository and functions
- [NixOS Manual](https://nixos.org/manual/nixos/stable/) — Linux distribution documentation
- [nix-darwin Manual](https://daiderd.com/nix-darwin/manual/) — macOS support
- [Home Manager Manual](https://nix-community.github.io/home-manager/) — User environment management

**Search and Discovery**
- [NixOS Options Search](https://search.nixos.org/options) — All NixOS configuration options
- [Nixpkgs Search](https://search.nixos.org/packages) — Package repository search
- [MyNixOS](https://mynixos.com/) — Alternative search interface

### Related Projects

**Infrastructure**
- [flake-parts](https://github.com/hercules-ci/flake-parts) — Flake organization framework
- [nixos-generators](https://github.com/nix-community/nixos-generators) — Cloud image builders
- [terranix](https://github.com/terranix/terranix) — Terraform via Nix

**Secrets Management**
- [sops-nix](https://github.com/Mic92/sops-nix) — NixOS SOPS integration
- [SOPS](https://github.com/getsops/sops) — Secrets encryption tool
- [age](https://github.com/FiloSottile/age) — Modern encryption

**GitOps & Kubernetes**
- [kubenix](https://github.com/hall/kubenix) — Kubernetes manifests in Nix
- [Flux](https://fluxcd.io/) — GitOps for Kubernetes
- [ArgoCD](https://argo-cd.readthedocs.io/) — Declarative GitOps

### Community Resources

**Learning Nix**
- [Nix Pills](https://nixos.org/guides/nix-pills/) — Deep dive tutorial series
- [NixOS Wiki](https://nixos.wiki/) — Community documentation
- [Zero to Nix](https://zero-to-nix.com/) — Beginner-friendly guide

**Example Configurations**
- [NixOS Discourse](https://discourse.nixos.org/) — Community forum
- [Awesome Nix](https://github.com/nix-community/awesome-nix) — Curated resources
- [nix-dotfiles](https://github.com/MatthiasBenaets/nix-dotfiles) — Example configurations

### Related Documentation in This Repo

- `README.md` — Quick start and daily usage
- `design.md` — Future roadmap and detailed architecture
- `hosts/README.md` — Host-specific setup guide
- `sops.md` — Secrets management details
- `gpg.md` — GPG and Ledger configuration
- `ledger_on_my_chain.md` — Hardware security deep dive
