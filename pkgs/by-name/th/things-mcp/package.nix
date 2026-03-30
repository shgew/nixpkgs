{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "things-mcp";
  version = "0.7.3";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "hald";
    repo = "things-mcp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-h4DQUS1Now4QKQKVpaeirFQx2e57HhvNCUYeMld0c9M=";
  };

  build-system = with python3Packages; [
    hatchling
  ];

  dependencies = with python3Packages; [
    httpx
    fastmcp
    things-py
  ];

  # Tests require a Things 3 database on macOS
  doCheck = false;

  meta = {
    description = "Model Context Protocol server for Things 3 task manager";
    homepage = "https://github.com/hald/things-mcp";
    changelog = "https://github.com/hald/things-mcp/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ shgew ];
    mainProgram = "things-mcp";
  };
})
