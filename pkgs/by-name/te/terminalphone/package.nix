{
  lib,
  stdenv,
  stdenvNoCC,
  fetchFromGitLab,
  makeWrapper,
  bash,
  alsa-utils,
  opus-tools,
  openssl,
  qrencode,
  socat,
  sox,
  tor,
}:

stdenvNoCC.mkDerivation {
  pname = "terminalphone";
  version = "1.1.6-unstable-2026-04-07";

  src = fetchFromGitLab {
    owner = "here_forawhile";
    repo = "terminalphone";
    rev = "e1d2512e8263de871232a338caa0e764ba1e3c2f";
    hash = "sha256-I09QHbQjD7L7TUozDIIVOc5tQ0lJmM2d30X1wooxXZA=";
  };

  nativeBuildInputs = [ makeWrapper ];

  __structuredAttrs = true;
  strictDeps = true;

  dontConfigure = true;
  dontBuild = true;

  postPatch = ''
    substituteInPlace terminalphone.sh \
      --replace-fail 'BASE_DIR="$(cd "$(dirname "$0")" && pwd -P)"' \
                     'BASE_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}"' \
      --replace-fail 'DATA_DIR="$BASE_DIR/.terminalphone"' \
                     'DATA_DIR="$BASE_DIR/terminalphone"'
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 terminalphone.sh "$out/share/terminalphone/terminalphone.sh"
    install -Dm644 LICENSE -t "$out/share/doc/terminalphone"
    install -Dm644 README.md -t "$out/share/doc/terminalphone"
    install -Dm644 CHANGELOG -t "$out/share/doc/terminalphone"

    makeWrapper ${lib.getExe bash} "$out/bin/terminalphone" \
      --add-flags "$out/share/terminalphone/terminalphone.sh" \
      --prefix PATH : ${
        lib.makeBinPath (
          [
            opus-tools
            openssl
            qrencode
            socat
            sox
            tor
          ]
          ++ lib.optionals stdenv.hostPlatform.isLinux [ alsa-utils ]
        )
      }

    runHook postInstall
  '';

  meta = {
    description = "Encrypted push-to-talk voice and text over Tor hidden services";
    longDescription = ''
      TerminalPhone is a single, self-contained Bash script that provides
      anonymous, end-to-end encrypted voice and text communication between two
      or more parties over the Tor network. It operates as a walkie-talkie:
      you record a voice message, and it is compressed, encrypted, and
      transmitted to the remote party as a single unit. Your Tor hidden
      service .onion address is your identity.
    '';
    homepage = "https://gitlab.com/here_forawhile/terminalphone";
    changelog = "https://gitlab.com/here_forawhile/terminalphone/-/blob/main/CHANGELOG";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ shgew ];
    mainProgram = "terminalphone";
    platforms = lib.platforms.unix;
  };
}
