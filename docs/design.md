# Nix + Containers + Cloud: Wiki Notes

A comprehensive, Nix-first playbook for managing macOS (nix-darwin), Linux/NixOS, OCI images, Kubernetes manifests, and cloud infrastructure (AWS EC2 + GCP N2/GCE) — with reproducibility, GitOps, and secrets baked in.

---

## Contents

* [Goals & Principles](#goals--principles)
* [Repository Structure](#repository-structure)
* [Flake Skeleton (Darwin + NixOS + Cloud)](#flake-skeleton-darwin--nixos--cloud)
* [Flake Outputs: What We Export](#flake-outputs-what-we-export)
* [Cross-Platform Common Module](#cross-platform-common-module)
* [macOS (nix-darwin) Setup](#macos-nix-darwin-setup)

  * [Why Colima on macOS](#why-colima-on-macos)
  * [Declarative Colima autostart](#declarative-colima-autostart)
  * [Home-Manager complements](#home-manager-complements)
* [Linux/NixOS Setup](#linuxnixos-setup)

  * [Docker vs Podman on Linux](#docker-vs-podman-on-linux)
  * [NixOS modules for Docker](#nixos-modules-for-docker)
  * [NixOS modules for Podman](#nixos-modules-for-podman)
  * [Impermanence (ephemeral root, persistent state)](#impermanence-ephemeral-root-persistent-state)
* [OCI Images via Nix](#oci-images-via-nix)

  * [Build with dockerTools](#build-with-dockertools)
  * [Daemonless publish with Skopeo](#daemonless-publish-with-skopeo)
  * [Multi-arch strategy](#multi-arch-strategy)
* [Language Packaging Patterns](#language-packaging-patterns)

  * [Go with gomod2nix](#go-with-gomod2nix)
  * [Python with poetry2nix/uv2nix](#python-with-poetry2nixuv2nix)
  * [Node with pnpm](#node-with-pnpm)
  * [Rust with crate2nix or fenix](#rust-with-crate2nix-or-fenix)
* [Kubernetes Manifests as Nix](#kubernetes-manifests-as-nix)

  * [Kubenix pattern](#kubenix-pattern)
  * [Local Kubernetes (macOS & Linux)](#local-kubernetes-macos--linux)
* [GitOps (Flux/Argo) and Helm](#gitops-fluxargo-and-helm)
* [Cloud Infra as Nix → Terraform (Terranix)](#cloud-infra-as-nix--terraform-terranix)
* [EC2 (AWS) Image Role & Boot Settings](#ec2-aws-image-role--boot-settings)
* [GCE (GCP N2) Image Role & Boot Settings](#gce-gcp-n2-image-role--boot-settings)
* [Secrets & Policy (sops-nix + age/KMS)](#secrets--policy-sops-nix--agekms)
* [Provisioning & Fleet Mgmt](#provisioning--fleet-mgmt)
* [Binary Caches, Remote Builds, and CI Speed](#binary-caches-remote-builds-and-ci-speed)
* [CI/CD Pipeline Sketch](#cicd-pipeline-sketch)
* [Observability & Cost Awareness](#observability--cost-awareness)
* [Security Baseline](#security-baseline)
* [Testing & Health Checks](#testing--health-checks)
* [Troubleshooting & Gotchas](#troubleshooting--gotchas)
* [Cross-Cloud Deltas (AWS ↔︎ GCP)](#cross-cloud-deltas-aws--gcp)
* [Decision Matrix](#decision-matrix)
* [FAQ](#faq)

---

## Goals & Principles

* **Single source of truth:** Hosts, images, manifests, and infra all derive from one flake + lockfile.
* **Reproducible builds:** Content-addressed derivations; deterministic containers; easy rollbacks.
* **Declarative everything:** nix-darwin/NixOS modules, Kubenix manifests, Terranix → Terraform, Colima startup policies.
* **Secrets safe by default:** sops-nix + age or cloud KMS; no secrets in the Nix store.
* **Portable dev:** macOS via Colima; Linux via Docker or Podman; images always built with Nix, not ad-hoc Dockerfiles.
* **GitOps first:** Flux or Argo drives cluster state from Git; CI only builds/pushes artifacts and updates refs.

---

## Repository Structure

```
.
├─ flake.nix
├─ flake.lock
├─ nix/
│  ├─ overlays/                    # per-language and tool overlays
│  │  └─ cloud-tools.nix
│  ├─ modules/
│  │  ├─ common.nix
│  │  ├─ linux-base.nix
│  │  ├─ darwin-base.nix
│  │  ├─ darwin/colima.nix
│  │  ├─ linux/docker.nix
│  │  ├─ linux/podman.nix
│  │  ├─ cloud/
│  │  │  ├─ ec2-base.nix
│  │  │  ├─ gce-base.nix
│  │  │  └─ impermanence.nix
│  │  └─ secrets/sops.nix
│  ├─ profiles/
│  │  ├─ cloud-cli.nix
│  │  ├─ developer.nix
│  │  └─ server-base.nix
│  └─ tests/                       # NixOS VM tests
│     ├─ ec2-boot.nix
│     ├─ gce-boot.nix
│     └─ k3s.nix
├─ hosts/
│  ├─ macbook-pro.nix
│  ├─ nixos-laptop.nix
│  ├─ ec2-image.nix
│  └─ gce-image.nix
├─ images/                         # Nix-built OCI images
│  ├─ api.nix
│  ├─ gateway.nix
│  └─ operator.nix
├─ k8s/                            # Kubenix/Helm templates
│  ├─ base/
│  │  ├─ traefik.nix
│  │  ├─ externaldns.nix
│  │  └─ cert-manager.nix
│  └─ apps/
│     ├─ api-deploy.nix
│     └─ ray-vllm.nix
├─ infra/
│  ├─ terranix-aws.nix
│  └─ terranix-gcp.nix
├─ pkgs/                           # in-house packages (optional)
│  └─ default.nix
├─ home/
│  └─ users/yourname.nix
├─ charts/                         # Helm charts (if using Helm+Flux)
│  └─ api/
├─ flux/                           # Flux GitOps
│  ├─ gitrepository.yaml
│  └─ helmrelease-api.yaml
└─ .pre-commit-config.yaml
```

---

## Flake Skeleton (Darwin + NixOS + Cloud)

```nix
{
  description = "Mac + NixOS + Cloud (AWS EC2 + GCP N2/GCE) — Nix-first monorepo";

  inputs = {
    nixpkgs.url          = "github:NixOS/nixpkgs/nixos-24.05";
    unstable.url         = "github:NixOS/nixpkgs/nixos-unstable";
    darwin.url           = "github:LnL7/nix-darwin";
    home-manager.url     = "github:nix-community/home-manager";
    sops-nix.url         = "github:Mic92/sops-nix";
    impermanence.url     = "github:nix-community/impermanence";
    nixos-generators.url = "github:nix-community/nixos-generators";
    kubenix.url          = "github:hall/kubenix";
    terranix.url         = "github:terranix/terranix";
    flake-parts.url      = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, nixpkgs, unstable, darwin, home-manager
                   , sops-nix, impermanence, nixos-generators, kubenix
                   , terranix, flake-parts, ... }:
  flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];

    perSystem = { system, ... }:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            awscli2   = unstable.legacyPackages.${system}.awscli2;
            gcloud    = unstable.legacyPackages.${system}.google-cloud-sdk;
            kubectl   = unstable.legacyPackages.${system}.kubectl;
            terraform = unstable.legacyPackages.${system}.terraform;
            ssm-plugin= unstable.legacyPackages.${system}.session-manager-plugin;
            alejandra = unstable.legacyPackages.${system}.alejandra;
          })
        ];
        config.allowUnfree = true;
      };
    in {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          git direnv nix-direnv
          awscli2 gcloud kubectl terraform sops age
          jq yq skopeo cosign
          alejandra
        ];
        shellHook = ''
          echo "Use direnv: allow"
        '';
      };

      # Example OCI image exports (see images/*.nix)
      packages.api-image = import ./images/api.nix { inherit pkgs self system; };

      apps.fmt = {
        type = "app";
        program = "${pkgs.alejandra}/bin/alejandra";
      };
    };

    flake = {
      darwinConfigurations.macbook-pro = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./nix/modules/darwin-base.nix
          ./nix/modules/common.nix
          ./nix/profiles/cloud-cli.nix
          ./nix/modules/darwin/colima.nix
          home-manager.darwinModules.home-manager
          { home-manager.users.yourname = import ./home/users/yourname.nix; }
        ];
        specialArgs = { inherit sops-nix; };
      };

      nixosConfigurations.nixos-laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./nix/modules/linux-base.nix
          ./nix/modules/common.nix
          ./nix/profiles/developer.nix
          ./nix/modules/linux/docker.nix   # or linux/podman.nix
          home-manager.nixosModules.home-manager
          { home-manager.users.yourname = import ./home/users/yourname.nix; }
        ];
        specialArgs = { inherit sops-nix impermanence; };
      };

      # Cloud images (buildable in CI)
      packages.x86_64-linux.ec2Image =
        nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          format = "amazon";
          modules = [ ./hosts/ec2-image.nix ];
        };

      packages.x86_64-linux.gceImage =
        nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          format = "gce";
          modules = [ ./hosts/gce-image.nix ];
        };
    };
  };
}
```

---

## Flake Outputs: What We Export

* **`devShells`**: per-platform shells with pinned toolchains (awscli2, gcloud, kubectl, terraform, sops, age, skopeo, cosign).
* **`packages`**: Nix-built **OCI images**, language binaries, test runners.
* **`apps`**: utility entrypoints (`fmt`, `lint`, `ci`, `deploy`).
* **`nixosConfigurations`**: laptops, servers, cloud images.
* **`darwinConfigurations`**: macOS machines (M-series).
* **Terraform via Terranix**: plan/apply directories produced by `nix build`.

---

## Cross-Platform Common Module

```nix
# nix/modules/common.nix
{ lib, pkgs, ... }:
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    warn-dirty = false;
    trusted-users = [ "root" "yourname" ];
    substituters = [
      "https://cache.nixos.org"
      "https://your-cachix.cachix.org"
    ];
    trusted-public-keys = [
      "your-cachix.cachix.org-1:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  programs.git.enable = true;
  environment.sessionVariables = {
    EDITOR = "nvim";   # or your choice
    PAGER  = "less -SR";
  };

  # Optional: nix-ld to run foreign dynamic binaries without glibc errors
  programs.nix-ld.enable = true;
}
```

---

## macOS (nix-darwin) Setup

### Why Colima on macOS

* **Fully declarative** via nix-darwin.
* **Docker-compatible** runtime without Docker Desktop.
* **Apple Silicon** friendly (`vz` hypervisor; optional Rosetta).
* **System-managed** autostart via LaunchAgents, no clicking GUIs.

### Declarative Colima autostart

```nix
# nix/modules/darwin/colima.nix
{ pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [
    colima docker docker-compose kubectl skopeo kind k3d
  ];

  launchd.user.agents."colima.default" = {
    command = lib.concatStringsSep " " [
      "${pkgs.colima}/bin/colima" "start" "--foreground"
      "--runtime" "docker" "--cpu" "4" "--memory" "8" "--disk" "80"
      "--vm-type" "vz" "--vz-rosetta"
    ];
    serviceConfig = { KeepAlive = true; RunAtLoad = true; ProcessType = "Background"; };
  };
}
```

### Home-Manager complements

```nix
# home/users/yourname.nix (excerpt)
{ config, pkgs, ... }:
{
  home.packages = with pkgs; [ direnv nix-direnv aws-vault gnupg ];
  programs.direnv.enable = true; programs.direnv.nix-direnv.enable = true;

  home.file.".docker/cli-plugins/docker-compose".source =
    "${pkgs.docker-compose}/bin/docker-compose";

  home.sessionVariables.DOCKER_HOST =
    "unix://${config.home.homeDirectory}/.colima/default/docker.sock";

  # If Colima started with --kubernetes
  home.sessionVariables.KUBECONFIG =
    "${config.home.homeDirectory}/.colima/default/kubeconfig";
}
```

---

## Linux/NixOS Setup

### Docker vs Podman on Linux

* **Docker**: best ecosystem compatibility (Compose, k3d, kind).
* **Podman**: rootless by default, tight systemd integration, great for hardened hosts. Add `dockerCompat` to keep Docker CLI workflows.

### NixOS modules for Docker

```nix
# nix/modules/linux/docker.nix
{ pkgs, ... }:
{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
  users.users.yourname.extraGroups = [ "docker" ];
  environment.systemPackages = with pkgs; [ docker docker-compose skopeo dive ];
}
```

### NixOS modules for Podman

```nix
# nix/modules/linux/podman.nix
{ pkgs, ... }:
{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;  # /run/docker.sock + 'docker' shim
    defaultNetwork.settings.dns_enabled = true;
  };
  environment.systemPackages = with pkgs; [
    podman buildah skopeo podman-compose crun
  ];
  services.podman.autoPrune.enable = true;
}
```

### Impermanence (ephemeral root, persistent state)

```nix
# nix/modules/cloud/impermanence.nix
{ lib, impermanence, ... }:
{
  imports = [ impermanence.nixosModules.impermanence ];
  environment.persistence."/persist" = {
    directories = [
      "/var/lib" "/var/log" "/etc/ssh" "/var/lib/tailscale"
    ];
    files = [ "/etc/machine-id" ];
  };
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    mkdir -p /persist
  '';
}
```

---

## OCI Images via Nix

### Build with dockerTools

```nix
# images/api.nix
{ pkgs, self, system }:
pkgs.dockerTools.buildLayeredImage {
  name     = "registry.example.com/api";
  tag      = self.shortRev or "dev";
  contents = [ self.packages.${system}.api-binary pkgs.cacert ];
  config   = { Cmd = [ "/bin/api-binary" ]; ExposedPorts = { "8080/tcp" = {}; }; };
}
```

### Daemonless publish with Skopeo

```bash
nix build .#api-image
skopeo copy oci-archive:result \
  docker://registry.example.com/api:$(git rev-parse --short HEAD)
```

### Multi-arch strategy

* Produce `x86_64-linux` and `aarch64-linux` images from the same flake revision.
* Push as separate tags; optionally assemble a manifest list with `skopeo manifest`.
* For local Apple Silicon testing, Rosetta on Colima can run x86_64 images; prefer native arm64 for performance.

---

## Language Packaging Patterns

### Go with gomod2nix

* Pin module graph with `gomod2nix init`.
* Build with `buildGoApplication` for speed and hermeticity.
* Export an OCI image using `dockerTools.buildLayeredImage`.

```nix
{ pkgs, ... }:
pkgs.buildGoApplication {
  pname = "api";
  version = "0.1.0";
  src = ./.;
  modules = ./gomod2nix.toml;
}
```

### Python with poetry2nix/uv2nix

* Prefer `uv`/`poetry` lockfiles checked in.
* Use `poetry2nix.mkPoetryApplication` or `uv2nix` to freeze deps.
* Export as an OCI with minimal base + `fakeNss` if needed.

### Node with pnpm

* Build frontend with `nodejs` + `pnpm` pinned via `pnpm-lock.yaml`.
* Serve static assets from a tiny `nginx`/`caddy` derivation if applicable.

### Rust with crate2nix or fenix

* Use `fenix` toolchains (pinned) or `crate2nix` to generate derivations.
* Build static where possible to shrink images.

---

## Kubernetes Manifests as Nix

### Kubenix pattern

```nix
# k8s/apps/api-deploy.nix
{ pkgs, kubenix, imageRef, replicas ? 2, ... }:
kubenix.lib.evalModules {
  inherit pkgs;
  modules = [
    ({ ... }: {
      apiVersion = "apps/v1";
      kind = "Deployment";
      metadata = { name = "api"; labels.app = "api"; };
      spec = {
        inherit replicas;
        selector.matchLabels.app = "api";
        template = {
          metadata.labels.app = "api";
          spec.containers = [{
            name = "api";
            image = imageRef;
            ports = [{ containerPort = 8080; }];
            readinessProbe.httpGet = { path = "/healthz"; port = 8080; };
            livenessProbe.httpGet  = { path = "/healthz"; port = 8080; };
          }];
        };
      };
    })
  ];
}
```

**Build & apply:**

```bash
IMAGE="registry.example.com/api:$(git rev-parse --short HEAD)"
nix build .#k8s.api-manifests --override-input imageRef "$IMAGE"
kubectl apply -f result
```

### Local Kubernetes (macOS & Linux)

* **macOS:** Colima `--kubernetes`, or **kind**/**k3d**.
* **Linux:** kind (Docker), k3d (Docker), minikube (Docker/Podman), or native **k3s**.

---

## GitOps (Flux/Argo) and Helm

* **Flux**:

  * `GitRepository` targets this monorepo at a specific path/ref.
  * `HelmRelease` renders `charts/*` with pinned image tags.
  * Reconciliation interval controls deployment cadence.
* **ArgoCD**:

  * App of Apps pattern or per-app Applications targeting generated manifests.
  * Sync waves handle CRD → app ordering.

Keep **charts** small and values-driven. For pure-Nix clusters, emit manifests with Kubenix and apply via GitOps.

---

## Cloud Infra as Nix → Terraform (Terranix)

Generate Terraform JSON from Nix, then `terraform init/plan/apply`:

```nix
# infra/terranix-aws.nix
{ terranix, pkgs, ... }:
terranix.lib.terraform.mkTerraform {
  nixpkgs = pkgs;
  settings = {
    terraform.required_version = ">= 1.8.0";
    provider.aws.region = "us-west-2";
    backend.s3 = {
      bucket = "nix-tf-state";
      key    = "global/terraform.tfstate";
      region = "us-west-2";
      encrypt = true;
    };
    # modules for VPC, subnets, ALB/NLB, IAM, ECR, etc.
  };
}
```

```nix
# infra/terranix-gcp.nix
{ terranix, pkgs, ... }:
terranix.lib.terraform.mkTerraform {
  nixpkgs = pkgs;
  settings = {
    terraform.required_version = ">= 1.8.0";
    provider.google = {
      project = "your-project";
      region  = "us-west1";
    };
    backend.gcs = {
      bucket = "nix-tf-state";
      prefix = "terraform/state";
    };
    # modules for VPC, Firewall, Cloud DNS, LB, Artifact Registry, MIGs
  };
}
```

**Build & apply:**

```bash
nix build .#tf.aws
terraform -chdir=result init
terraform -chdir=result apply
```

---

## EC2 (AWS) Image Role & Boot Settings

```nix
# nix/modules/cloud/ec2-base.nix
{ lib, pkgs, ... }:
{
  boot.growPartition = true;
  fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; autoResize = true; };

  services.cloud-init.enable = true;     # inject SSH keys/hostname via IMDS
  services.amazon-ssm-agent.enable = true;
  services.openssh.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
  };

  networking.hostName = "ec2-core";
  networking.usePredictableInterfaceNames = false; # eth0
  networking.firewall.enable = true;
  boot.kernelParams = [ "console=ttyS0" ];

  # Optional: Tailscale admin plane
  services.tailscale.enable = true;

  environment.defaultPackages = [ ];
  documentation.enable = false;
}
```

**Build image:**

```bash
nix build .#ec2Image
# Upload/register via your TF or a small script (S3 -> AMI snapshot -> AMI)
```

---

## GCE (GCP N2) Image Role & Boot Settings

```nix
# nix/modules/cloud/gce-base.nix
{ lib, pkgs, ... }:
{
  boot.growPartition = true;
  fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; autoResize = true; };

  services.google-guest-agent.enable = true;  # metadata, accounts, hostname
  services.openssh.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
  };

  networking.hostName = "gce-core";
  networking.firewall.enable = true;
  boot.kernelParams = [ "console=ttyS0" ];

  services.tailscale.enable = true;

  environment.defaultPackages = [ ];
  documentation.enable = false;
}
```

**Build & import:**

```bash
nix build .#gceImage
# Result is a raw disk; tar+gzip and upload to GCS:
tar -Sczf disk.raw.tar.gz result
gsutil cp disk.raw.tar.gz gs://your-bucket/
gcloud compute images create nixos-YYYYMMDD --source-uri gs://your-bucket/disk.raw.tar.gz
# Create N2 instance template from this image; launch VM or MIG
```

---

## Secrets & Policy (sops-nix + age/KMS)

```nix
# nix/modules/secrets/sops.nix
{ sops-nix, ... }:
{
  imports = [ sops-nix.nixosModules.sops ];

  sops.defaultSopsFile = ./secrets.yaml;

  # On Linux/NixOS servers
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  # Example secrets exposed at runtime (not in the Nix store)
  sops.secrets."app/env" = {
    path = "/run/secrets/app.env";
    restartUnits = [ "api.service" ];
  };
}
```

* **AWS**: encrypt recipients with AWS KMS; instances with the correct IAM role decrypt on boot.
* **GCP**: encrypt recipients with Cloud KMS; instances on GCE use ambient credentials.
* **macOS**: keep an `age` key in your user profile; never commit private keys.

---

## Provisioning & Fleet Mgmt

* **Bootstrap non-NixOS host to Nix**: `nixos-anywhere --flake .#server root@HOST`
* **Converge NixOS nodes**: `deploy-rs` or `colmena apply -I nixpkgs=...`
* **Cluster GitOps**: Flux/Argo watches Git and reconciles Helm/manifests.

For quick service installs to non-NixOS Linux, export a **system-manager** target in your flake and run `nix run github:numtide/system-manager -- switch --flake .#profile` on Ubuntu/Debian.

---

## Binary Caches, Remote Builds, and CI Speed

* **Cachix/Attic**: push/store CI build artifacts to avoid re-compiling on laptops.
* **Remote builders**: set up a beefy `x86_64-linux` builder VM and optionally an `aarch64-linux` builder (or QEMU with binfmt) for multi-arch pipelines.
* **`nix.conf`**: share the same substituters and keys across CI and dev shells.

---

## CI/CD Pipeline Sketch

1. **Lint & fmt**
   `alejandra -q .` for Nix; Pre-commit hooks for YAML/JSON/MD.
2. **Build**
   `nix build .#api-image` (and other images); push to cache.
3. **Sign**
   `cosign sign --key ... registry.example.com/api:$TAG` (optional).
4. **Publish**
   `skopeo copy oci-archive:result docker://REG/api:$TAG`.
5. **Manifests**
   Build Kubenix `k8s/api-deploy.nix` with `imageRef=$TAG`; emit YAML.
6. **GitOps bump**
   Commit/tag Helm values or manifest digests; Flux/Argo deploys.
7. **Infra drift**
   `nix build .#tf.aws` or `.#tf.gcp` → `terraform apply`.

All steps are **flake-pinned**; rollbacks revert both infra and app versions.

---

## Observability & Cost Awareness

* **Host**: node-exporter, cAdvisor; on GCE add Ops Agent; on EC2 optionally CloudWatch Agent.
* **Cluster**: Prometheus operator + Grafana dashboards; alerting to Slack/Email.
* **Costs**: AWS Budgets or GCP Budgets; feed budget/burn into a small dashboard or your internal “Switchboard.”

---

## Security Baseline

* **Network**: keep admin endpoints behind Tailscale; ACL deny-by-default; ephemeral keys for burst workers.
* **SSH**: disable password auth; enable strong ciphers only; `AllowUsers` where practical.
* **Systemd hardening**: `ProtectSystem`, `ProtectHome`, `NoNewPrivileges` for services.
* **Images**: minimal contents; distroless-style where possible; scan with `trivy`.
* **Secrets**: sops-nix; decrypt at runtime; never in derivations.
* **Supply chain**: pin inputs via `flake.lock`; verify container signatures with `cosign` if applicable.

---

## Testing & Health Checks

* **NixOS VM tests** (boot, services, K3s):

```nix
# nix/tests/gce-boot.nix
{ ... }:
{
  name = "gce-boot";
  nodes.machine = { ... }: { imports = [ ../modules/cloud/gce-base.nix ]; };
  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.succeed("systemctl is-active google-guest-agent")
    machine.succeed("tailscale --version || true")
  '';
}
```

Run: `nix build .#nixosTests.gce-boot`

* **K8s smoke tests**: `kubectl rollout status deploy/api`, ephemeral Job to hit `/healthz`, basic e2e.

---

## Troubleshooting & Gotchas

* **Colima**: keep `~/.colima` writable; prefer CLI flags over static config.
* **Docker vs Podman**: k3d and some Compose stacks need Docker; Podman works with `dockerCompat` but test carefully.
* **EC2 NVMe**: rely on `by-label` for root FS; device names may change.
* **Binary cache misses**: ensure CI and dev use identical substituters and public keys.
* **Multi-arch drift**: build both arches from the same `flake.lock`; tag clearly.

---

## Cross-Cloud Deltas (AWS ↔︎ GCP)

**DNS/TLS**
AWS Route53 + cert-manager DNS01 vs GCP Cloud DNS + cert-manager DNS01. Same manifests; only provider values change.

**Load balancers**
ALB/NLB on AWS vs GCLB HTTP(S) and External Passthrough NLB on GCP. WebSockets OK on both; UDP via NLB equivalents.

**Images**
AMI (S3 → snapshot → AMI) on AWS vs raw disk import to GCE image on GCP. Both built from the same flake via `nixos-generators`.

**Costs/metrics**
CloudWatch vs Cloud Monitoring/Logging; both cheap to start. Budgets exist on both.

---

## Decision Matrix

| Context                  | Recommendation                        | Rationale                             |
| ------------------------ | ------------------------------------- | ------------------------------------- |
| macOS developer machine  | Colima + Docker CLI from Nix          | Declarative, no Docker Desktop        |
| Linux desktop/server     | Docker **or** Podman (`dockerCompat`) | Compatibility vs rootless/systemd     |
| Image builds             | Nix `dockerTools`                     | Reproducible, no Dockerfile drift     |
| Image publishing         | Skopeo (daemonless)                   | Works in CI and locally               |
| Manifests                | Kubenix (or Helm + Flux)              | GitOps-friendly, typed in Nix         |
| Cloud infra              | Terranix → Terraform                  | Nix as source, TF as executor         |
| AWS hosts                | `nixos-generators` AMI + EC2          | Hermetic hosts, easy rollbacks        |
| GCP hosts                | `nixos-generators` GCE image + N2     | Same as AWS flow; MIG scale-out later |
| Non-NixOS quick installs | `system-manager` profiles             | Systemd deployments on Ubuntu/Debian  |

---

## FAQ

**Q: Do I need Docker/Podman to *build* images?**
A: No. Nix builds OCI images with `dockerTools`. Runtimes are only for running/pushing locally. Prefer Skopeo for daemonless pushes.

**Q: Which local Kubernetes should I use?**
A: macOS: Colima `--kubernetes` or kind/k3d. Linux: kind/k3d/minikube. For servers: native k3s on NixOS.

**Q: How do I handle secrets safely?**
A: `sops-nix` with age locally, cloud KMS in production. Render to `/run/secrets/*` at runtime; never store in derivations.

**Q: How do I speed up CI?**
A: Use a cache (Cachix/Attic), remote builders for both arches, and keep `flake.lock` stable. Pin toolchains in devShells.

**Q: What about GPU nodes and Ray/vLLM?**
A: Keep a CPU-only core node. Add GPU workers (EC2 G* or GCE A2/G2) later; KubeRay/vLLM manifests don’t change. Join external GPU boxes over Tailscale; enforce least-privilege networking.

---

**Copy-paste quickstarts**

**macOS bootstrap**

```bash
sh <(curl -L https://nixos.org/nix/install)
nix run nix-darwin -- switch --flake .#macbook-pro
direnv allow
```

**NixOS laptop bootstrap**

```bash
sudo nixos-rebuild switch --flake .#nixos-laptop
```

**Build & publish an image**

```bash
nix build .#api-image
skopeo copy oci-archive:result docker://registry.example.com/api:$(git rev-parse --short HEAD)
```

**Generate & apply k8s manifests**

```bash
IMAGE="registry.example.com/api:$(git rev-parse --short HEAD)"
nix build .#k8s.api-manifests --override-input imageRef "$IMAGE"
kubectl apply -f result
```

**Build cloud images**

```bash
# AWS
nix build .#ec2Image
# GCP
nix build .#gceImage
```
