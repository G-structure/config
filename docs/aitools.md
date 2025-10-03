# Nixifying Global npm CLIs: Complete Guide

A comprehensive guide to packaging and managing global npm CLI tools (Claude Code, Gemini, OpenAI Codex, Slate) with Nix for reproducible, offline, and fast installation across devShells, NixOS, and nix-darwin.

---

## Contents

* [TL;DR](#tldr)
* [Why Switch from npm install -g in shellHook](#why-switch-from-npm-install--g-in-shellhook)
* [Option A: Aggregate with npmlock2nix (Recommended)](#option-a-aggregate-with-npmlock2nix-recommended)
* [Option B: buildNpmPackage per CLI (Most Explicit)](#option-b-buildnpmpackage-per-cli-most-explicit)
* [Option C: Yarn Berry + yarn-plugin-nixify](#option-c-yarn-berry--yarn-plugin-nixify)
* [Removing the Old shellHook Logic](#removing-the-old-shellhook-logic)
* [Optional: One-shot Latest Without Giving Up Purity](#optional-one-shot-latest-without-giving-up-purity)
* [Optional: Auto-bump Workflow](#optional-auto-bump-workflow)
* [Decision Guide: Which Option Should You Choose](#decision-guide-which-option-should-you-choose)

---

## TL;DR

Your current shellHook installs/updates global npm CLIs (Claude Code, Gemini, OpenAI Codex, Slate) at login time. That's impure, slow, and non-reproducible. Replace it with:

1. **Reproducible packaging in Nix** (pin versions + hashes)
2. **Expose binaries in PATH** from the flake (devShell + NixOS + nix-darwin)
3. **One command to bump** versions when you want ("latest" is treated as an explicit, audited update)

Everything below gives you two **first-class** ways to do it: `buildNpmPackage` (explicit/pure per-package) and `npmlock2nix` (aggregate lockfile-driven).

**References:**
- [NixOS Wiki — Node.js](https://nixos.wiki/wiki/Node.js)
- [npmlock2nix](https://github.com/nix-community/npmlock2nix)
- [node2nix](https://github.com/svanderburg/node2nix)
- [yarn-plugin-nixify](https://github.com/cachix/yarn-plugin-nixify)
- [nvfetcher](https://digga.divnix.com/integrations/nvfetcher.html)
- [dream2nix](https://github.com/nix-community/dream2nix)

---

## Why Switch from npm install -g in shellHook

**Determinism**
- Get byte-for-byte reproducible CLIs pinned to explicit versions + hashes
- Not whatever "latest" happens to be today
- Reference: [NixOS Wiki — Node.js](https://nixos.wiki/wiki/Node.js)

**Speed & CI caching**
- Nix builds once and caches
- No per-shell "npm update" churn
- Reference: [npmlock2nix](https://github.com/nix-community/npmlock2nix)

**Security posture**
- Review lockfile or tarball hashes in PRs
- Supply-chain drift (transitives) can't silently land
- Reference: [node2nix](https://github.com/svanderburg/node2nix)

---

## Option A: Aggregate with npmlock2nix (Recommended)

**Model:** Put all your JS CLIs into one tiny `tools/js` project, commit `package.json` + `package-lock.json`, and let `npmlock2nix` build a hermetic tool bundle whose `node_modules/.bin` is exported to `$out/bin`.

Reference: [npmlock2nix](https://github.com/nix-community/npmlock2nix)

### 1) Create the aggregator project

Create `tools/js/package.json` (pin exact versions you trust):

```json
{
  "name": "ai-cli-bundle",
  "private": true,
  "version": "1.0.0",
  "dependencies": {
    "@anthropic-ai/claude-code": "X.Y.Z",
    "@google/gemini-cli": "A.B.C",
    "@openai/codex": "P.Q.R",
    "@randomlabs/slatecli": "U.V.W"
  }
}
```

Then run `npm install` once to produce `package-lock.json` (commit it).

Reference: [npmlock2nix](https://github.com/nix-community/npmlock2nix)

### 2) Wire it into your flake

Add this to your flake's `outputs` (for each system):

```nix
{ pkgs, ... }:
let
  nm = pkgs.npmlock2nix;  # provided by nixpkgs
in {
  packages.ai-clis = pkgs.stdenvNoCC.mkDerivation {
    pname = "ai-clis";
    version = "1";
    src = ./tools/js;
    # Build node_modules from the lockfile (offline, reproducible)
    installPhase = ''
      mkdir -p $out
      # Create node_modules via npmlock2nix
      NODE_PATH=$(pwd)
      ${nm.build { src = ./tools/js; }} # produces a closure with node_modules
      # Expose all CLI binaries
      mkdir -p $out/bin
      cp -r node_modules $out/node_modules
      for b in $out/node_modules/.bin/*; do
        ln -s "$b" "$out/bin/$(basename "$b")"
      done
    '';
    meta.description = "Bundle of pinned npm CLIs (Claude Code, Gemini, Codex, Slate)";
  };
}
```

Now your devShells, NixOS, and nix-darwin configs can simply include `pkgs.ai-clis` to get `claude`, `gemini`, `codex`, `slate` (whatever the CLIs expose) on PATH.

Reference: [npmlock2nix](https://github.com/nix-community/npmlock2nix)

### 3) Use it everywhere (no shellHook installs)

**devShell:**
```nix
packages = with pkgs; [ nodejs_20 ai-clis ];
```

**NixOS:**
```nix
environment.systemPackages = [ pkgs.ai-clis ];
```

**nix-darwin / home-manager:**
Add the same to your user packages.

Reference: [NixOS Wiki — Node.js](https://nixos.wiki/wiki/Node.js)

### 4) Updating CLIs (explicit, auditable)

To bump a tool:
- Edit `package.json` (or run `npm install @anthropic-ai/claude-code@newver`)
- This rewrites the lockfile
- Commit the diff
- Build with `nix build .#ai-clis`

You can automate bumps (optional) with `nvfetcher` or a small script that runs `npm view <pkg> version`, updates the lock, commits, then lets Nix rebuild.

Reference: [nvfetcher](https://digga.divnix.com/integrations/nvfetcher.html)

**Pros:**
- One derivation, one lockfile
- Easiest to reason about
- Bins show up in PATH
- Works cross-platform

**Trade-off:**
If you prefer not to keep a lockfile in-repo, see Option B.

Reference: [npmlock2nix](https://github.com/nix-community/npmlock2nix)

---

## Option B: buildNpmPackage per CLI (Most Explicit)

**Model:** Package each CLI as its own Nix derivation with pinned version and hashes. Great for surgical control and for exposing each tool as a named flake output.

Reference: [NixOS Wiki — Node.js](https://nixos.wiki/wiki/Node.js)

### 1) Overlay with a helper

```nix
# overlays/js-clis.nix
{ lib, pkgs, ... }:
let
  mkNpmCli = { npmName, pname ? (builtins.replaceStrings ["@","/"] ["","-"] npmName), version, sha256, npmDepsHash ? lib.fakeHash }:
    pkgs.buildNpmPackage {
      inherit pname version;
      src = pkgs.fetchurl {
        # npm registry tarball URL; scoped packages are URL-escaped
        url = let
          esc = builtins.replaceStrings ["/"] ["%2f"] npmName;
          base = builtins.tail (builtins.split "/" npmName); # last path segment
          baseName = if builtins.length base > 0 then builtins.elemAt base 0 else npmName;
        in "https://registry.npmjs.org/${esc}/-/${baseName}-${version}.tgz";
        sha256 = sha256;
      };
      # Build offline with vendored deps; set to lib.fakeHash once to learn the right value from the build log.
      npmDepsHash = npmDepsHash;
      dontNpmBuild = true;
      # Make sure node is available at runtime for bin scripts with `env node`
      makeWrapperArgs = [ "--prefix" "PATH" ":" "${pkgs.nodejs_20}/bin" ];
      meta.description = "Pinned CLI ${npmName} via buildNpmPackage";
    };
in {
  claude-code = mkNpmCli {
    npmName = "@anthropic-ai/claude-code";  version = "X.Y.Z";
    sha256 = "sha256-…";  npmDepsHash = "sha256-…";
  };
  gemini-cli = mkNpmCli {
    npmName = "@google/gemini-cli";         version = "A.B.C";
    sha256 = "sha256-…";  npmDepsHash = "sha256-…";
  };
  codex = mkNpmCli {
    npmName = "@openai/codex";              version = "P.Q.R";
    sha256 = "sha256-…";  npmDepsHash = "sha256-…";
  };
  slatecli = mkNpmCli {
    npmName = "@randomlabs/slatecli";       version = "U.V.W";
    sha256 = "sha256-…";  npmDepsHash = "sha256-…";
  };
}
```

### 2) Add to your flake

Add the overlay to your flake and expose a convenient bundle:

```nix
# flake.nix (excerpt)
overlays = [ (import ./overlays/js-clis.nix) ];
outputs = { self, nixpkgs, ... }:
let
  forAll = f: nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-darwin" ] (system: f (import nixpkgs { inherit system overlays; }));
in {
  packages = forAll (pkgs: {
    ai-clis = pkgs.symlinkJoin {
      name = "ai-clis";
      paths = [ pkgs.claude-code pkgs.gemini-cli pkgs.codex pkgs.slatecli ];
    };
  });
  devShells = forAll (pkgs: {
    default = pkgs.mkShell { packages = [ pkgs.nodejs_20 pkgs.ai-clis ]; };
  });
};
```

### 3) Fill the hashes

Set `npmDepsHash = lib.fakeHash` and run `nix build .#claude-code`. Nix will print the **actual** `sha256-…` it expected; paste that in and rebuild. Repeat when bumping `version`.

Reference: [NixOS Wiki — Node.js](https://nixos.wiki/wiki/Node.js)

**Pros:**
- Max control
- No lockfile needed
- Fine-grained review per CLI

**Trade-off:**
You update hashes per package when versions change.

Reference: [NixOS Wiki — Node.js](https://nixos.wiki/wiki/Node.js)

---

## Option C: Yarn Berry + yarn-plugin-nixify

If your toolchain already uses Yarn PnP/Berry, add `yarn-plugin-nixify` to your repo; it will **generate Nix expressions straight from your Yarn lockfile**, so your CLIs appear as Nix packages without bespoke overlays.

Run `yarn plugin import nixify` then commit the generated files and add the outputs to your flake.

Reference: [yarn-plugin-nixify](https://github.com/cachix/yarn-plugin-nixify)

---

## Removing the Old shellHook Logic

Delete the imperative block:

```bash
export NPM_CONFIG_PREFIX=$PWD/.npm-global
npm install -g @openai/codex @anthropic-ai/claude-code @google/gemini-cli @randomlabs/slatecli
npm update  -g @openai/codex @anthropic-ai/claude-code @google/gemini-cli @randomlabs/slatecli
```

Replace it with `packages = [ pkgs.nodejs_20 pkgs.ai-clis ];` in each shell/system that needs the tools. Now login is O(0) and reproducible.

Reference: [NixOS Wiki — Node.js](https://nixos.wiki/wiki/Node.js)

---

## Optional: One-shot Latest Without Giving Up Purity

You can keep a **separate command** to explore "latest" before pinning:

```bash
nix shell nixpkgs#nodejs_20 --command npx -y @anthropic-ai/claude-code@latest --help
```

If you decide to keep it, bump your `package.json`/overlay version and commit.

Reference: [NixOS Wiki — Node.js](https://nixos.wiki/wiki/Node.js)

---

## Optional: Auto-bump Workflow

If you like automated PRs:

Use **nvfetcher** or a tiny script that:
1. Checks `npm view <name> version`
2. Rewrites either `package.json` (Option A) or the attrset version (Option B)
3. Runs a no-network `nix build` to get the new hash
4. Updates the file
5. Opens a PR

References:
- [nvfetcher](https://digga.divnix.com/integrations/nvfetcher.html)
- [dream2nix](https://github.com/nix-community/dream2nix)

---

## Decision Guide: Which Option Should You Choose

### Quick Decision Tree

**Choose Option A (npmlock2nix) if:**
- You have many CLIs with low ceremony
- You want one lockfile, one package, fastest day-2 ops
- Reference: [npmlock2nix](https://github.com/nix-community/npmlock2nix)

**Choose Option B (buildNpmPackage) if:**
- You want surgical control / per-CLI review
- You prefer explicit versions & hashes per tool
- Reference: [NixOS Wiki — Node.js](https://nixos.wiki/wiki/Node.js)

**Choose Option C (yarn-plugin-nixify) if:**
- You're already using Yarn Berry
- You want Yarn to generate the Nix expressions
- Reference: [yarn-plugin-nixify](https://github.com/cachix/yarn-plugin-nixify)

### Bottom Line

Either way, your devShells, NixOS, and nix-darwin configs just depend on **packages you build in Nix**, not on at-login networked installs. That's faster, safer, and fits the rest of your flake.

Reference: [NixOS Wiki — Node.js](https://nixos.wiki/wiki/Node.js)
