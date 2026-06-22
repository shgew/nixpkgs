{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  git,
  nodejs_22,
  nix-update-script,
  versionCheckHook,
}:

buildNpmPackage (finalAttrs: {
  pname = "codegraph";
  version = "1.0.1";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "colbymchenry";
    repo = "codegraph";
    tag = "v${finalAttrs.version}";
    hash = "sha256-k4UMQit4/Yqgyuv+x1pZqyInPpBvJ4Qy9Y8Vpgu4FNI=";
  };

  npmDepsHash = "sha256-FdWAmkYKRVnztBF4Va6chOVLdH8DHNfDM2aobCIRsq4=";

  nodejs = nodejs_22;

  patches = [ ./disable-self-management.patch ];

  doCheck = true;
  nativeCheckInputs = [ git ];
  checkPhase = ''
    runHook preCheck
    npm test -- --exclude __tests__/upgrade.test.ts --exclude __tests__/mcp-daemon.test.ts
    runHook postCheck
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  postInstallCheck = ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    project="$TMPDIR/project"
    mkdir -p "$project"
    printf 'example <- function() 1\n' > "$project/example.r"
    "$out/bin/codegraph" init "$project"
    "$out/bin/codegraph" status "$project" --json
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Code intelligence and knowledge graph for any codebase";
    homepage = "https://github.com/colbymchenry/codegraph";
    changelog = "https://github.com/colbymchenry/codegraph/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ shgew ];
    mainProgram = "codegraph";
  };
})
