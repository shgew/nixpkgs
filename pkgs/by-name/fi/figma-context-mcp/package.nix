{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  nix-update-script,
  nodejs,
  pnpm_10,
  pnpmConfigHook,
  fetchPnpmDeps,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "figma-context-mcp";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "GLips";
    repo = "Figma-Context-MCP";
    tag = "v${finalAttrs.version}";
    hash = "sha256-1FPNyUwYhvpg8+9ht6qcAdWDnB/325DnGEUmplZuM5g=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm_10
    pnpmConfigHook
    makeWrapper
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 3;
    hash = "sha256-zEj1uFqYu9hcOm8htUhGvhEEMR5iK8bCwWcj0YH3YpQ=";
  };

  buildPhase = ''
    runHook preBuild

    pnpm build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/figma-context-mcp
    cp -r dist node_modules $out/lib/figma-context-mcp/

    mkdir -p $out/bin
    makeWrapper ${nodejs}/bin/node $out/bin/figma-context-mcp \
      --add-flags "$out/lib/figma-context-mcp/dist/bin.js"

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "MCP server to provide Figma layout information to AI coding agents like Cursor";
    homepage = "https://github.com/GLips/Figma-Context-MCP";
    changelog = "https://github.com/GLips/Figma-Context-MCP/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ shgew ];
    mainProgram = "figma-context-mcp";
    platforms = with lib.platforms; linux ++ darwin;
  };
})
