# Nix Fundamentals Reference

A comprehensive guide to Nix's core concepts: store paths, derivations, evaluation model, and build process.

---

## Table of Contents

- [Nix Store Paths](#nix-store-paths)
- [Derivations](#derivations)
- [The Nix Store](#the-nix-store)
- [Evaluation Model](#evaluation-model)
- [Build Process](#build-process)
- [Binary Caches](#binary-caches)
- [Garbage Collection](#garbage-collection)
- [Fixed-Output Derivations](#fixed-output-derivations)
- [Quick Reference](#quick-reference)
- [Related Documentation](#related-documentation)

---

## Nix Store Paths

### Why Every Path Has a Hash

Every path in `/nix/store` starts with a unique hash:

```
/nix/store/1v3d2qj7k6vvkr7mprqnlk4p4yyk2r7d-python3-3.10.12
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
           32-character base-32 hash
```

### Hash Components

| What it is                                 | Key points                                                                                                                                                                                                                                                                                                                             |
| ------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **A deterministic ID**                     | The 32-character string is a base-32 encoding of the first 160 bits of a SHA-256 hash (older Nix once used MD5, which is why you sometimes still hear that).                                                                                                                                                                           |
| **What gets hashed**                       | Nix hashes a *derivation file* (.drv) that records:<br>• The exact build script<br>• All compile flags and environment variables<br>• Absolute paths of every input in `/nix/store`<br>This recipe is serialized to a Nix archive (NAR) and then hashed.                                                                              |
| **Why 160 bits, not the full 256**         | 160 bits keeps paths short enough to stay under Unix's 255-byte filename limit while still leaving the chance of a collision astronomically low.                                                                                                                                                                                       |
| **What it guarantees**                     | If any dependency, flag, or patch changes, the hash changes, so the output gets a new, unique path. That means:<br>• Builds are *pure* (no accidental reuse of impure results)<br>• Multiple versions can coexist side-by-side<br>• Nix can treat packages like immutable content-addressed blobs for caching and binary substituters. |

### Practical Takeaway

You never have to compute or remember these hashes. Nix does it so that:

- Every build is reproducible and referentially transparent
- The package manager can tell with one look at the path exactly which build recipe produced the files

Think of the hash as the package's **fingerprint**: change even a single bit of the recipe or its inputs and you get an entirely new fingerprint, guaranteeing there is no accidental overlap in the store.

---

## Derivations

### What is a Derivation?

A **derivation** (.drv file) is a build recipe that Nix uses to produce store paths. It's a pure description of:

- **Inputs**: All dependencies (other store paths)
- **Builder**: The program that performs the build
- **Environment**: All environment variables
- **Outputs**: What store paths will be produced

### Derivation File Format

Derivations are stored in `/nix/store` with a `.drv` extension:

```
/nix/store/abc123...-hello-2.10.drv
```

They're actually ATerm files (a tree-based data format), but you can inspect them:

```bash
# View derivation
nix derivation show /nix/store/...-hello-2.10.drv

# Or for a package
nix derivation show nixpkgs#hello
```

### Example Derivation Structure

```json
{
  "/nix/store/abc123...-hello-2.10.drv": {
    "outputs": {
      "out": {
        "path": "/nix/store/xyz789...-hello-2.10"
      }
    },
    "inputSrcs": [
      "/nix/store/...-hello-2.10.tar.gz"
    ],
    "inputDrvs": {
      "/nix/store/...-bash-5.1.drv": ["out"],
      "/nix/store/...-gcc-11.3.0.drv": ["out"]
    },
    "system": "x86_64-linux",
    "builder": "/nix/store/...-bash-5.1/bin/bash",
    "args": ["-e", "/nix/store/...-builder.sh"],
    "env": {
      "name": "hello-2.10",
      "src": "/nix/store/...-hello-2.10.tar.gz",
      "buildInputs": "..."
    }
  }
}
```

### Key Derivation Properties

1. **Inputs determine output** - Same inputs = same output hash
2. **Hermetic** - No access to network, filesystem outside /nix/store
3. **Reproducible** - Build again, get same hash
4. **Cacheable** - Hash lookup in binary caches

### Viewing Derivations

```bash
# Show derivation for a package
nix derivation show nixpkgs#python3

# Show derivation path
nix-instantiate '<nixpkgs>' -A python3

# Show runtime dependencies
nix-store -q --tree /nix/store/...-python3-3.10.12

# Show build-time dependencies
nix-store -qR $(nix-instantiate '<nixpkgs>' -A python3)
```

---

## The Nix Store

### Structure

The Nix store (`/nix/store`) is an **immutable** directory where all packages live:

```
/nix/store/
├── 1v3d2qj7k6vvkr7mprqnlk4p4yyk2r7d-python3-3.10.12/
│   ├── bin/
│   │   ├── python3
│   │   └── pip3
│   ├── lib/
│   │   └── python3.10/
│   └── share/
├── abc123...-hello-2.10.drv         # Derivation file
├── abc123...-hello-2.10/             # Built package
│   └── bin/
│       └── hello
└── xyz789...-gcc-11.3.0/
    └── ...
```

### Store Properties

1. **Immutable** - Files never modified after creation
2. **Content-addressed** - Hash in path identifies contents
3. **Atomic** - Builds either complete or don't exist
4. **Garbage-collectible** - Unused paths can be deleted safely

### Store Operations

```bash
# Query store path
nix-store -q /nix/store/...-python3

# Show dependencies
nix-store -q --references /nix/store/...-python3

# Show reverse dependencies (what depends on this)
nix-store -q --referrers /nix/store/...-python3

# Verify store integrity
nix-store --verify --check-contents

# Optimize store (hardlink duplicates)
nix-store --optimise
```

### Store Database

Nix maintains a SQLite database of store paths:

```bash
# Location
/nix/var/nix/db/db.sqlite

# Contains:
# - All store paths
# - Dependency relationships
# - GC roots
# - Binary cache info
```

---

## Evaluation Model

### Lazy Evaluation

Nix is **lazily evaluated** - expressions are only evaluated when their values are needed:

```nix
let
  expensive = import ./huge-calculation.nix;  # Not evaluated yet
  result = expensive.someAttribute;            # Only evaluates what's needed
in
  result
```

### Evaluation Phases

1. **Parse** - Read `.nix` files into AST
2. **Evaluate** - Reduce expressions to values
3. **Instantiate** - Convert values to derivations (.drv)
4. **Realise** - Build derivations to store paths

```bash
# Just parse (check syntax)
nix-instantiate --parse file.nix

# Evaluate to value
nix-instantiate --eval file.nix

# Instantiate to .drv
nix-instantiate file.nix

# Realize (build)
nix-build file.nix
```

### Pure Functional Language

Nix expressions are **pure functions**:

```nix
# Pure - always returns same result
{ pkgs }:
  pkgs.python3.withPackages (ps: [ ps.requests ps.flask ])

# Impure - depends on external state (not allowed in derivations)
builtins.readFile /etc/hostname  # Error in restricted mode
```

### Evaluation Context

**During evaluation**, Nix has:
- ✅ Access to all `.nix` files
- ✅ Ability to import other modules
- ✅ Builtin functions (map, filter, etc.)
- ❌ No network access
- ❌ No arbitrary filesystem access
- ❌ No side effects

**During build** (in sandbox), Nix has:
- ✅ Access to declared inputs in `/nix/store`
- ✅ Isolated temp directory
- ✅ Declared environment variables
- ❌ No network (except fixed-output derivations)
- ❌ No access to `/nix/store` outside inputs
- ❌ No access to home directory, `/tmp`, etc.

---

## Build Process

### From Expression to Store Path

1. **Write Nix expression**
   ```nix
   { pkgs }: pkgs.stdenv.mkDerivation {
     name = "hello";
     src = ./src;
     buildPhase = "gcc hello.c -o hello";
     installPhase = "mkdir -p $out/bin; cp hello $out/bin/";
   }
   ```

2. **Evaluation** - Nix evaluates to derivation
   ```bash
   nix-instantiate hello.nix
   # Output: /nix/store/abc123...-hello.drv
   ```

3. **Realisation** - Nix builds derivation
   ```bash
   nix-build hello.nix
   # Output: /nix/store/xyz789...-hello
   ```

### Build Sandbox

Every build runs in an **isolated sandbox**:

- **Isolated filesystem** - Only sees `/nix/store` inputs
- **Isolated network** - No network access (except FODs)
- **Isolated process tree** - No access to other processes
- **Clean environment** - Only declared env vars

```bash
# Check sandbox status
nix show-config | grep sandbox

# Build with sandbox explicitly enabled
nix-build --option sandbox true hello.nix
```

### Build Phases

Standard build phases (from `stdenv.mkDerivation`):

1. **unpackPhase** - Extract source tarball
2. **patchPhase** - Apply patches
3. **configurePhase** - Run `./configure`
4. **buildPhase** - Run `make`
5. **checkPhase** - Run `make check` (optional)
6. **installPhase** - Copy outputs to `$out`
7. **fixupPhase** - Patch shebangs, strip binaries

### Build Environment

```bash
# During build, these are set:
$out         # Output path (e.g., /nix/store/xyz789...-hello)
$src         # Source path
$buildInputs # List of dependencies
$NIX_BUILD_CORES  # CPU cores available
$NIX_BUILD_TOP    # Build directory
```

---

## Binary Caches

### What is a Binary Cache?

A **binary cache** stores pre-built derivations so you don't have to build locally:

```
Your Computer                     Binary Cache (cache.nixos.org)
     │                                      │
     │ 1. Request /nix/store/abc123...-hello
     ├─────────────────────────────────────>│
     │                                      │
     │ 2. Send .nar.xz (compressed package) │
     │<─────────────────────────────────────┤
     │                                      │
     │ 3. Extract to /nix/store             │
     └──────────────────────────────────────
```

### How It Works

1. **Hash lookup** - Nix computes derivation hash
2. **Cache query** - Checks if binary exists in cache
3. **Download** - If found, download and extract
4. **Build** - If not found, build locally

### Configure Binary Caches

```nix
# In nix.settings
nix.settings = {
  substituters = [
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
  ];
  trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];
};
```

### Binary Cache Operations

```bash
# Query if path is in cache
nix path-info --store https://cache.nixos.org /nix/store/...-hello

# Build without using caches
nix-build --option substitute false hello.nix

# Push to cachix
cachix push my-cache /nix/store/...-hello
```

### NAR Format

Binary caches store packages as **NAR** (Nix ARchive) files:

- `.nar` - Uncompressed archive
- `.nar.xz` - XZ-compressed (most common)
- `.nar.zst` - Zstandard-compressed (faster)

```bash
# Create NAR from store path
nix-store --export /nix/store/...-hello > hello.nar

# Import NAR
nix-store --import < hello.nar
```

---

## Garbage Collection

### GC Roots

**GC roots** prevent paths from being deleted:

```
GC Root → Derivation → Dependencies → ... → Leaf packages
```

Types of roots:
- **User profiles** - `~/.nix-profile`
- **System profiles** - `/nix/var/nix/profiles/system`
- **Result symlinks** - `./result` from nix-build
- **Explicit roots** - `/nix/var/nix/gcroots/`

### Garbage Collection Process

```bash
# Find unreachable paths
nix-store --gc --print-dead

# Delete unreachable paths
nix-store --gc

# Delete old generations
nix-collect-garbage --delete-older-than 30d

# Delete everything not currently in use
nix-collect-garbage -d
```

### How GC Works

1. **Find roots** - Start from GC roots
2. **Trace dependencies** - Follow all references
3. **Mark live paths** - Anything reachable is kept
4. **Sweep dead paths** - Delete unreachable paths

### Viewing GC Roots

```bash
# List all GC roots
ls -l /nix/var/nix/gcroots/

# Find roots for a store path
nix-store -q --roots /nix/store/...-python3

# Add a GC root manually
nix-store --add-root /nix/var/nix/gcroots/my-root /nix/store/...-hello
```

---

## Fixed-Output Derivations

### What are FODs?

**Fixed-Output Derivations** are special derivations that:
- Have network access during build
- Declare expected output hash upfront
- Used for fetching sources (git, tarballs, etc.)

### Why FODs are Special

Normal derivations:
- ❌ No network access
- ✅ Hash derived from inputs

Fixed-output derivations:
- ✅ Network access allowed
- ✅ Hash declared explicitly
- ✅ Nix verifies output matches hash

### Example FOD

```nix
{ pkgs }:
pkgs.fetchurl {
  url = "https://example.com/hello-1.0.tar.gz";
  sha256 = "abc123...";  # Expected hash
}
```

### Creating FODs

```nix
# fetchurl
pkgs.fetchurl {
  url = "...";
  sha256 = "...";
}

# fetchgit
pkgs.fetchgit {
  url = "...";
  rev = "...";
  sha256 = "...";
}

# fetchFromGitHub
pkgs.fetchFromGitHub {
  owner = "...";
  repo = "...";
  rev = "...";
  sha256 = "...";
}
```

### Getting Hashes

```bash
# Fetch and compute hash
nix-prefetch-url https://example.com/file.tar.gz

# Fetch git and compute hash
nix-prefetch-git https://github.com/user/repo

# Use fakeSha256, build will fail with correct hash
sha256 = pkgs.lib.fakeSha256;
```

---

## Quick Reference

### Common Commands

```bash
# Store operations
nix-store -q --tree /nix/store/...-pkg      # Show dependency tree
nix-store -q --references /nix/store/...-pkg  # List direct dependencies
nix-store --verify --check-contents         # Verify store integrity

# Derivation operations
nix derivation show nixpkgs#hello           # Show derivation
nix-instantiate '<nixpkgs>' -A hello        # Build .drv file
nix-build '<nixpkgs>' -A hello              # Build package

# Evaluation
nix eval nixpkgs#hello.name                 # Evaluate attribute
nix-instantiate --eval '<nixpkgs>' -A hello.name

# Garbage collection
nix-collect-garbage                         # Delete unreachable paths
nix-collect-garbage -d                      # Delete old profiles too
nix-store --gc --print-roots               # Show all GC roots

# Binary caches
nix path-info --store https://cache.nixos.org /nix/store/...-pkg
nix copy --to https://my-cache.com /nix/store/...-pkg
```

### Key File Locations

```
/nix/store/                         # All packages
/nix/var/nix/profiles/              # User/system profiles
/nix/var/nix/gcroots/               # GC roots
/nix/var/nix/db/db.sqlite          # Store database
~/.nix-profile                      # User profile (symlink)
/run/current-system                 # Current system (NixOS/Darwin)
```

### Environment Variables

```bash
NIX_PATH="nixpkgs=/path/to/nixpkgs"     # Search path for <nixpkgs>
NIX_STORE_DIR="/nix/store"              # Store location (usually default)
NIX_BUILD_CORES=8                       # Parallel build jobs
```

---

## Related Documentation

- [Structure Guide](../architecture/structure.md) - Modular configuration explained
- [Design Doc](../architecture/design.md) - Overall architecture and roadmap
- [CLI Commands](./cli-commands.md) - Common Nix commands
- [Modules Reference](./modules-reference.md) - All modules documented
- [Troubleshooting](./troubleshooting.md) - Common issues and solutions

---

## External References

- [Nix Manual](https://nixos.org/manual/nix/stable/) - Official Nix documentation
- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/) - Package repository guide
- [Nix Pills](https://nixos.org/guides/nix-pills/) - In-depth Nix tutorial series
- [NixOS Wiki - Store](https://nixos.wiki/wiki/Nix_store) - Store documentation
- [Derivation Format](https://nixos.org/manual/nix/stable/language/derivations.html) - Derivation specification

---

**Next:** [CLI Commands Reference](./cli-commands.md) - Learn common Nix commands
