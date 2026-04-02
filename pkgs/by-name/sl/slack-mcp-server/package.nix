{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "slack-mcp-server";
  version = "1.2.3";

  src = fetchFromGitHub {
    owner = "korotovsky";
    repo = "slack-mcp-server";
    tag = "v${finalAttrs.version}";
    hash = "sha256-AfmuQfV3RqFBw9b8B4aFM0EOuFQrUlUpTnMmQcyvCfU=";
  };

  vendorHash = "sha256-mR+UFQRi98OTCyNISy3e7QTGKusd8XhNW4iz57QvpZE=";

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
