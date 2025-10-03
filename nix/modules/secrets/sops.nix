# SOPS secrets management configuration
# Uses Ledger GPG key for encryption/decryption
{ config, pkgs, lib, ... }:
{
  # SOPS configuration
  sops = {
    # Set GNUPGHOME so SOPS can find the Ledger GPG key
    gnupg.home = "~/.gnupg-ledger";

    # Default secrets file (can be overridden per secret)
    defaultSopsFile = ../../secrets/secrets.yaml;
  };

  # Environment variables for SOPS/GPG
  environment.variables = {
    # Point SOPS to the Ledger GPG keyring
    GNUPGHOME = lib.mkIf (builtins.hasAttr "users" config && builtins.hasAttr "users" config.users)
      (if builtins.hasAttr config.system.primaryUser config.users.users
       then "${config.users.users.${config.system.primaryUser}.home}/.gnupg-ledger"
       else "~/.gnupg-ledger");
  };

  # System packages for secrets management
  environment.systemPackages = with pkgs; [
    gnupg         # GPG for OpenPGP card (Ledger)
    age           # Modern encryption tool
    ssh-to-age    # Convert SSH keys to age format
    sops          # Secret management
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    pinentry_mac  # macOS GUI for GPG PIN entry
  ];
}
