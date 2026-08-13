{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
}:

stdenv.mkDerivation rec {
  pname = "axe";
  version = "1.8.0";

  src = fetchurl {
    url = "https://github.com/cameroncooke/AXe/releases/download/v${version}/AXe-macOS-v${version}-universal.tar.gz";
    hash = "sha256-e3Y0C3LpDQ8hG8fEY28VAJB27/B6zvLytjKxdd69iDQ=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ makeWrapper ];

  # prebuilt Developer ID signed binaries; stripping would invalidate the signatures
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec
    cp axe $out/libexec/
    cp -R Frameworks AXe_AXe.bundle $out/libexec/
    makeWrapper $out/libexec/axe $out/bin/axe

    runHook postInstall
  '';

  meta = {
    description = "Command-line tool for iOS simulator UI automation";
    homepage = "https://github.com/cameroncooke/AXe";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [ shgew ];
    platforms = lib.platforms.darwin;
    mainProgram = "axe";
  };
}
