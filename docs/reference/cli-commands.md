---
title: CLI Commands Reference
---


Quick reference for common Nix and nix-darwin commands.

---

## Table of Contents

- [System Management](#system-management)
- [Package Management](#package-management)
- [Flake Commands](#flake-commands)
- [Store Operations](#store-operations)
- [Development](#development)
- [Troubleshooting](#troubleshooting)

---

## System Management

### darwin-rebuild

```bash
# Apply configuration changes
darwin-rebuild switch --flake .#hostname

# Build without applying
darwin-rebuild build --flake .#hostname

# Test build (dry run)
darwin-rebuild build --flake .#hostname --dry-run

# Build with trace (for errors)
darwin-rebuild switch --flake .#hostname --show-trace

# List generations
darwin-rebuild --list-generations

# Switch to generation
darwin-rebuild switch --switch-generation 5

# Rollback to previous
darwin-rebuild switch --rollback

# Delete specific generations
darwin-rebuild delete-generations 1 2 3

# Delete old generations (30+ days)
darwin-rebuild delete-generations +30
```

### System Information

```bash
# Show current system
ls -l /run/current-system

# System configuration
darwin-option -r

# Specific option
darwin-option programs.zsh.enable

# Show all options
darwin-option --list
```

---

## Package Management

### Searching Packages

```bash
# Search nixpkgs
nix search nixpkgs python

# Search with JSON output
nix search nixpkgs --json python | jq

# Browse online
# https://search.nixos.org/packages
```

### Installing Packages

```bash
# Add to configuration file, then:
darwin-rebuild switch --flake .#hostname

# Or install to user profile
nix profile install nixpkgs#package-name

# List installed (in profile)
nix profile list

# Remove from profile
nix profile remove package-name
```

### Package Information

```bash
# Show package metadata
nix eval nixpkgs#python3.meta.description

# Show version
nix eval nixpkgs#python3.version

# Show package info
nix-env -qa --description python3
```

---

## Flake Commands

### Flake Management

```bash
# Update all inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs

# Show flake info
nix flake show

# Show flake metadata
nix flake metadata

# Check flake
nix flake check

# Archive flake
nix flake archive --to file://backup.tar.gz
```

### Flake Building

```bash
# Build default package
nix build

# Build specific output
nix build .#ai-clis

# Build system
nix build .#darwinConfigurations.hostname.system

# Build and run
nix run .#package-name
```

### Flake Development

```bash
# Enter dev shell
nix develop

# Run command in dev shell
nix develop --command bash
```

---

## Store Operations

### Store Queries

```bash
# List all store paths
nix-store --query --requisites /run/current-system

# Show references (runtime deps)
nix-store --query --references /nix/store/path

# Show referrers (what depends on this)
nix-store --query --referrers /nix/store/path

# Dependency tree
nix-store --query --tree /run/current-system

# Closure size
nix path-info -S /run/current-system

# All paths sorted by size
nix path-info -rS /run/current-system | sort -nk2
```

### Store Maintenance

```bash
# Garbage collection
nix-collect-garbage

# Delete old generations (30+ days)
nix-collect-garbage --delete-older-than 30d

# Delete everything not in use
nix-collect-garbage -d

# Optimize store (deduplicate)
nix-store --optimise

# Verify store
nix-store --verify --check-contents

# Repair store
nix-store --verify --check-contents --repair
```

### Store Comparison

```bash
# Diff two store paths
nix store diff-closures /run/current-system ./result

# Compare generations
nix store diff-closures \
  /nix/var/nix/profiles/system-5-link \
  /nix/var/nix/profiles/system-6-link
```

---

## Development

### Building

```bash
# Build package
nix build .#package-name

# Build with logs
nix build .#package-name --print-build-logs

# Build with trace
nix build .#package-name --show-trace

# Keep failed builds
nix build .#package-name --keep-failed

# Dry run (what would build)
nix build .#package-name --dry-run

# Force rebuild
nix build .#package-name --rebuild
```

### Evaluation

```bash
# Evaluate expression
nix eval .#package-name.version

# Evaluate with JSON
nix eval --json .#package-name.meta

# Parse Nix file
nix-instantiate --parse file.nix

# Evaluate Nix file
nix-instantiate --eval file.nix

# Show derivation
nix derivation show .#package-name
```

### Testing

```bash
# Enter shell with package
nix shell nixpkgs#python3

# Run command with package
nix run nixpkgs#hello

# Develop with package
nix develop
```

---

## Troubleshooting

### Debugging

```bash
# Verbose output
darwin-rebuild switch --flake .#hostname --verbose

# Show trace
darwin-rebuild switch --flake .#hostname --show-trace

# Debug evaluation
nix eval --show-trace .#darwinConfigurations.hostname

# Check what's wrong
nix flake check --show-trace
```

### Repair

```bash
# Repair store
nix-store --verify --check-contents --repair

# Re-download from cache
nix-store --verify --check-contents

# Delete and rebuild
rm -rf result
nix build .#package-name
```

### Cache Issues

```bash
# Build without cache (force local)
nix build .#package-name --option substitute false

# Use specific cache
nix build .#package-name \
  --option substituters "https://cache.nixos.org"

# Check if path in cache
nix path-info --store https://cache.nixos.org /nix/store/path
```

---

## Quick Reference

### Most Used Commands

```bash
# Update and rebuild
nix flake update && darwin-rebuild switch --flake .#hostname

# Test before applying
darwin-rebuild build --flake .#hostname
nix store diff-closures /run/current-system ./result

# Rollback if broken
darwin-rebuild switch --rollback

# Clean up old stuff
nix-collect-garbage --delete-older-than 30d

# Search for package
nix search nixpkgs package-name

# Check configuration
nix flake check
```

### Common Workflows

**Update system:**
```bash
cd ~/Config
nix flake update
darwin-rebuild build --flake .#hostname
nix store diff-closures /run/current-system ./result
darwin-rebuild switch --flake .#hostname
```

**Add package:**
```nix
# Edit hosts/hostname.nix
environment.systemPackages = [ pkgs.new-package ];
```
```bash
darwin-rebuild switch --flake .#hostname
```

**Test package:**
```bash
nix build .#package-name
./result/bin/package-name
```

**Recover from error:**
```bash
darwin-rebuild switch --rollback
# Or
darwin-rebuild switch --switch-generation 5
```

---

## Environment Variables

```bash
# Nix configuration
NIX_PATH="nixpkgs=/path/to/nixpkgs"

# Build cores
NIX_BUILD_CORES=8

# Store directory (usually default)
NIX_STORE_DIR="/nix/store"

# Remote builders
NIX_REMOTE_SYSTEMS="user@builder"

# Show all options
nix show-config
```

---

## Related Documentation

- [Nix Fundamentals](./nix-fundamentals.md) - Understanding Nix
- [Troubleshooting](./troubleshooting.md) - Common issues
- [Testing Builds](../guides/development/testing-builds.md) - Build testing

---

## External References

- [Nix Manual](https://nixos.org/manual/nix/stable/command-ref/nix-env.html) - Command reference
- [nix-darwin Manual](https://daiderd.com/nix-darwin/manual/) - Darwin commands
- [Nix Pills](https://nixos.org/guides/nix-pills/) - In-depth tutorials

---

**Bookmark this page for quick command reference!**
