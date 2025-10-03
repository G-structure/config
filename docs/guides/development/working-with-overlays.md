# Working with Overlays

Learn how to customize and modify packages using Nix overlays.

---

## Table of Contents

- [Overview](#overview)
- [What is an Overlay?](#what-is-an-overlay)
- [Creating Overlays](#creating-overlays)
- [Common Use Cases](#common-use-cases)
- [Advanced Techniques](#advanced-techniques)
- [Testing Overlays](#testing-overlays)
- [Best Practices](#best-practices)
- [Examples](#examples)

---

## Overview

**Overlays** allow you to modify or extend the nixpkgs package set. They:
- Override package versions
- Add custom packages
- Apply patches to existing packages
- Customize build options

---

## What is an Overlay?

### Overlay Function

An overlay is a function that takes two package sets and returns modifications:

```nix
final: prev: {
  # final = resulting package set
  # prev = original package set

  mypackage = prev.mypackage.override { ... };
}
```

### How Overlays Work

```
nixpkgs (original)
    │
    ▼
overlay 1 (modifications)
    │
    ▼
overlay 2 (more modifications)
    │
    ▼
final package set (your config uses this)
```

Each overlay can reference:
- `final` - The final package set (after all overlays)
- `prev` - The previous package set (before this overlay)

---

## Creating Overlays

### Basic Overlay Structure

Create `nix/overlays/my-overlay.nix`:

```nix
final: prev: {
  # Add new package
  my-tool = prev.callPackage ./packages/my-tool.nix { };

  # Override existing package
  ripgrep = prev.ripgrep.overrideAttrs (old: {
    version = "14.0.0";
  });
}
```

### Apply Overlay in Flake

In `flake.nix`:

```nix
{
  darwinConfigurations.your-mac = darwin.lib.darwinSystem {
    modules = [
      {
        nixpkgs.overlays = [
          (import ./nix/overlays/my-overlay.nix)
          (import ./nix/overlays/another-overlay.nix)
        ];
      }
      # ... other modules
    ];
  };
}
```

### Apply in Module

In a module file:

```nix
{ config, pkgs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      # Overlay content
    })
  ];
}
```

---

## Common Use Cases

### Override Package Version

```nix
final: prev: {
  # Use different version
  nodejs = prev.nodejs_20;

  # Override with specific version
  python3 = prev.python311;

  # Use unstable version
  neovim = final.callPackage ./custom-neovim.nix { };
}
```

### Apply Patches

```nix
final: prev: {
  myapp = prev.myapp.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./fix-bug.patch
      (prev.fetchpatch {
        url = "https://github.com/user/repo/pull/123.patch";
        sha256 = "sha256-...";
      })
    ];
  });
}
```

### Change Build Options

```nix
final: prev: {
  # Enable feature
  vim = prev.vim.override {
    python3Support = true;
    rubySupport = true;
  };

  # Disable feature
  git = prev.git.override {
    guiSupport = false;
    svnSupport = false;
  };

  # Custom configuration
  nginx = prev.nginx.override {
    modules = [ prev.nginxModules.rtmp ];
  };
}
```

### Add Custom Package

```nix
final: prev: {
  my-tool = prev.stdenv.mkDerivation {
    pname = "my-tool";
    version = "1.0.0";

    src = prev.fetchFromGitHub {
      owner = "user";
      repo = "my-tool";
      rev = "v1.0.0";
      sha256 = "sha256-...";
    };

    buildInputs = [ prev.go ];

    buildPhase = ''
      go build -o my-tool
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp my-tool $out/bin/
    '';
  };
}
```

---

## Advanced Techniques

### Python Package Overlays

```nix
final: prev: {
  python3 = prev.python3.override {
    packageOverrides = pyfinal: pyprev: {
      # Add custom Python package
      my-python-lib = pyfinal.buildPythonPackage {
        pname = "my-python-lib";
        version = "1.0.0";
        src = prev.fetchPypi {
          pname = "my-python-lib";
          version = "1.0.0";
          sha256 = "sha256-...";
        };
      };

      # Override Python package version
      requests = pyprev.requests.overridePythonAttrs (old: {
        version = "2.31.0";
      });
    };
  };
}
```

### Recursive Overlays

```nix
final: prev: {
  # Reference other overlay modifications
  my-app = final.callPackage ./my-app.nix {
    # Use modified version from another overlay
    nodejs = final.nodejs;
  };
}
```

### Conditional Overlays

```nix
final: prev:
let
  isDarwin = prev.stdenv.isDarwin;
in
{
  # macOS-specific override
  myapp = prev.myapp.overrideAttrs (old: {
    buildInputs = old.buildInputs
      ++ prev.lib.optionals isDarwin [ prev.darwin.apple_sdk.frameworks.Security ];
  });
}
```

### Overlay Composition

```nix
# nix/overlays/default.nix
[
  (import ./ledger-agent.nix)
  (import ./ai-tools.nix)
  (import ./custom-packages.nix)
]

# In flake.nix
nixpkgs.overlays = import ./nix/overlays;
```

---

## Testing Overlays

### Build with Overlay

```bash
# Test build
nix build .#your-package

# Check package derivation
nix show-derivation .#your-package

# Evaluate package
nix eval .#your-package.version
```

### Debug Overlay

```nix
final: prev: {
  # Add debug output
  myapp = prev.myapp.overrideAttrs (old: {
    # Print during build
    postBuild = ''
      echo "Building with version: ${old.version}"
      ${old.postBuild or ""}
    '';
  });
}
```

### Test in Isolation

```bash
# Test single package with overlay
nix-build -E 'with import <nixpkgs> { overlays = [ (import ./my-overlay.nix) ]; }; mypackage'
```

---

## Best Practices

### Use Final for References

```nix
# ✅ Good: Use final to reference overlaid packages
final: prev: {
  my-app = final.callPackage ./my-app.nix {
    nodejs = final.nodejs;  # Gets overlaid version
  };
}

# ❌ Bad: Use prev, might get old version
final: prev: {
  my-app = final.callPackage ./my-app.nix {
    nodejs = prev.nodejs;  # Gets pre-overlay version
  };
}
```

### Minimize Rebuilds

```nix
# ✅ Good: Only override what's needed
final: prev: {
  myapp = prev.myapp.override {
    enableFeature = true;
  };
}

# ❌ Bad: Causes full rebuild
final: prev: {
  myapp = prev.myapp.overrideAttrs (old: {
    # Changing derivation forces rebuild of dependents
    version = old.version;
  });
}
```

### Organize Overlays

```nix
# ✅ Good: Separate concerns
nix/overlays/
├── ledger-agent.nix      # Ledger-specific
├── python-packages.nix   # Python overrides
├── security-tools.nix    # Security packages

# ❌ Bad: Everything in one file
nix/overlays/
└── everything.nix        # 1000+ lines
```

### Document Changes

```nix
final: prev: {
  # Override Node.js version to 20 for compatibility with our tools
  # See: https://github.com/org/tool/issues/123
  nodejs = prev.nodejs_20;

  # Add patch to fix memory leak
  # Upstream PR: https://github.com/upstream/repo/pull/456
  myapp = prev.myapp.overrideAttrs (old: {
    patches = [ ./fix-memory-leak.patch ];
  });
}
```

---

## Examples

### Example 1: Ledger Agent Overlay

From your config (`nix/overlays/ledger-agent.nix`):

```nix
final: prev: {
  ledger-agent = prev.python3Packages.trezor-agent.overridePythonAttrs (old: {
    pname = "ledger-agent";

    propagatedBuildInputs = old.propagatedBuildInputs ++ [
      prev.python3Packages.ledger-bitcoin
      prev.python3Packages.hidapi
    ];

    postInstall = ''
      ${old.postInstall or ""}
      # Custom ledger-specific binaries
      for tool in ledger-agent ledger-gpg-agent; do
        ln -s $out/bin/trezor-agent $out/bin/$tool
      done
    '';
  });
}
```

### Example 2: AI CLI Tools

From your config (`nix/packages/ai-clis.nix`):

```nix
{ pkgs, lib }:

pkgs.buildNpmPackage {
  pname = "ai-clis";
  version = "1.0.0";

  src = ../../tools/js;

  npmDepsHash = "sha256-aSip2gUeEM3RRCszF8jvH9MX0X3dRbLW5C4dy+lsdpE=";

  dontNpmBuild = true;

  postInstall = ''
    mkdir -p $out/bin
    if [ -d "$out/lib/node_modules/ai-cli-bundle/node_modules/.bin" ]; then
      for bin in "$out/lib/node_modules/ai-cli-bundle/node_modules/.bin"/*; do
        if [ -f "$bin" ] || [ -L "$bin" ]; then
          ln -s "$bin" "$out/bin/$(basename "$bin")"
        fi
      done
    fi
  '';

  meta = with lib; {
    description = "Bundle of pinned npm CLIs (Claude Code, MCP Inspector)";
    platforms = platforms.darwin ++ platforms.linux;
  };
}
```

### Example 3: Custom Python Tools

```nix
final: prev: {
  my-python-tools = prev.python3.withPackages (ps: [
    # Standard packages
    ps.requests
    ps.flask

    # Custom package
    (ps.buildPythonPackage {
      pname = "my-lib";
      version = "1.0.0";
      src = prev.fetchPypi {
        pname = "my-lib";
        version = "1.0.0";
        sha256 = "sha256-...";
      };
      propagatedBuildInputs = [ ps.requests ];
    })
  ]);
}
```

### Example 4: Security Tools Override

```nix
final: prev: {
  # Use latest nmap
  nmap = prev.nmap.overrideAttrs (old: {
    version = "7.94";
    src = prev.fetchurl {
      url = "https://nmap.org/dist/nmap-7.94.tar.bz2";
      sha256 = "sha256-...";
    };
  });

  # Add Ledger support to GnuPG
  gnupg = prev.gnupg.override {
    enableLdap = true;
    enableUsb = true;
  };
}
```

### Example 5: Development Tools

```nix
final: prev: {
  # Latest neovim with plugins
  neovim-custom = prev.neovim.override {
    configure = {
      packages.myPlugins = with prev.vimPlugins; {
        start = [ nvim-lspconfig nvim-treesitter ];
      };
      customRC = ''
        lua << EOF
        require('lspconfig').nixd.setup{}
        EOF
      '';
    };
  };

  # Go with custom version
  go = prev.go_1_21;

  # Node.js 20 LTS
  nodejs = prev.nodejs_20;
}
```

---

## Troubleshooting

### Overlay Not Applied

```bash
# Check if overlay is loaded
nix eval .#darwinConfigurations.your-mac.config.nixpkgs.overlays

# Check package after overlay
nix eval .#darwinConfigurations.your-mac.pkgs.mypackage.version
```

### Infinite Recursion

```nix
# ❌ Bad: Creates infinite loop
final: prev: {
  mypackage = final.mypackage.override { ... };  # Refers to itself!
}

# ✅ Good: Use prev
final: prev: {
  mypackage = prev.mypackage.override { ... };
}
```

### Build Failures

```bash
# Build with trace
nix build .#mypackage --show-trace

# Check derivation
nix show-derivation .#mypackage

# Compare with original
nix show-derivation nixpkgs#mypackage
```

---

## Next Steps

- **[Adding Packages](./adding-packages.md)** - Install software
- **[Creating Modules](./creating-modules.md)** - Write custom modules
- **[Testing Builds](./testing-builds.md)** - Test your changes
- **[Packaging Example](../../examples/packaging-custom-app.md)** - Complete example

---

## Related Documentation

- [Structure Guide](../../architecture/structure.md) - Overlay system explained
- [Nix Fundamentals](../../reference/nix-fundamentals.md) - Understanding Nix
- [Troubleshooting](../../reference/troubleshooting.md) - Common issues

---

## External References

- [Nixpkgs Overlays](https://nixos.org/manual/nixpkgs/stable/#chap-overlays) - Official docs
- [Overlays Wiki](https://nixos.wiki/wiki/Overlays) - Community docs
- [Package Overriding](https://nixos.org/manual/nixpkgs/stable/#chap-overrides) - Override techniques

---

**Ready to customize packages?** Start with a [basic overlay](#creating-overlays)!
