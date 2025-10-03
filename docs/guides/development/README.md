# Development Guides

Learn how to extend and customize your Nix configuration.

---

## Overview

This section covers development workflows for customizing your Nix configuration. Learn to add packages, create modules, build profiles, and test changes before applying them.

---

## Documentation in This Section

### [Adding Packages](./adding-packages.md) ⭐
**Start here** to install new software.

**Covers:**
- Finding packages in nixpkgs
- Adding system-wide packages
- Adding user packages with Home Manager
- Installing Homebrew casks
- Custom package creation

**Perfect for:** Adding software to your system

---

### [Creating Modules](./creating-modules.md)
Write custom Nix modules for reusable configuration.

**Covers:**
- Module structure and basics
- Defining module options
- Conditional configuration
- Platform-specific modules
- Testing and validation

**Perfect for:** Building reusable configuration components

---

### [Creating Profiles](./creating-profiles.md)
Build composable feature bundles.

**Covers:**
- Profile vs module differences
- Creating simple profiles
- Role-based profiles (devops, security, ai-ml)
- Language-specific profiles
- Profile composition

**Perfect for:** Bundling related tools and configurations

---

### [Working with Overlays](./working-with-overlays.md)
Customize and modify packages using overlays.

**Covers:**
- Overlay fundamentals
- Overriding package versions
- Applying patches
- Adding custom packages
- Python and language-specific overlays

**Perfect for:** Customizing existing packages

---

### [Testing Builds](./testing-builds.md)
Test changes before applying to your system.

**Covers:**
- Dry run builds
- Diff analysis
- Syntax validation
- CI/CD integration
- Troubleshooting builds

**Perfect for:** Safe system updates and development

---

## Quick Start

### Add a Package (2 minutes)

```bash
# 1. Find package
nix search nixpkgs htop

# 2. Add to config
# In hosts/your-mac.nix:
environment.systemPackages = [ pkgs.htop ];

# 3. Apply
darwin-rebuild switch --flake .#your-hostname
```

### Create a Profile (5 minutes)

```bash
# 1. Create profile file
cat > nix/profiles/my-tools.nix << 'EOF'
{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    htop
    ripgrep
    fd
  ];
}
EOF

# 2. Add to flake.nix imports
imports = [ ./nix/profiles/my-tools.nix ];

# 3. Build and apply
darwin-rebuild switch --flake .#your-hostname
```

### Test Before Applying

```bash
# Build without applying
darwin-rebuild build --flake .#your-hostname

# Check what changed
nix store diff-closures /run/current-system ./result

# Apply if good
darwin-rebuild switch --flake .#your-hostname
```

---

## Development Workflows

### Package Development

```
1. Search/create package
   ↓
2. Test build locally
   ↓
3. Add to system/user config
   ↓
4. Test build (dry run)
   ↓
5. Apply changes
```

### Module Development

```
1. Create module with options
   ↓
2. Validate syntax
   ↓
3. Test evaluation
   ↓
4. Build system with module
   ↓
5. Apply and verify
```

### Profile Development

```
1. Identify related tools
   ↓
2. Create profile file
   ↓
3. Import in flake
   ↓
4. Test build
   ↓
5. Apply changes
```

---

## Common Tasks

### Install Software
→ [Adding Packages](./adding-packages.md)

**Quick:**
```nix
environment.systemPackages = [ pkgs.package-name ];
```

### Create Feature Bundle
→ [Creating Profiles](./creating-profiles.md)

**Quick:**
```nix
# nix/profiles/my-profile.nix
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [ tool1 tool2 ];
}
```

### Customize Package
→ [Working with Overlays](./working-with-overlays.md)

**Quick:**
```nix
nixpkgs.overlays = [(final: prev: {
  mypackage = prev.mypackage.override { enableFeature = true; };
})];
```

### Write Configuration Module
→ [Creating Modules](./creating-modules.md)

**Quick:**
```nix
{ config, lib, ... }: {
  options.mymodule.enable = lib.mkEnableOption "my module";
  config = lib.mkIf config.mymodule.enable { };
}
```

### Test Changes
→ [Testing Builds](./testing-builds.md)

**Quick:**
```bash
darwin-rebuild build --flake .#hostname
nix store diff-closures /run/current-system ./result
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Development Layers                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  flake.nix                                                  │
│      │                                                      │
│      ├─> Modules (nix/modules/)                             │
│      │   └─> Common, Darwin, Linux, Cloud                   │
│      │                                                      │
│      ├─> Profiles (nix/profiles/)                           │
│      │   └─> Cloud-CLI, Developer, Hardware-Security        │
│      │                                                      │
│      ├─> Overlays (nix/overlays/)                           │
│      │   └─> Package customizations                         │
│      │                                                      │
│      ├─> Packages (nix/packages/)                           │
│      │   └─> Custom packages                                │
│      │                                                      │
│      └─> Hosts (hosts/)                                     │
│          └─> Machine-specific configs                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Best Practices

### 1. Test Before Applying

```bash
# Always test first
darwin-rebuild build --flake .#hostname
nix store diff-closures /run/current-system ./result
darwin-rebuild switch --flake .#hostname
```

### 2. Use Version Control

```bash
# Commit before major changes
git add .
git commit -m "Add new feature"
# Test
# If breaks: git reset --hard HEAD
```

### 3. Organize by Purpose

```
nix/
├── modules/      # Low-level, configurable
├── profiles/     # High-level, opinionated
├── overlays/     # Package modifications
└── packages/     # Custom packages
```

### 4. Document Changes

```nix
# Good: Explain why
# Use Node 20 for compatibility with tool X
nodejs = prev.nodejs_20;

# Bad: No context
nodejs = prev.nodejs_20;
```

### 5. Keep It Simple

```nix
# ✅ Good: Clear and simple
environment.systemPackages = [ pkgs.htop ];

# ❌ Bad: Over-engineered
environment.systemPackages = lib.optionals
  (config.enable.monitoring)
  [ (if config.advanced then pkgs.htop-advanced else pkgs.htop) ];
```

---

## Troubleshooting

### Build Fails

```bash
# Show full error
nix build .#package --show-trace

# Keep failed build for inspection
nix build .#package --keep-failed
```

### Package Not Found

```bash
# Update flake
nix flake update

# Search again
nix search nixpkgs package-name
```

### Module Error

```bash
# Check module loads
nix eval .#darwinConfigurations.hostname.config.mymodule.enable

# Validate syntax
nix-instantiate --parse nix/modules/mymodule.nix
```

See [Troubleshooting Guide](../../reference/troubleshooting.md) for more.

---

## Examples

### Example 1: Python Development Setup

```nix
# nix/profiles/python-dev.nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    python3
    python3Packages.pip
    python3Packages.virtualenv
    poetry
    black
    ruff
  ];

  environment.variables = {
    PYTHONPATH = "$HOME/.local/lib/python3.11/site-packages";
  };
}
```

### Example 2: Cloud Developer Profile

```nix
# nix/profiles/cloud-dev.nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Cloud CLIs
    awscli2
    google-cloud-sdk
    azure-cli

    # Container tools
    docker
    kubectl
    helm

    # IaC
    terraform
    pulumi
  ];
}
```

### Example 3: Custom Package

```nix
# nix/packages/my-tool.nix
{ pkgs, lib }:

pkgs.buildGoModule {
  pname = "my-tool";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "user";
    repo = "my-tool";
    rev = "v1.0.0";
    sha256 = "sha256-...";
  };

  vendorHash = "sha256-...";

  meta = {
    description = "My custom tool";
    license = lib.licenses.mit;
  };
}
```

---

## Learning Path

### Beginner
1. **[Adding Packages](./adding-packages.md)** - Start here
2. **[Testing Builds](./testing-builds.md)** - Learn safe updates
3. **[Creating Profiles](./creating-profiles.md)** - Bundle tools

### Intermediate
4. **[Creating Modules](./creating-modules.md)** - Build reusable config
5. **[Working with Overlays](./working-with-overlays.md)** - Customize packages
6. **[Examples](../../examples/)** - Study real-world examples

### Advanced
7. [Design Philosophy](../../architecture/design.md) - Understand architecture
8. [Structure Guide](../../architecture/structure.md) - Deep dive
9. [Nix Fundamentals](../../reference/nix-fundamentals.md) - Master Nix

---

## Related Documentation

### In This Section
- [Adding Packages](./adding-packages.md)
- [Creating Modules](./creating-modules.md)
- [Creating Profiles](./creating-profiles.md)
- [Working with Overlays](./working-with-overlays.md)
- [Testing Builds](./testing-builds.md)

### Other Sections
- [Examples](../../examples/) - Practical walkthroughs
- [Reference](../../reference/) - Technical references
- [Architecture](../../architecture/) - Design docs

---

## External Resources

- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/) - Package docs
- [Nix Pills](https://nixos.org/guides/nix-pills/) - In-depth tutorials
- [NixOS Wiki](https://nixos.wiki/) - Community docs
- [Nix Dev](https://nix.dev/) - Learning resources

---

**Ready to develop?** Start with [Adding Packages](./adding-packages.md)!
