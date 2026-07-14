{
  lib,
  buildNpmPackage,
  fetchurl,
}:

buildNpmPackage (finalAttrs: {
  pname = "tavily-mcp";
  version = "0.2.21";

  src = fetchurl {
    url = "https://registry.npmjs.org/tavily-mcp/-/tavily-mcp-${finalAttrs.version}.tgz";
    hash = "sha256-kjD7sWzjCbLbNwRgbXxNHBOd9UG55ICMdZEI5naX1Pc=";
  };

  # The published npm tarball ships the prebuilt build/index.js but, like all
  # npm packages, omits the lockfile. Vendor it from the upstream source so
  # buildNpmPackage can resolve and fetch the runtime dependencies.
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-EWs6hTEk8PtKzlSe13Smssd3aB2HzDe3h/meqkBOXrY=";
  npmDepsFetcherVersion = 2;

  dontNpmBuild = true;
  npmPackFlags = [ "--ignore-scripts" ];

  meta = {
    description = "MCP server for advanced web search using Tavily";
    homepage = "https://github.com/tavily-ai/tavily-mcp";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ yzx9 ];
    mainProgram = "tavily-mcp";
  };
})
