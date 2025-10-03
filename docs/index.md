---
title: WikiGen's Nix Configuration
description: Modular multi-platform Nix configuration for macOS, NixOS, and cloud deployments
---

# WikiGen's Nix Configuration

A modern, modular Nix configuration supporting **macOS (nix-darwin)**, **NixOS**, and **cloud platforms** with hardware security integration.

## Features

- **Multi-Platform**: Unified configuration for macOS (nix-darwin), NixOS, and cloud platforms (EC2, GCE)
- **Hardware Security**: Integrated Ledger hardware wallet support for SSH authentication and GPG signing
- **Modular Design**: Clean separation of concerns with modules, profiles, and overlays
- **Secrets Management**: Secure secrets handling with SOPS-nix integration
- **Developer Tools**: Comprehensive development environment with cloud CLIs and AI tools
- **Reproducible**: Fully declarative and reproducible system configuration

## Quick Start

New to this config? Start with the [Quickstart Guide](getting-started/quickstart.md)

## Documentation

- [Getting Started](getting-started/) - Installation and first steps
- [Architecture](architecture/) - Design and structure
- [Guides](guides/) - How-to guides for specific tasks
- [Reference](reference/) - Technical references

## Quick Links

- [Installation Guide](getting-started/installation.md)
- [Architecture Overview](architecture/structure.md)
- [Hardware Security Setup](guides/hardware-security/ledger-overview.md)
- [Development Guide](guides/development/adding-packages.md)

---

This configuration showcases modern Nix best practices including **flake-parts** for better organization, **Home Manager** for user-level configuration, modular architecture for easy customization, cloud-ready infrastructure as code, and hardware security for cryptographic operations.
