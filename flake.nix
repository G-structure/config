{
  description = "WikiGen's Nix Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, darwin, home-manager, sops-nix, ... }:
  let
    system = "aarch64-darwin";
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
    # Expose the ai-clis package
    packages.${system} = {
      ai-clis = pkgs.callPackage ./nix/packages/ai-clis.nix { };
      ledger-ssh-agent = pkgs.ledger-ssh-agent;
      default = self.packages.${system}.ai-clis;
    };

    darwinConfigurations."wikigen-mac" = darwin.lib.darwinSystem {
      inherit system;
      modules = [
        ./darwin-configuration.nix
        home-manager.darwinModules.home-manager
        sops-nix.darwinModules.sops
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.wikigen = import ./home.nix;
          nixpkgs.overlays = [
            (import ./nix/overlays/ledger-ssh-agent.nix)
            (import ./nix/overlays/ledger-agent.nix)
          ];
        }
      ];
      specialArgs = { inherit self; };
    };
  };
}
