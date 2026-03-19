{
  lib,
  buildNpmPackage,
  fetchurl,
}:

buildNpmPackage (finalAttrs: {
  pname = "zai-mcp-server";
  version = "0.1.2";

  src = fetchurl {
    url = "https://registry.npmjs.org/@z_ai/mcp-server/-/mcp-server-${finalAttrs.version}.tgz";
    hash = "sha256-etfPQbfzihM84MM25xE7uFxz5jUhRRFMwn6jOEhL4QY=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-bPljAkpO+Rh4fXRVIrSSIdlUaWMEINcjFqtnC/z3eTo=";

  dontNpmBuild = true;
  npmPackFlags = [ "--ignore-scripts" ];

  meta = {
    description = "Model Context Protocol (MCP) server that provides AI capabilities powered by Z.AI";
    homepage = "https://docs.z.ai/";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ yzx9 ];
    mainProgram = "zai-mcp-server";
  };
})
