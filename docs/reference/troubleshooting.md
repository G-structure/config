---
title: Troubleshooting Guide
---


Common issues and solutions for this Nix configuration.

---

## System Build Errors

### "version mismatch" Error

**Problem:** nix-darwin version doesn't match nixpkgs

**Solution:**
```bash
# Update to latest
nix flake update

# Or use same channel for both
inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
inputs.nix-darwin.follows = "nixpkgs";
```

### "hash mismatch" Error

**Problem:** Package hash doesn't match expected

**Solution:**
```bash
# Get correct hash
nix-prefetch-url https://example.com/file.tar.gz

# Or use fake hash, build will show correct one
sha256 = lib.fakeSha256;
```

### Infinite Recursion

**Problem:** Overlay or module refers to itself

**Solution:**
```nix
# ❌ Bad: infinite loop
final: prev: {
  mypackage = final.mypackage.override { };
}

# ✅ Good: use prev
final: prev: {
  mypackage = prev.mypackage.override { };
}
```

---

## Activation Errors

### "nix.gc.automatic requires nix.enable"

**Problem:** Garbage collection enabled but nix daemon disabled

**Solution:**
```nix
# Make GC conditional
nix.gc = lib.mkIf config.nix.enable {
  automatic = true;
  options = "--delete-older-than 14d";
};
```

### Permission Denied

**Problem:** Activation script needs sudo

**Solution:**
```bash
# First-time activation needs sudo
sudo nix run nix-darwin -- switch --flake .#hostname

# Subsequent builds don't need sudo
darwin-rebuild switch --flake .#hostname
```

---

## Package Issues

### Package Not Found

**Solution:**
```bash
# Update flake
nix flake update

# Search again
nix search nixpkgs package-name

# Check attribute path
nix eval nixpkgs#package-name --apply builtins.attrNames
```

### Build Failure

**Solution:**
```bash
# Show full error
nix build .#package --show-trace

# Keep failed build
nix build .#package --keep-failed
cd /tmp/nix-build-package-*

# Try without cache
nix build .#package --option substitute false
```

---

## Homebrew Issues

### Cask Installation Fails

**Solution:**
```bash
# Manual install
brew install --cask app-name

# Update Homebrew
brew update

# Check cask exists
brew search app-name
```

---

## Hardware Security Issues

### Ledger Not Detected

**Solution:**
1. Check USB connection
2. Unlock with PIN
3. Open SSH/GPG Agent app
4. Check logs: `tail -f ~/.local/share/ledger-gpg-agent.error.log`

### GPG Signing Fails

**Solution:**
```bash
# Start agent
ledger-gpg-agent --homedir ~/.gnupg-ledger --server --verbose &

# Test
echo "test" | gpg --homedir ~/.gnupg-ledger --clearsign
```

---

## Quick Fixes

```bash
# Rollback broken system
darwin-rebuild switch --rollback

# Fix permissions
sudo chown -R $USER ~/.nix-profile

# Clear cache
rm -rf ~/.cache/nix

# Repair store
nix-store --verify --check-contents --repair
```

See [CLI Commands](./cli-commands.md) for more commands.
