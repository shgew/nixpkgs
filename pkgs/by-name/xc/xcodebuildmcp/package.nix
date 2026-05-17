{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  fetchurl,
  makeWrapper,
  versionCheckHook,
}:

let
  axeVersion = "1.5.2";
  axeSrc = fetchurl {
    url = "https://github.com/cameroncooke/AXe/releases/download/v${axeVersion}/AXe-macOS-v${axeVersion}-universal.tar.gz";
    hash = "sha256-Uct+fyxf7JCoTP2ol4PilW6inQnkoOBqfuNlD8i5h0w=";
  };
in
buildNpmPackage (finalAttrs: {
  pname = "xcodebuildmcp";
  version = "2.5.2";

  src = fetchFromGitHub {
    owner = "getsentry";
    repo = "XcodeBuildMCP";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ir0ZpIpRtLqH/4yPQX+jfgosVpsuHg07iEeEb0yRGwg=";
  };

  npmDepsHash = "sha256-qkNmrsbvBMac8ePquAArBlxO5RQBJ7D7BAKrO6srd0g=";

  __structuredAttrs = true;

  nativeBuildInputs = [ makeWrapper ];

  # AXe is normally downloaded by scripts/bundle-axe.sh at build time; fetch it
  # declaratively and drop it into bundled/ so the sandboxed build skips network.
  # `export npmDeps` works around npmConfigHook reading it as an env var while
  # `__structuredAttrs = true` keeps it in .attrs.json only.
  postPatch = ''
    export npmDeps
    mkdir -p bundled
    tar -xzf ${axeSrc} -C bundled
  '';

  npmBuildScript = "build:tsup";

  postInstall = ''
    for bin in xcodebuildmcp xcodebuildmcp-doctor; do
      wrapProgram $out/bin/$bin \
        --set-default XCODEBUILDMCP_SENTRY_DISABLED true
    done
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";

  meta = {
    description = "MCP server providing Xcode project, simulator, and device management tools for AI agents";
    homepage = "https://github.com/getsentry/XcodeBuildMCP";
    changelog = "https://github.com/getsentry/XcodeBuildMCP/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ shgew ];
    mainProgram = "xcodebuildmcp";
    platforms = lib.platforms.darwin;
  };
})
