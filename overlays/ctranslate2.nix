{ nixpkgs, ... }:

final: prev:

# Workaround: nixpkgs ctranslate2 source hash is stale (upstream re-tagged v4.8.1).
# https://github.com/OpenNMT/CTranslate2
nixpkgs.lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
  ctranslate2 = prev.ctranslate2.overrideAttrs {
    src = final.fetchFromGitHub {
      owner = "OpenNMT";
      repo = "CTranslate2";
      tag = "v${prev.ctranslate2.version}";
      fetchSubmodules = true;
      hash = "sha256-cchwv+esysn/0v6RqD5zp306HfzOjjlCxH5usLETXs0=";
    };
  };
}
