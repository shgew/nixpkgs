{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "slack-mcp-server";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "korotovsky";
    repo = "slack-mcp-server";
    tag = "v${finalAttrs.version}";
    hash = "sha256-I4f6yKV0BXtaxnqi/XNID+Pwl2mWjSqxIHhb07U7sc4=";
  };

  vendorHash = "sha256-+uQRODO9oL8mGKBmdghTxE6R9Fz+3GJFVTi17306gT8=";

  __structuredAttrs = true;

  ldflags = [ "-s" ];

  preCheck = ''
    export HOME="$(mktemp -d)"
  '';

  checkFlags = [
    "-skip"
    "^TestIntegration"
  ];

  meta = {
    description = "The most powerful MCP Slack Server with no permission requirements, Apps support, GovSlack, DMs, Group DMs and smart history fetch logic";
    homepage = "https://github.com/korotovsky/slack-mcp-server";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ shgew ];
    mainProgram = "slack-mcp-server";
  };
})
