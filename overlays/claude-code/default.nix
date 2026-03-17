{ ... }:

final: prev:

{
  claude-code = prev.claude-code.overrideAttrs (
    finalAttrs: prevAttrs: {
      version = "2.1.76";

      src = prevAttrs.src.overrideAttrs {
        url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${finalAttrs.version}.tgz";
        hash = "sha256-kjzPTG32f35eN6S85gGLUCmsNwH70Sq5rruEs/0hioM=";
      };

      npmDeps = prev.fetchNpmDeps {
        src = prev.lib.fileset.toSource {
          root = ./.;
          fileset = prev.lib.fileset.unions [
            ./package-lock.json
          ];
        };
        name = "${finalAttrs.pname}-${finalAttrs.version}-npm-deps";
        hash = finalAttrs.npmDepsHash;
      };

      npmDepsHash = "sha256-sk1RdPMgZD+Ejd6JdKWcK24AdfasnwWATQkwAx5MjmY=";

      postPatch = (prevAttrs.postPatch or "") + ''
        rm package-lock.json
        cp ${./package-lock.json} package-lock.json
      '';
    }
  );
}
