{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
}:

stdenv.mkDerivation rec {
  pname = "axe";
  version = "1.7.1";

  src = fetchurl {
    url = "https://github.com/cameroncooke/AXe/releases/download/v${version}/AXe-macOS-v${version}-universal.tar.gz";
    hash = "sha256-JqZACcCaOumAsfG0s3e9Ki3ZbLveJIIZNeRzUstxzGk=";
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
