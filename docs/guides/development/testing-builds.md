---
title: Testing Builds
---


Learn how to test Nix builds before applying changes to your system.

---

## Table of Contents

- [Overview](#overview)
- [Dry Run Builds](#dry-run-builds)
- [Build Testing](#build-testing)
- [Diff Analysis](#diff-analysis)
- [Syntax Validation](#syntax-validation)
- [Package Testing](#package-testing)
- [CI/CD Integration](#cicd-integration)
- [Troubleshooting](#troubleshooting)

---

## Overview

Testing builds before applying them:
- Catches errors early
- Shows what will change
- Validates syntax and logic
- Prevents system breakage

---

## Dry Run Builds

### Build Without Applying

```bash
# Build but don't activate
darwin-rebuild build --flake .#your-hostname

# Result symlink created: ./result
ls -l ./result
```

### What You Get

```bash
# result/ contains the system closure
result/
├── sw/          # System packages
├── activate     # Activation script
└── ...

# Inspect packages
ls result/sw/bin/
```

### Check What Changed

```bash
# Compare with current system
nix store diff-closures /run/current-system ./result

# Output shows added/removed packages and size changes
```

---

## Build Testing

### Test Specific Package

```bash
# Build single package
nix build .#ai-clis

# Build and inspect
nix build .#ai-clis && ls ./result/bin/
```

### Test Configuration

```bash
# Build full configuration
nix build .#darwinConfigurations.your-hostname.system

# Verbose output
nix build .#darwinConfigurations.your-hostname.system --print-build-logs
```

### Test Different Systems

```bash
# Build for specific architecture
nix build .#darwinConfigurations.your-hostname.system --system aarch64-darwin

# Cross-compile (if supported)
nix build .#darwinConfigurations.your-hostname.system --system x86_64-darwin
```

---

## Diff Analysis

### Show Package Changes

```bash
# Detailed diff
nix store diff-closures /run/current-system ./result

# Example output:
# nodejs: 18.0.0 → 20.0.0 (+15.2 MB)
# python3: ∅ → 3.11.0 (+50.0 MB)
# vim: 9.0.0 → ε (removed)
```

### Analyze Size Impact

```bash
# Show closure size
nix path-info -S ./result

# Compare sizes
echo "Current: $(nix path-info -S /run/current-system | awk '{print $2}')"
echo "New:     $(nix path-info -S ./result | awk '{print $2}')"
```

### List All Changes

```bash
# All packages in new build
nix-store -q --tree ./result

# Just added packages
comm -13 \
  <(nix-store -q --references /run/current-system | sort) \
  <(nix-store -q --references ./result | sort)

# Just removed packages
comm -23 \
  <(nix-store -q --references /run/current-system | sort) \
  <(nix-store -q --references ./result | sort)
```

---

## Syntax Validation

### Flake Check

```bash
# Comprehensive checks
nix flake check

# Check specific system
nix flake check --system aarch64-darwin

# Show all outputs
nix flake show
```

### Parse Nix Files

```bash
# Check syntax
nix-instantiate --parse file.nix

# Evaluate (but don't build)
nix-instantiate --eval file.nix

# Evaluate with strict mode
nix-instantiate --eval --strict file.nix
```

### Validate Module

```bash
# Check module is loadable
nix eval .#darwinConfigurations.your-hostname.config.mymodule.enable

# Show module options
nix eval .#darwinConfigurations.your-hostname.options.mymodule --json | jq
```

---

## Package Testing

### Evaluate Package

```bash
# Show package metadata
nix eval .#mypackage.meta.description

# Show version
nix eval .#mypackage.version

# Show derivation
nix derivation show .#mypackage
```

### Build Package Locally

```bash
# Build package
nix build .#mypackage

# Run from result
./result/bin/mypackage --version

# Install to test profile
nix profile install .#mypackage

# Test, then remove
nix profile remove mypackage
```

### Test Package Dependencies

```bash
# Show runtime dependencies
nix-store -q --references ./result

# Show build dependencies
nix-store -q --requisites $(nix-instantiate -A mypackage)

# Dependency tree
nix-store -q --tree ./result
```

---

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/build.yml
name: Build Nix Configuration

on:
  pull_request:
  push:
    branches: [main]

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - uses: DeterminateSystems/nix-installer-action@main

      - name: Build configuration
        run: |
          nix build .#darwinConfigurations.your-hostname.system

      - name: Check flake
        run: |
          nix flake check

      - name: Show diff
        if: github.event_name == 'pull_request'
        run: |
          # Compare with main branch
          git fetch origin main
          nix build github:${{ github.repository }}/main#darwinConfigurations.your-hostname.system -o result-main
          nix store diff-closures ./result-main ./result
```

### GitLab CI

```yaml
# .gitlab-ci.yml
build:
  image: nixos/nix
  script:
    - nix build .#darwinConfigurations.your-hostname.system
    - nix flake check

test:
  image: nixos/nix
  script:
    - nix build .#ai-clis
    - ./result/bin/claude-code --version
```

### Pre-commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: nix-flake-check
        name: Nix flake check
        entry: nix flake check
        language: system
        pass_filenames: false

      - id: nix-format
        name: Nix format
        entry: nix fmt
        language: system
        files: \.nix$
```

---

## Troubleshooting

### Build Fails

```bash
# Show full build log
nix build .#mypackage --print-build-logs

# Show trace
nix build .#mypackage --show-trace

# Keep failed build
nix build .#mypackage --keep-failed

# Failed build at:
# /tmp/nix-build-mypackage-1.0.0.drv-0
```

### Evaluation Errors

```bash
# Debug evaluation
nix eval .#darwinConfigurations.your-hostname --show-trace

# Check specific attribute
nix eval .#darwinConfigurations.your-hostname.config.environment.systemPackages --json
```

### Dependency Issues

```bash
# Why is package included?
nix why-depends ./result nixpkgs#python3

# Show dependency path
nix-store -q --tree ./result | grep python3 -B5
```

### Cache Misses

```bash
# Check what needs to build
nix build .#mypackage --dry-run

# Build without substitutes (force local build)
nix build .#mypackage --option substitute false

# Use specific cache
nix build .#mypackage --option substituters "https://cache.nixos.org"
```

---

## Testing Workflows

### Safe Update Workflow

```bash
# 1. Backup current generation
darwin-rebuild --list-generations

# 2. Update flake lock
nix flake update

# 3. Build (don't apply)
darwin-rebuild build --flake .#your-hostname

# 4. Check diff
nix store diff-closures /run/current-system ./result

# 5. If looks good, apply
darwin-rebuild switch --flake .#your-hostname

# 6. If something breaks, rollback
darwin-rebuild switch --rollback
```

### Package Development Workflow

```bash
# 1. Create package
vim nix/packages/mypackage.nix

# 2. Quick syntax check
nix-instantiate --parse nix/packages/mypackage.nix

# 3. Test build
nix build .#mypackage

# 4. Test executable
./result/bin/mypackage

# 5. Iterate
vim nix/packages/mypackage.nix
nix build .#mypackage --rebuild

# 6. Add to system
environment.systemPackages = [ pkgs.mypackage ];
```

### Module Testing Workflow

```bash
# 1. Create module
vim nix/modules/mymodule.nix

# 2. Validate syntax
nix-instantiate --parse nix/modules/mymodule.nix

# 3. Check module loads
nix eval .#darwinConfigurations.your-hostname.config.mymodule.enable

# 4. Build with module
darwin-rebuild build --flake .#your-hostname

# 5. Check what changed
nix store diff-closures /run/current-system ./result

# 6. Apply if good
darwin-rebuild switch --flake .#your-hostname
```

---

## Best Practices

### Always Test First

```bash
# ❌ Bad: Direct apply
darwin-rebuild switch --flake .#hostname

# ✅ Good: Test first
darwin-rebuild build --flake .#hostname
nix store diff-closures /run/current-system ./result
darwin-rebuild switch --flake .#hostname
```

### Use Version Control

```bash
# ✅ Good: Commit before major changes
git add .
git commit -m "WIP: testing new package"
darwin-rebuild build --flake .#hostname
# If fails, easy to revert
git reset --hard HEAD
```

### Document Test Results

```bash
# ✅ Good: Save diff output
nix store diff-closures /run/current-system ./result > changes.txt
git add changes.txt
git commit -m "Add mypackage" -m "$(cat changes.txt)"
```

### Test on Branches

```bash
# ✅ Good: Use git branches
git checkout -b test-new-feature
# Make changes
darwin-rebuild build --flake .#hostname
# Test
# If good: merge, if bad: delete branch
```

---

## Quick Reference

### Essential Commands

```bash
# Build without applying
darwin-rebuild build --flake .#hostname

# Show diff
nix store diff-closures /run/current-system ./result

# Validate configuration
nix flake check

# Test package
nix build .#package && ./result/bin/package

# Show what needs building
nix build .#hostname --dry-run

# Rollback if needed
darwin-rebuild switch --rollback
```

---

## Next Steps

- **[Adding Packages](./adding-packages.md)** - Install software
- **[Creating Modules](./creating-modules.md)** - Write modules
- **[Working with Overlays](./working-with-overlays.md)** - Customize packages
- **[Troubleshooting](../../reference/troubleshooting.md)** - Fix issues

---

## Related Documentation

- [CLI Commands](../../reference/cli-commands.md) - Command reference
- [Nix Fundamentals](../../reference/nix-fundamentals.md) - Understanding builds
- [Structure Guide](../../architecture/structure.md) - Config architecture

---

## External References

- [Nix Manual - Testing](https://nixos.org/manual/nix/stable/command-ref/nix-build.html) - Build commands
- [nix-darwin Manual](https://daiderd.com/nix-darwin/manual/) - Darwin-rebuild
- [Nix Pills](https://nixos.org/guides/nix-pills/) - Deep dives

---

**Ready to test builds?** Start with a [dry run](#dry-run-builds)!
