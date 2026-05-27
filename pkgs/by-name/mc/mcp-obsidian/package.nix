{
  lib,
  buildNpmPackage,
  fetchzip,
}:

buildNpmPackage (finalAttrs: {
  pname = "mcp-obsidian";
  version = "0.8.2";

  src = fetchzip {
    url = "https://registry.npmjs.org/@mauricio.wolff/mcp-obsidian/-/mcp-obsidian-${finalAttrs.version}.tgz";
    hash = "sha256-o9+YjdLAiTcvXn6jRcTcqILMsCZS0s2pZJqJ6X9+TLE=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-tWQgIW6K0i1SZhASdnZNhvsOqM55jriJk6G3nb3uH+M=";

  __structuredAttrs = true;

  dontNpmBuild = true;

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Universal AI bridge for Obsidian vaults via Model Context Protocol";
    homepage = "https://github.com/bitbonsai/mcp-obsidian";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ shgew ];
    mainProgram = "mcp-obsidian";
  };
})
