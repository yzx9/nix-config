{
  description = "Rust project with WebAssembly";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, fenix, ... }:

    let
      inherit (nixpkgs) lib;

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSystem = systems: f: lib.genAttrs systems f;
      forEachSupportedSystem = forEachSystem supportedSystems;
    in
    {
      # nix develop
      devShells = forEachSupportedSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ fenix.overlays.default ];
          };
          target = "wasm32-unknown-unknown";
          fenix' = fenix.packages.${system};
          toolchain = fenix'.complete;
          buildInputs = with pkgs; [
            # rust
            (fenix'.combine [
              toolchain.cargo
              toolchain.rustc
              toolchain.rust-src
              toolchain.clippy
              toolchain.rustfmt
              fenix'.targets.${target}.latest.rust-std
            ])
            rust-analyzer
            pkg-config
            openssl
            wasm-pack
          ];
        in
        {
          default = pkgs.mkShell {
            inherit buildInputs;

            shellHook = ''
              # Specify the rust-src path (many editors rely on this)
              export RUST_SRC_PATH="${toolchain.rust-src}/lib/rustlib/src/rust/library";
            '';
          };
        }
      );
    };
}
