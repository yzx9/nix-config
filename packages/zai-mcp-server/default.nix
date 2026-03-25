{
  lib,
  buildNpmPackage,
  fetchurl,
}:

buildNpmPackage (finalAttrs: {
  pname = "zai-mcp-server";
  version = "0.1.3";

  src = fetchurl {
    url = "https://registry.npmjs.org/@z_ai/mcp-server/-/mcp-server-${finalAttrs.version}.tgz";
    hash = "sha256-wSmCWR44HHfb34X9u7Y0w4z+PSFFUCG7q4lrevuTrUY=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-Smpbac6Ded99buABK+AobWbXaTHMQYbDYm131XQ31XU=";
  npmDepsFetcherVersion = 2;

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
