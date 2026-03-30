{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "things-py";
  version = "1.0.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "thingsapi";
    repo = "things.py";
    tag = "v${finalAttrs.version}";
    hash = "sha256-wtPll3GSuo8C+b156ZmhztreDJ5QTWm1dX9MPXj10Gw=";
  };

  build-system = [ setuptools ];

  # Remove py2app dependency - only needed for macOS .app bundling
  postPatch = ''
    substituteInPlace setup.py \
      --replace-fail 'setup_requires=["py2app"],' ""
  '';

  pythonImportsCheck = [ "things" ];

  # Tests require a Things 3 database on macOS
  doCheck = false;

  meta = {
    description = "Python 3 library to read your Things app data";
    homepage = "https://github.com/thingsapi/things.py";
    changelog = "https://github.com/thingsapi/things.py/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ shgew ];
  };
})
