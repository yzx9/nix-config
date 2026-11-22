final: prev:

let
  version = "20.1.0";
in
{
  # Backport of NixOS/nixpkgs#591637. Drop once our nixpkgs pin includes it.
  super-productivity =
    if prev.lib.versionOlder prev.super-productivity.version version then
      prev.super-productivity.overrideAttrs (
        finalAttrs: old: {
          inherit version;

          src = final.fetchFromGitHub {
            owner = "super-productivity";
            repo = "super-productivity";
            tag = "v${finalAttrs.version}";
            hash = "sha256-w6vPWekIHow9if1pULoqEezTK7tvp5xGQ3XGLzBVCmU=";
          };

          npmDeps = old.npmDeps.overrideAttrs (_: {
            outputHash = "sha256-0W7LWxsyQQ/qtmD6pPgL7K27ayTR2xFWltqG0mN3bDQ=";
          });

          meta = old.meta // {
            maintainers = old.meta.maintainers ++ [ final.lib.maintainers.yzx9 ];
          };
        }
      )
    else
      prev.super-productivity;
}
