{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  uv-build,
  bibtexparser,
  click,
  feedparser,
  httpx,
  mcp,
  pytest-asyncio,
  pytest-cov-stub,
  pytestCheckHook,
  python-dateutil,
  pytz,
  whenever,
}:

buildPythonPackage (finalAttrs: {
  pname = "pyzotero";
  version = "1.11.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "urschrei";
    repo = "pyzotero";
    tag = "v${finalAttrs.version}";
    hash = "sha256-3pOdSoVSE3XhQ1Vy3/KiSGd3Yr+DBO4+wyfTtHEUTso=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'uv_build>=0.8.14,<0.9.0' 'uv_build'
  '';

  build-system = [ uv-build ];

  dependencies = [
    bibtexparser
    click
    feedparser
    httpx
    mcp
    whenever
  ];

  nativeCheckInputs = [
    pytest-asyncio
    pytest-cov-stub
    pytestCheckHook
    python-dateutil
    pytz
  ];

  pythonImportsCheck = [ "pyzotero" ];

  meta = {
    description = "Python wrapper for the Zotero API";
    homepage = "https://github.com/urschrei/pyzotero";
    changelog = "https://github.com/urschrei/pyzotero/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.blueOak100;
    maintainers = with lib.maintainers; [ yzx9 ];
  };
})
