# WikiGen's Config Documentation Site

This directory contains the Starlight documentation site for WikiGen's Nix configuration.

## Quick Start

### Using Nix (Recommended)

The easiest way to work with the documentation is using the Nix flake:

```bash
# Enter the documentation development shell
nix develop .#docs

# Or run commands directly via Nix apps
nix run .#starlight-dev      # Start dev server
nix run .#starlight-build    # Build static site
nix run .#starlight-preview  # Preview built site
```

### Using pnpm Directly

If you prefer to use pnpm directly:

```bash
cd site

# Install dependencies
pnpm install

# Start development server
pnpm dev

# Build for production
pnpm build

# Preview production build
pnpm preview
```

## Structure

- `src/content/docs/` - Documentation content (auto-generated from `../docs/`)
- `src/styles/` - Custom CSS styles
- `astro.config.mjs` - Starlight configuration
- `public/` - Static assets (images, favicons, etc.)

## Configuration

The site uses the `starlight-obsidian` plugin to automatically convert markdown files from the `../docs/` directory into Starlight pages. The sidebar is organized into:

- Getting Started
- Guides (Development, Deployment, Hardware Security, Secrets Management)
- Architecture
- Reference

Edit the `astro.config.mjs` file to customize the sidebar structure or add additional Starlight plugins.
