{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  nix-update-script,
  python3,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "xcode-build-server";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "SolaWing";
    repo = "xcode-build-server";
    tag = "v${finalAttrs.version}";
    hash = "sha256-AUGDoMeW/FSMJLG7uR580cMpytYQBFV2PXE3LBNaiFQ=";
  };

  __structuredAttrs = true;
  strictDeps = true;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ python3 ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/libexec/xcode-build-server
    cp -R . $out/libexec/xcode-build-server
    makeWrapper $out/libexec/xcode-build-server/xcode-build-server \
      $out/bin/xcode-build-server

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Build server protocol implementation for Xcode and SourceKit-LSP";
    homepage = "https://github.com/SolaWing/xcode-build-server";
    changelog = "https://github.com/SolaWing/xcode-build-server/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ shgew ];
    mainProgram = "xcode-build-server";
    platforms = lib.platforms.darwin;
  };
})
