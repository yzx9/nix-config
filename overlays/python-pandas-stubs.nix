# TODO: drop once nixpkgs-unstable includes NixOS/nixpkgs#540420.
# 2.3.3.260113 fails its type-stub tests against modern pandas; the PR
# bumps to 3.0.3.260530 and disables the newly-failing cases.
_inputs: final: prev: {
  python3Packages = prev.python3Packages.overrideScope (
    _final: prev': {
      pandas-stubs = prev'.pandas-stubs.overrideAttrs (old: {
        version = "3.0.3.260530";
        src = old.src.override {
          tag = "v3.0.3.260530";
          hash = "sha256-vPXz4ibNbFE2B14pkGPN5EDAwhA92VgFXzMLR9da6WQ=";
        };
        disabledTests = old.disabledTests ++ [
          "test_iceberg" # pyiceberg
          "test_timedelta_properties_methods" # DeprecationWarning: 'generic' unit for NumPy timedelta
          "test_sparse_dtype"
          "test_sparse_dtype_fill_value_subtype_compatibility"
          "test_isna"
          "test_timedelta_range"
        ];
      });
    }
  );
}
