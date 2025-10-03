# Creating Modules

Learn how to write custom Nix modules for your configuration.

---

## Table of Contents

- [Overview](#overview)
- [Module Basics](#module-basics)
- [Module Structure](#module-structure)
- [Creating a Simple Module](#creating-a-simple-module)
- [Module Options](#module-options)
- [Advanced Patterns](#advanced-patterns)
- [Testing Modules](#testing-modules)
- [Best Practices](#best-practices)
- [Examples](#examples)

---

## Overview

**Modules** are reusable configuration units in Nix. They:
- Encapsulate related configuration
- Provide options for customization
- Can be composed with other modules
- Enable declarative system configuration

---

## Module Basics

### What is a Module?

A module is a Nix function that returns an attribute set with configuration:

```nix
{ config, pkgs, lib, ... }:
{
  # Configuration goes here
  options = { };    # Define options
  config = { };     # Set values
  imports = [ ];    # Import other modules
}
```

### Module Arguments

Modules receive these standard arguments:

- `config` - The full system configuration
- `pkgs` - Package set (nixpkgs)
- `lib` - Nixpkgs library functions
- `...` - Other custom arguments

---

## Module Structure

### Basic Module Template

```nix
{ config, pkgs, lib, ... }:

{
  # Import other modules
  imports = [
    ./submodule.nix
  ];

  # Define options
  options = {
    services.myservice.enable = lib.mkEnableOption "my service";
  };

  # Configuration (conditional on options)
  config = lib.mkIf config.services.myservice.enable {
    environment.systemPackages = [ pkgs.mypackage ];
  };
}
```

### File Organization

```
nix/modules/
├── common.nix              # Cross-platform base
├── darwin-base.nix         # macOS base
├── darwin/
│   └── homebrew.nix        # Homebrew config
├── cloud/
│   ├── ec2-base.nix        # AWS config
│   └── gce-base.nix        # GCP config
└── secrets/
    └── sops.nix            # SOPS config
```

---

## Creating a Simple Module

### Example: Development Environment Module

Create `nix/modules/development.nix`:

```nix
{ config, pkgs, lib, ... }:

{
  # System packages for development
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
  ];

  # Git configuration
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };

  # Shell configuration
  programs.zsh.enable = true;
}
```

### Use in Configuration

Add to your host config or flake.nix:

```nix
{
  imports = [
    ./nix/modules/development.nix
  ];
}
```

---

## Module Options

### Defining Options

Options make modules configurable:

```nix
{ config, pkgs, lib, ... }:

{
  options.myapp = {
    enable = lib.mkEnableOption "MyApp service";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port to listen on";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.myapp;
      description = "MyApp package to use";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/myapp";
      description = "Data directory";
    };
  };

  config = lib.mkIf config.myapp.enable {
    # Use options here
    environment.systemPackages = [ config.myapp.package ];

    # Create data directory
    system.activationScripts.myapp = ''
      mkdir -p ${config.myapp.dataDir}
    '';
  };
}
```

### Option Types

Common option types:

```nix
{
  options = {
    # Boolean
    enable = lib.mkEnableOption "feature";

    # String
    name = lib.mkOption {
      type = lib.types.str;
      default = "default";
    };

    # Integer
    count = lib.mkOption {
      type = lib.types.int;
      default = 1;
    };

    # Port (integer 1-65535)
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
    };

    # Path
    configFile = lib.mkOption {
      type = lib.types.path;
      default = ./config.yaml;
    };

    # Package
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.myapp;
    };

    # List of strings
    hosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };

    # Attribute set
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };

    # Enum (one of specific values)
    logLevel = lib.mkOption {
      type = lib.types.enum [ "debug" "info" "warn" "error" ];
      default = "info";
    };
  };
}
```

### Using Options

```nix
# In your host config
{
  myapp = {
    enable = true;
    port = 3000;
    dataDir = "/custom/path";
  };
}
```

---

## Advanced Patterns

### Conditional Configuration

```nix
{ config, pkgs, lib, ... }:

{
  config = lib.mkIf config.services.myapp.enable {
    # Only applied if myapp is enabled

    environment.systemPackages = [ pkgs.myapp ];

    # Nested conditional
    environment.variables = lib.mkIf config.services.myapp.debug {
      DEBUG = "true";
    };
  };
}
```

### Merging Configurations

```nix
{ config, pkgs, lib, ... }:

{
  config = lib.mkMerge [
    # Base config (always applied)
    {
      environment.systemPackages = [ pkgs.base ];
    }

    # Conditional config
    (lib.mkIf config.myapp.enable {
      environment.systemPackages = [ pkgs.myapp ];
    })

    # Another conditional
    (lib.mkIf config.myapp.extraFeatures {
      environment.systemPackages = [ pkgs.extra ];
    })
  ];
}
```

### Platform-Specific Config

```nix
{ config, pkgs, lib, ... }:

{
  config = lib.mkMerge [
    # Common config
    {
      environment.systemPackages = [ pkgs.common ];
    }

    # macOS only
    (lib.mkIf pkgs.stdenv.isDarwin {
      environment.systemPackages = [ pkgs.darwin-only ];
    })

    # Linux only
    (lib.mkIf pkgs.stdenv.isLinux {
      environment.systemPackages = [ pkgs.linux-only ];
    })
  ];
}
```

### Assertions and Warnings

```nix
{ config, pkgs, lib, ... }:

{
  config = {
    # Fail if condition not met
    assertions = [
      {
        assertion = config.myapp.enable -> config.database.enable;
        message = "MyApp requires database to be enabled";
      }
    ];

    # Warn user
    warnings = lib.optional
      (config.myapp.port < 1024)
      "MyApp running on privileged port ${toString config.myapp.port}";
  };
}
```

---

## Testing Modules

### Dry Run Build

```bash
# Test without applying
darwin-rebuild build --flake .#your-hostname

# Check what would change
darwin-rebuild build --flake .#your-hostname
nix store diff-closures /run/current-system ./result
```

### Syntax Check

```bash
# Check for syntax errors
nix flake check

# Evaluate module
nix eval .#darwinConfigurations.your-hostname.config.myapp.enable
```

### Debug Module Options

```bash
# Show all options for a module
darwin-option myapp

# Show option value
darwin-option myapp.enable

# Show option documentation
darwin-option -r myapp
```

---

## Best Practices

### Module Organization

```nix
# ✅ Good: Clear structure
{ config, pkgs, lib, ... }:

let
  cfg = config.services.myapp;
in {
  options.services.myapp = {
    enable = lib.mkEnableOption "MyApp";
    # ... more options
  };

  config = lib.mkIf cfg.enable {
    # Use cfg instead of config.services.myapp
    environment.systemPackages = [ cfg.package ];
  };
}
```

### Option Naming

```nix
# ✅ Good: Hierarchical, descriptive
options.services.myapp = {
  enable = ...;
  settings.port = ...;
  settings.host = ...;
};

# ❌ Bad: Flat, unclear
options.myapp-enabled = ...;
options.myapp-port = ...;
```

### Documentation

```nix
{
  options.myapp.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = lib.mdDoc ''
      Whether to enable MyApp service.

      MyApp provides XYZ functionality.
      See <https://myapp.example.com> for details.
    '';
  };
}
```

### Defaults

```nix
# ✅ Good: Sensible defaults
options.myapp = {
  port = lib.mkOption {
    type = lib.types.port;
    default = 8080;  # Standard port
  };

  logLevel = lib.mkOption {
    type = lib.types.enum [ "debug" "info" "warn" "error" ];
    default = "info";  # Reasonable default
  };
};
```

---

## Examples

### Example 1: Service Module

```nix
{ config, pkgs, lib, ... }:

let
  cfg = config.services.myservice;
in {
  options.services.myservice = {
    enable = lib.mkEnableOption "my service";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Service port";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "myservice";
      description = "User to run service as";
    };
  };

  config = lib.mkIf cfg.enable {
    # Create user
    users.users.${cfg.user} = {
      name = cfg.user;
      description = "MyService user";
    };

    # Install package
    environment.systemPackages = [ pkgs.myservice ];

    # Create launchd service (macOS)
    launchd.user.agents.myservice = lib.mkIf pkgs.stdenv.isDarwin {
      config = {
        ProgramArguments = [
          "${pkgs.myservice}/bin/myservice"
          "--port" "${toString cfg.port}"
        ];
        RunAtLoad = true;
      };
    };
  };
}
```

### Example 2: Development Tools Module

```nix
{ config, pkgs, lib, ... }:

let
  cfg = config.development;
in {
  options.development = {
    enable = lib.mkEnableOption "development tools";

    languages = lib.mkOption {
      type = lib.types.listOf (lib.types.enum [ "python" "node" "go" "rust" ]);
      default = [ ];
      description = "Programming languages to install";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Base development tools
    {
      environment.systemPackages = with pkgs; [
        git
        vim
        curl
        jq
      ];
    }

    # Python
    (lib.mkIf (builtins.elem "python" cfg.languages) {
      environment.systemPackages = with pkgs; [
        python3
        python3Packages.pip
        python3Packages.virtualenv
      ];
    })

    # Node.js
    (lib.mkIf (builtins.elem "node" cfg.languages) {
      environment.systemPackages = with pkgs; [
        nodejs
        nodePackages.npm
        nodePackages.pnpm
      ];
    })

    # Go
    (lib.mkIf (builtins.elem "go" cfg.languages) {
      environment.systemPackages = [ pkgs.go ];
    })

    # Rust
    (lib.mkIf (builtins.elem "rust" cfg.languages) {
      environment.systemPackages = with pkgs; [
        rustc
        cargo
        rustfmt
      ];
    })
  ]);
}
```

### Example 3: Cloud Provider Module

```nix
{ config, pkgs, lib, ... }:

let
  cfg = config.cloud;
in {
  options.cloud = {
    providers = lib.mkOption {
      type = lib.types.listOf (lib.types.enum [ "aws" "gcp" "azure" ]);
      default = [ ];
      description = "Cloud providers to install tools for";
    };
  };

  config = {
    environment.systemPackages = lib.flatten [
      # AWS
      (lib.optional (builtins.elem "aws" cfg.providers) pkgs.awscli2)

      # GCP
      (lib.optional (builtins.elem "gcp" cfg.providers) pkgs.google-cloud-sdk)

      # Azure
      (lib.optional (builtins.elem "azure" cfg.providers) pkgs.azure-cli)

      # Common tools if any provider enabled
      (lib.optionals (cfg.providers != [ ]) [
        pkgs.kubectl
        pkgs.terraform
      ])
    ];
  };
}
```

---

## Next Steps

- **[Creating Profiles](./creating-profiles.md)** - Build feature bundles
- **[Working with Overlays](./working-with-overlays.md)** - Customize packages
- **[Adding Packages](./adding-packages.md)** - Install software

---

## Related Documentation

- [Structure Guide](../../architecture/structure.md) - Module system explained
- [Modules Reference](../../reference/modules-reference.md) - All modules documented
- [Examples](../../examples/) - Practical examples

---

## External References

- [NixOS Module System](https://nixos.org/manual/nixos/stable/#sec-writing-modules) - Official docs
- [Module Options](https://nixos.org/manual/nixos/stable/index.html#sec-option-types) - Option types
- [lib Functions](https://nixos.org/manual/nixpkgs/stable/#chap-functions) - Helper functions

---

**Ready to create modules?** Start with a [simple module](#creating-a-simple-module)!
