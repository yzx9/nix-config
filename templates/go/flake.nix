{
  description = "Go project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
    }:
    let
      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "197001010000";

      # Generate a user-friendly version number.
      version = builtins.substring 0 12 lastModifiedDate;

      # Helper function to generate an attrset
      eachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      # nix build .#<package_name>
      # nix run .#<package_name>
      packages = eachSystem (
        system:

        let
          pkgs = nixpkgs.legacyPackages.${system};
          fs = pkgs.lib.fileset;
          pname = "YOUR_APP";
        in
        {
          # The default package for 'nix build'. This makes sense if the
          # flake provides only one package or there is a clear "main"
          # package.
          default = self.packages.${system}.pname;

          ${pname} = pkgs.buildGoModule {
            inherit pname version;

            # In 'nix develop', we don't need a copy of the source tree
            # in the Nix store.
            src = fs.toSource {
              root = ./.;
              fileset = fs.unions [
                ./go.mod
                ./go.sum
                # NOTE: add your file here
              ];
            };

            # This hash locks the dependencies of this package. It is
            # necessary because of how Go requires network access to resolve
            # VCS. See https://www.tweag.io/blog/2021-03-04-gomod2nix/ for
            # details. Normally one can build with a fake hash and rely on native Go
            # mechanisms to tell you what the hash should be or determine what
            # it should be "out-of-band" with other tooling (eg. gomod2nix).
            # To begin with it is recommended to set this, but one must
            # remember to bump this hash when your dependencies change.
            # vendorHash = pkgs.lib.fakeHash;
            vendorHash = "sha256-00000000000000000000000000000000000000000000";

            CGO_ENABLED = 0;
          };

          "${pname}-docker" =
            let
              overrideAttrsOrNot =
                cond: p: attrs:
                if cond then (p.overrideAttrs attrs) else p;

              app = overrideAttrsOrNot (system != "x86_64-linux") self.packages.${system}.server (
                old:
                old
                // {
                  doCheck = false; # skip check in cross compile
                  GOOS = "linux";
                  GOARCH = "amd64";
                  postInstall = ''
                    mv $out/bin/linux_amd64/* $out/bin/
                    rmdir $out/bin/linux_amd64
                  '';
                }
              );
            in
            pkgs.dockerTools.buildImage {
              name = pname;
              config = {
                User = "1500:1500";
                Cmd = [ "${app}/bin/${pname}" ];
              };
            };
        }
      );

      # nix develop .
      devShells = eachSystem (
        system:

        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              go
              gopls
              gotools
              go-tools
            ];
          };
        }
      );
    };
}
