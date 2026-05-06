_inputs:

final: prev:

let
  inherit (prev) lib python3Packages;
in
{
  python3Packages = python3Packages.overrideScope (
    final': prev':

    {
      pyzotero = prev'.toPythonModule (prev.python3Packages.callPackage ../packages/pyzotero { });
    }
    // (lib.optionalAttrs prev.stdenv.hostPlatform.isAarch64 {
      # lupa depends on luajit, which doesn't support aarch64.
      # Provide a dummy so fastmcp (which has lupa in nativeCheckInputs) can evaluate.
      lupa = prev'.toPythonModule (prev.runCommand "lupa-dummy" { } "mkdir $out");

      fastmcp = prev'.fastmcp.overrideAttrs {
        nativeCheckInputs = [ ];
        doCheck = false;
      };
    })
  );
}
