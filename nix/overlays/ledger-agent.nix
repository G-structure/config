final: prev: {
  # Build both libagent and ledger-agent from the trezor-agent repo
  python312 = prev.python312.override {
    packageOverrides = pyFinal: pyPrev: {
      # Override ledgerblue to skip bleak dependency on macOS
      ledgerblue = pyPrev.ledgerblue.overridePythonAttrs (old: {
        pythonRemoveDeps = [ "bleak" ];
        dontCheckRuntimeDeps = true;

        postPatch = (old.postPatch or "") + ''
          substituteInPlace ledgerblue/comm.py \
            --replace-fail 'from .BleComm import BleDevice' \
            'try:
    from .BleComm import BleDevice
    BLE_SUPPORT = True
except ImportError:
    BLE_SUPPORT = False
    class BleDevice:
        pass'
        '';
      });

      # Build libagent base package
      libagent = pyFinal.buildPythonPackage {
        pname = "libagent";
        version = "0.15.0";
        format = "setuptools";

        src = prev.fetchFromGitHub {
          owner = "romanz";
          repo = "trezor-agent";
          rev = "e8e033fb0bd6e985ecf49a802f490dbd971a1676";
          hash = "sha256-A3WdhiAarTCJLWJEvwN8/PwMtiYLUYlUcuqJrGobeFc=";
        };

        # Patch ledger.py to fix GPG signing with newer Ledger app versions
        postPatch = ''
          # Fix GPG signing by disabling end-of-frame byte for GPG operations
          # The Ledger SSH/GPG Agent app doesn't properly support the end-of-frame
          # byte for GPG signing (instruction 0x08), only for SSH (instruction 0x04)
          substituteInPlace libagent/device/ledger.py \
            --replace-fail \
              "if offset + chunk_size == len(blob) and self.ledger_app_supports_end_of_frame_byte:" \
              "if offset + chunk_size == len(blob) and self.ledger_app_supports_end_of_frame_byte and identity.identity_dict['proto'] == 'ssh':"
        '';

        propagatedBuildInputs = with pyFinal; [
          bech32
          cryptography
          docutils
          python-daemon
          wheel
          backports-shutil-which
          configargparse
          ecdsa
          pynacl
          mnemonic
          pymsgbox
          semver
          unidecode
          setuptools  # Required for pkg_resources
        ];

        doCheck = false;

        meta = with prev.lib; {
          description = "Using hardware wallets as SSH/GPG/age agent - base library";
          homepage = "https://github.com/romanz/trezor-agent";
          license = licenses.lgpl3;
          platforms = platforms.unix;
        };
      };
    };
  };

  # Build ledger-agent package
  ledger-agent = final.python312.pkgs.buildPythonApplication {
    pname = "ledger-agent";
    version = "0.9.0";
    format = "setuptools";

    src = prev.fetchFromGitHub {
      owner = "romanz";
      repo = "trezor-agent";
      rev = "e8e033fb0bd6e985ecf49a802f490dbd971a1676";
      hash = "sha256-A3WdhiAarTCJLWJEvwN8/PwMtiYLUYlUcuqJrGobeFc=";
    };

    # Only build the ledger agent, not the whole repo
    postPatch = ''
      # Navigate to the ledger agent subdirectory
      cd agents/ledger
    '';

    propagatedBuildInputs = with final.python312.pkgs; [
      libagent
      ledgerblue
    ];

    doCheck = false;

    meta = with prev.lib; {
      description = "Using Ledger hardware wallet as SSH/GPG agent";
      homepage = "https://github.com/romanz/trezor-agent";
      license = licenses.lgpl3;
      platforms = platforms.unix;
      mainProgram = "ledger-agent";
    };
  };
}
