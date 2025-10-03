{ pkgs, ... }:

{
  home.stateVersion = "24.11";

  # User packages
  home.packages = with pkgs; [
    # Container tools
    skopeo
    dive

    # Development tools
    jq
    yq

    # Cloud tools
    awscli2
    terraform

    # Ledger Hardware Security
    ledger-ssh-agent  # SSH agent for Ledger hardware wallets
    ledger-agent      # Ledger SSH/GPG agent from trezor-agent
  ];

  # Shell configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    initContent = ''
      # Colima autostart
      if command -v colima &>/dev/null; then
        if ! colima status &>/dev/null; then
          echo "Starting Colima..."
          colima start --cpu 4 --memory 8 --disk 100
        fi
      fi
    '';
  };

  programs.git = {
    enable = true;
    userName = "Luc Chartier";
    userEmail = "luc@distorted.media";

    # GPG signing with Ledger hardware wallet
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
    pinentry.package = pkgs.pinentry_mac;
  };

  # Shell environment for GPG/SSH
  home.sessionVariables = {
    GPG_TTY = "$(tty)";
    SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
  };

  # Ledger GPG Agent launchd service - starts on login
  launchd.agents.ledger-gpg-agent = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.writeShellScript "ledger-gpg-agent-wrapper" ''
          export PATH="${pkgs.gnupg}/bin:$PATH"
          exec ${pkgs.ledger-agent}/bin/ledger-gpg-agent --homedir /Users/wikigen/.gnupg-ledger --server --verbose
        ''}"
      ];
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/Users/wikigen/.local/share/ledger-gpg-agent.log";
      StandardErrorPath = "/Users/wikigen/.local/share/ledger-gpg-agent.error.log";
    };
  };

  # Ledger SSH Agent launchd service - starts on login
  launchd.agents.ledger-ssh-agent = {
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
      StandardOutPath = "/Users/wikigen/.local/share/ledger-ssh-agent.log";
      StandardErrorPath = "/Users/wikigen/.local/share/ledger-ssh-agent.error.log";
    };
  };
}
