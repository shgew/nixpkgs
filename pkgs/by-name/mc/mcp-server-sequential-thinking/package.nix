{
  lib,
  buildNpmPackage,
  fetchzip,
}:

buildNpmPackage (finalAttrs: {
  pname = "mcp-server-sequential-thinking";
  version = "0.6.2";

  src = fetchzip {
    url = "https://registry.npmjs.org/@modelcontextprotocol/server-sequential-thinking/-/server-sequential-thinking-${finalAttrs.version}.tgz";
    hash = "sha256-U21rDtEpHYv+YPOs31AuGoTahR8QklNY4i0ySKWkX8U=";
  };

  npmDepsHash = "sha256-bTAP+oBezZ+W6dnJ67yLXzPRPbURFua7lqUX1ilQ4O0=";

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
