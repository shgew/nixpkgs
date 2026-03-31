{
  lib,
  python3,
  fetchFromGitHub,
}:

python3.pkgs.buildPythonApplication (finalAttrs: {
  pname = "things3-mcp";
  version = "2.0.7";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "rossshannon";
    repo = "Things3-MCP";
    tag = "v${finalAttrs.version}";
    hash = "sha256-mzsam1UuQfqCN0QsUV9jbqwX9CNoLusYsmhKPmL855A=";
  };

  build-system = [
    python3.pkgs.hatchling
  ];

  dependencies = with python3.pkgs; [
    httpx
    mcp
    things-py
  ];

  pythonImportsCheck = [
    "things3_mcp"
  ];

  meta = {
    description = "MCP server for Things 3 with read/write support for tasks, projects, areas and tags";
    homepage = "https://github.com/rossshannon/Things3-MCP";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "Things3-MCP-server";
  };
})
