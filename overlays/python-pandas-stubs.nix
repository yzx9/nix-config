final: prev:

let
  inherit (prev) python3Packages;
in
{
  python3Packages = python3Packages.overrideScope (
    final': prev':

    {
      # pandas-stubs' own test suite passes generators to @pytest.mark.parametrize,
      # which pytest 9.1+ rejects at collection time (PytestRemovedIn10Warning),
      # breaking the build of every transitive dependent (pdfplumber, markitdown,
      # zotero-mcp). pytestCheckHook runs in installCheckPhase, so doCheck=false is
      # not enough -- disable the pytest hook itself. The package ships only type
      # stubs (.pyi) with no runtime code, so skipping its tests is safe.
      #
      # TODO: drop this overlay once nixpkgs-unstable carries upstream's fix
      # (commit 0f00451ae0, `pytestCheckHook = pytest9_0CheckHook`) and flake.lock
      # is bumped. As of pin 38a4887 (2026-07-27) the fix is still only on master.
      pandas-stubs = prev'.pandas-stubs.overrideAttrs {
        dontUsePytestCheck = true;
      };
    }
  );
}
