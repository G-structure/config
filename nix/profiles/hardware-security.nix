# Hardware security profile
# Ledger hardware wallet support for SSH and GPG
{ config, pkgs, lib, ... }:
{
  # Home-manager configuration for hardware security
  # This profile expects to be used within home-manager
  home.packages = with pkgs; [
    # Ledger Hardware Security
    ledger-ssh-agent  # SSH agent for Ledger hardware wallets
    ledger-agent      # Ledger SSH/GPG agent from trezor-agent
  ];

  # GPG configuration for Ledger OpenPGP card
  programs.gpg = {
    enable = true;
    scdaemonSettings = {
      reader-port = "Ledger Token";
      allow-admin = true;
      enable-pinpad-varlen = true;
      disable-ccid = true;
      pcsc-shared = true;
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = if pkgs.stdenv.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-curses;
  };

  # Shell environment for GPG/SSH
  home.sessionVariables = {
    GPG_TTY = "$(tty)";
    SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
  };

  # Git GPG signing configuration
  programs.git = {
    signing = {
      key = "D2A7EC63E350CC488197CB2ED369B07E00FB233E";
      signByDefault = true;
    };

    extraConfig = {
      gpg = {
        program = "${pkgs.writeShellScript "gpg-ledger" ''
          # Ensure ledger-gpg-agent is running
          if ! pgrep -f "ledger-gpg-agent.*--homedir.*\.gnupg-ledger" > /dev/null; then
            PATH="${pkgs.gnupg}/bin:$PATH" ${pkgs.ledger-agent}/bin/ledger-gpg-agent --homedir $HOME/.gnupg-ledger --server --verbose &
            sleep 2
          fi

          # Use --homedir flag instead of GNUPGHOME
          exec ${pkgs.gnupg}/bin/gpg --homedir $HOME/.gnupg-ledger "$@"
        ''}";
        openpgp.program = "${pkgs.writeShellScript "gpg-ledger" ''
          # Ensure ledger-gpg-agent is running
          if ! pgrep -f "ledger-gpg-agent.*--homedir.*\.gnupg-ledger" > /dev/null; then
            PATH="${pkgs.gnupg}/bin:$PATH" ${pkgs.ledger-agent}/bin/ledger-gpg-agent --homedir $HOME/.gnupg-ledger --server --verbose &
            sleep 2
          fi

          # Use --homedir flag instead of GNUPGHOME
          exec ${pkgs.gnupg}/bin/gpg --homedir $HOME/.gnupg-ledger "$@"
        ''}";
      };
    };
  };

  # Ledger GPG Agent launchd service - starts on login (macOS only)
  launchd.agents.ledger-gpg-agent = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.writeShellScript "ledger-gpg-agent-wrapper" ''
          export PATH="${pkgs.gnupg}/bin:$PATH"
          exec ${pkgs.ledger-agent}/bin/ledger-gpg-agent --homedir ${config.home.homeDirectory}/.gnupg-ledger --server --verbose
        ''}"
      ];
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "${config.home.homeDirectory}/.local/share/ledger-gpg-agent.log";
      StandardErrorPath = "${config.home.homeDirectory}/.local/share/ledger-gpg-agent.error.log";
    };
  };

  # Ledger SSH Agent launchd service - starts on login (macOS only)
  launchd.agents.ledger-ssh-agent = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.writeShellScript "ledger-ssh-agent-wrapper" ''
          export PATH="${pkgs.gnupg}/bin:$PATH"
          exec ${pkgs.ledger-agent}/bin/ledger-agent -d ssh://ledger@localhost
        ''}"
      ];
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "${config.home.homeDirectory}/.local/share/ledger-ssh-agent.log";
      StandardErrorPath = "${config.home.homeDirectory}/.local/share/ledger-ssh-agent.error.log";
    };
  };
}
