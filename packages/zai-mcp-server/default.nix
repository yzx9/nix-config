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
    substituteInPlace package.json \
      --replace-fail '"@modelcontextprotocol/sdk": "1.17.5"' '"@modelcontextprotocol/sdk": "1.26.0"'

    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-55NJI3KsvBo3tufhLyGkelMAlattli2U65RS1KLuMyc=";

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
