final: prev: {
  # Override ledgerblue to skip bleak dependency on macOS (not needed for USB/HID)
  python312 = prev.python312.override {
    packageOverrides = pyFinal: pyPrev: {
      ledgerblue = pyPrev.ledgerblue.overridePythonAttrs (old: {
        pythonRemoveDeps = [ "bleak" ];  # Remove bleak dep (Bluetooth, not needed on macOS)
        dontCheckRuntimeDeps = true;  # Skip the runtime dependency check

        # Patch comm.py to make BleComm import optional
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
    };
  };

  ledger-ssh-agent = prev.python312.pkgs.buildPythonApplication {
    pname = "ledger-ssh-agent";
    version = "unstable-2024-01-11";
    format = "other";  # No standard Python build system

    src = prev.fetchFromGitHub {
      owner = "LedgerHQ";
      repo = "app-ssh-agent";
      rev = "3bae16a59dc99668007c7c622ee5b62102f5eed1";
      hash = "sha256-LMV2DrgUCbkwHVMJJhSBliFoPl3QDWbxJwuj/pN2BcU=";
    };

    propagatedBuildInputs = with final.python312.pkgs; [
      ledgerblue
    ];

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/bin

      # Copy and fix Python 2 to Python 3 syntax for agent.py
      cp agent.py $out/bin/ledger-ssh-agent

      # Fix imports
      substituteInPlace $out/bin/ledger-ssh-agent \
        --replace-fail 'import thread' 'import _thread as thread'

      # Fix comparison operators
      substituteInPlace $out/bin/ledger-ssh-agent \
        --replace-fail 'blob <> key:' 'blob != key:' \
        --replace-fail 'while offset <> len(challenge):' 'while offset != len(challenge):' \
        --replace-fail 'if offset == len(challenge):' 'if offset >= len(challenge):'

      # Fix print statements
      substituteInPlace $out/bin/ledger-ssh-agent \
        --replace-fail 'print "Export those variables in your shell to use this agent"' 'print("Export those variables in your shell to use this agent")' \
        --replace-fail 'print "export SSH_AUTH_SOCK=" + socketPath.name' 'print("export SSH_AUTH_SOCK=" + socketPath.name)' \
        --replace-fail 'print "export SSH_AGENT_PID=" + str(os.getpid())' 'print("export SSH_AGENT_PID=" + str(os.getpid()))' \
        --replace-fail 'print "Agent running ..."' 'print("Agent running ...")'

      # Fix hex encoding - convert .encode('hex') to .hex()
      substituteInPlace $out/bin/ledger-ssh-agent \
        --replace-fail 'blob.encode('"'"'hex'"'"')' 'blob.hex()' \
        --replace-fail 'message.encode('"'"'hex'"'"')' 'message.hex()' \
        --replace-fail 'agentResponse.encode('"'"'hex'"'"')' 'agentResponse.hex()'

      # Fix hex decoding - convert "string".decode('hex') to bytes.fromhex("string")
      substituteInPlace $out/bin/ledger-ssh-agent \
        --replace-fail 'apdu = "8004".decode('"'"'hex'"'"')' 'apdu = bytes.fromhex("8004")'

      # Fix chr() for bytes - need to build bytes properly
      substituteInPlace $out/bin/ledger-ssh-agent \
        --replace-fail 'response = chr(SSH2_AGENT_IDENTITIES_ANSWER)' 'response = bytes([SSH2_AGENT_IDENTITIES_ANSWER])' \
        --replace-fail 'response = chr(SSH2_AGENT_SIGN_RESPONSE)' 'response = bytes([SSH2_AGENT_SIGN_RESPONSE])' \
        --replace-fail 'return chr(SSH_AGENT_FAILURE)' 'return bytes([SSH_AGENT_FAILURE])' \
        --replace-fail 'response = chr(SSH_AGENT_FAILURE)' 'response = bytes([SSH_AGENT_FAILURE])'

      # Fix struct.pack concatenation
      substituteInPlace $out/bin/ledger-ssh-agent \
        --replace-fail 'response += struct.pack' 'response = response + struct.pack'

      # Fix integer division
      substituteInPlace $out/bin/ledger-ssh-agent \
        --replace-fail 'chr(len(donglePath) / 4)' 'bytes([len(donglePath) // 4])'

      # Fix parse_bip32_path to use bytes instead of strings
      substituteInPlace $out/bin/ledger-ssh-agent \
        --replace-fail 'def parse_bip32_path(path):
	if len(path) == 0:
		return ""
	result = ""' \
        'def parse_bip32_path(path):
	if len(path) == 0:
		return b""
	result = b""'

      # Copy and fix getPublicKey.py
      cp getPublicKey.py $out/bin/ledger-get-pubkey

      # Fix comparison operators
      substituteInPlace $out/bin/ledger-get-pubkey \
        --replace-fail '((keyX[31] & 1)<>0)' '((keyX[31] & 1) != 0)'

      # Fix parse_bip32_path to use bytes instead of strings
      substituteInPlace $out/bin/ledger-get-pubkey \
        --replace-fail 'result = ""' 'result = b""' \
        --replace-fail 'return ""' 'return b""'

      # Fix print statement
      substituteInPlace $out/bin/ledger-get-pubkey \
        --replace-fail 'print keyHeader + " " + base64.b64encode(blob)' 'print(keyHeader + " " + base64.b64encode(blob).decode())'

      # Fix hex decoding
      substituteInPlace $out/bin/ledger-get-pubkey \
        --replace-fail 'apdu = apdu.decode('"'"'hex'"'"')' 'apdu = bytes.fromhex(apdu)'

      # Fix chr and integer division
      substituteInPlace $out/bin/ledger-get-pubkey \
        --replace-fail 'chr(len(donglePath) + 1) + chr(len(donglePath) / 4)' 'bytes([len(donglePath) + 1, len(donglePath) // 4])'

      # Fix blob/key concatenation to use bytes
      substituteInPlace $out/bin/ledger-get-pubkey \
        --replace-fail 'blob = struct.pack(">I", len(KEY_HEADER)) + keyHeader' 'blob = struct.pack(">I", len(KEY_HEADER)) + keyHeader.encode()' \
        --replace-fail 'blob += struct.pack(">I", len(CURVE_NAME)) + CURVE_NAME' 'blob += struct.pack(">I", len(CURVE_NAME)) + CURVE_NAME.encode()'

      # Fix key to be bytes instead of str
      substituteInPlace $out/bin/ledger-get-pubkey \
        --replace-fail 'key = str(result[1:])' 'key = bytes(result[1:])' \
        --replace-fail 'key = str(keyY)' 'key = bytes(keyY)'

      chmod +x $out/bin/*

      # Make them executable Python scripts
      sed -i '1i#!${prev.python312}/bin/python3' $out/bin/ledger-get-pubkey
      sed -i '1i#!${prev.python312}/bin/python3' $out/bin/ledger-ssh-agent
    '';

    meta = with prev.lib; {
      description = "SSH and PGP agent for Ledger hardware wallets";
      homepage = "https://github.com/LedgerHQ/app-ssh-agent";
      license = licenses.asl20;
      platforms = platforms.unix;
    };
  };
}
