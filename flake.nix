{
  description = "WikiGen's Nix Configuration - Modular multi-platform setup";

  inputs = {
    # Main nixpkgs (unstable for macOS, as per nix-darwin requirements)
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Stable nixpkgs for future NixOS hosts
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";

    # nix-darwin for macOS
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # SOPS secrets management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Flake-parts for better organization
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Future: Additional inputs for cloud/k8s
    # nixos-generators.url = "github:nix-community/nixos-generators";
    # impermanence.url = "github:nix-community/impermanence";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-stable, darwin, home-manager, sops-nix, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Supported systems
      systems = [
        "aarch64-darwin"   # Apple Silicon Macs
        "x86_64-linux"     # Intel/AMD Linux
        "aarch64-linux"    # ARM Linux
      ];

      perSystem = { system, ... }:
        let
          # Import nixpkgs with overlays
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [
              (import ./nix/overlays/ledger-ssh-agent.nix)
              (import ./nix/overlays/ledger-agent.nix)
            ];
          };
        in
        {
          # Packages available via `nix build`
          packages = {
            ai-clis = pkgs.callPackage ./nix/packages/ai-clis.nix { };
            ledger-ssh-agent = pkgs.ledger-ssh-agent;
            ledger-agent = pkgs.ledger-agent;
            default = self.packages.${system}.ai-clis;
          };

          # Development shell
          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              git
              vim
              curl
              wget
              jq
              yq
            ];
            shellHook = ''
              echo "WikiGen's Nix Dev Environment"
              echo "System: ${system}"
            '';
          };
        };

      flake = {
        # Darwin (macOS) configurations
        darwinConfigurations = {
          wikigen-mac = darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            modules = [
              # Base modules
              ./nix/modules/common.nix
              ./nix/modules/darwin-base.nix

              # Darwin-specific modules
              ./nix/modules/darwin/homebrew.nix

              # Profiles
              ./nix/profiles/cloud-cli.nix
              ./nix/profiles/developer.nix

              # SOPS secrets
              ./nix/modules/secrets/sops.nix
              sops-nix.darwinModules.sops

              # Host-specific configuration
              ./hosts/wikigen-mac.nix

              # Home Manager
              home-manager.darwinModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.backupFileExtension = "backup";
                home-manager.users.wikigen = import ./home/users/wikigen.nix;

                # Apply overlays for home-manager
                nixpkgs.overlays = [
                  (import ./nix/overlays/ledger-ssh-agent.nix)
                  (import ./nix/overlays/ledger-agent.nix)
                ];
              }
            ];
            specialArgs = { inherit self; };
          };
        };

        # NixOS configurations (placeholder for future)
        nixosConfigurations = {
          # Uncomment when setting up a NixOS machine
          # linux-workstation = nixpkgs.lib.nixosSystem {
          #   system = "x86_64-linux";
          #   modules = [
          #     ./nix/modules/common.nix
          #     ./nix/modules/linux-base.nix
          #     ./nix/profiles/cloud-cli.nix
          #     ./nix/profiles/developer.nix
          #     ./hosts/linux-workstation.nix
          #     home-manager.nixosModules.home-manager
          #     {
          #       home-manager.useGlobalPkgs = true;
          #       home-manager.useUserPackages = true;
          #       home-manager.users.wikigen = import ./home/users/wikigen.nix;
          #     }
          #   ];
          #   specialArgs = { inherit self; };
          # };
        };

        # Future: Cloud images
        # packages.x86_64-linux.ec2Image = ...
        # packages.x86_64-linux.gceImage = ...
      };
    };
}
