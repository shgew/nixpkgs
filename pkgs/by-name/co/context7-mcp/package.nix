{
  lib,
  buildNpmPackage,
  fetchzip,
  nix-update-script,
}:

buildNpmPackage (finalAttrs: {
  pname = "context7-mcp";
  version = "2.1.3";

  src = fetchzip {
    url = "https://registry.npmjs.org/@upstash/context7-mcp/-/context7-mcp-${finalAttrs.version}.tgz";
    hash = "sha256-+k/z6hA8XHdBPBWZ+VVZE/Y1gnWALXAmBYr6/CFKiYw=";
  };

  npmDepsHash = "sha256-xVRTtQ0uOA77fP/pxUC2ZpW28aJbIeSfB50GTmMkJ9c=";

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "MCP server providing up-to-date documentation and code examples for any library";
    homepage = "https://github.com/upstash/context7";
    downloadPage = "https://www.npmjs.com/package/@upstash/context7-mcp";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ shgew ];
    mainProgram = "context7-mcp";
  };
})
