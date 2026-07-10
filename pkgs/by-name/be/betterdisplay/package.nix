{
  lib,
  stdenvNoCC,
  fetchurl,
  undmg,
  nix-update-script,
  versionCheckHook,
  writeShellScript,
  re-plistbuddy,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "betterdisplay";
  version = "4.3.5";

  src = fetchurl {
    url = "https://github.com/waydabber/BetterDisplay/releases/download/v${finalAttrs.version}/BetterDisplay-v${finalAttrs.version}.dmg";
    hash = "sha256-8lUC6Cs3ubHRRnooQ4NM4gPIU3q3PEScbnlGCuC7Vgc=";
  };

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  buildInputs = [ undmg ];

  sourceRoot = ".";
  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications
    mv BetterDisplay.app $out/Applications

    runHook postInstall
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgram = writeShellScript "version-check" ''
    ${lib.getExe' re-plistbuddy "PlistBuddy"} -c "Print :CFBundleShortVersionString" "$1"
  '';
  versionCheckProgramArg = [
    "${placeholder "out"}/Applications/BetterDisplay.app/Contents/Info.plist"
  ];
  doInstallCheck = true;

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--use-github-releases" ];
  };

  meta = {
    description = "Unlock your displays on your Mac! Flexible HiDPI scaling, XDR/HDR extra brightness, virtual screens, DDC control, extra dimming, PIP/streaming, EDID override and lots more";
    homepage = "https://betterdisplay.pro/";
    changelog = "https://github.com/waydabber/BetterDisplay/releases/tag/v${finalAttrs.version}";
    license = [ lib.licenses.unfree ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    maintainers = with lib.maintainers; [ DimitarNestorov ];
    platforms = lib.platforms.darwin;
  };
})
