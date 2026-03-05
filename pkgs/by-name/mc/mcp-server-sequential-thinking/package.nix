{
  lib,
  buildNpmPackage,
  fetchzip,
}:

buildNpmPackage (finalAttrs: {
  pname = "mcp-server-sequential-thinking";
  version = "2025.12.18";

  src = fetchzip {
    url = "https://registry.npmjs.org/@modelcontextprotocol/server-sequential-thinking/-/server-sequential-thinking-${finalAttrs.version}.tgz";
    hash = "sha256-4O9qTNwdi3Tfy0IrtwuHwQ8tZZpMKkDmHTFpJYACeuo=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-r0RrOQ8RlspNbIiakpQ0Htc5Sus4MleUaUp3807XSlg=";

  dontNpmBuild = true;

  npmPackFlags = [ "--ignore-scripts" ];

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  meta = {
    description = "MCP server for sequential thinking and problem solving";
    homepage = "https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking";
    changelog = "https://github.com/modelcontextprotocol/servers/releases/tag/typescript-servers-${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ shgew ];
    mainProgram = "mcp-server-sequential-thinking";
  };
})
