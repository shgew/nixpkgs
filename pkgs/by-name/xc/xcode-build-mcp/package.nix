{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage (finalAttrs: {
  pname = "xcode-build-mcp";
  version = "2.3.2";

  src = fetchFromGitHub {
    owner = "getsentry";
    repo = "XcodeBuildMCP";
    tag = "v${finalAttrs.version}";
    hash = "sha256-RHg5uIWpNwqGvd9LuVO7zBt6hgSZWb1KSHcslt1mgJQ=";
  };

  npmDepsHash = "sha256-jgvxXxvmdMr/qK3iGPAF/fjo2ob5aKIlXXJbRqDVOCI=";

  # The `prepare` script tries to install git hooks
  npmFlags = [ "--ignore-scripts" ];

  # Generate src/version.ts then build with tsup
  preBuild = ''
    node --input-type=module -e "
      import { readFile, writeFile } from 'node:fs/promises';
      const pkg = JSON.parse(await readFile('package.json', 'utf8'));
      const content =
        \"export const version = '\" + pkg.version + \"';\\n\" +
        \"export const iOSTemplateVersion = '\" + pkg.iOSTemplateVersion + \"';\\n\" +
        \"export const macOSTemplateVersion = '\" + pkg.macOSTemplateVersion + \"';\\n\";
      await writeFile('src/version.ts', content, 'utf8');
    "
  '';

  npmBuildScript = "build:tsup";

  postInstall = ''
    wrapProgram $out/bin/xcodebuildmcp \
      --set XCODEBUILDMCP_SENTRY_DISABLED true
    wrapProgram $out/bin/xcodebuildmcp-doctor \
      --set XCODEBUILDMCP_SENTRY_DISABLED true
  '';

  meta = {
    description = "Model Context Protocol server that provides Xcode build, test, and simulator tools for AI coding agents";
    homepage = "https://github.com/getsentry/XcodeBuildMCP";
    changelog = "https://github.com/getsentry/XcodeBuildMCP/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ shgew ];
    mainProgram = "xcodebuildmcp";
    platforms = lib.platforms.darwin;
  };
})
