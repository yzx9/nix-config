# Gitmoji: An emoji guide for your commit messages
# homepage: https://gitmoji.dev/

{
  config,
  pkgs,
  lib,
  ...
}:

let
  toJSON = lib.generators.toJSON { };

  gitmoji = pkgs.fetchFromGitHub {
    owner = "carloscuesta";
    repo = "gitmoji";
    tag = "v3.15.0";
    hash = "sha256-qqias3MHI5OiJvdfhPL9i6UtBbmIGnUV7f8Jw4zomKA=";
  };

  # NOTE: We need to import the JSON file at build time, otherwise the gitmoji-cli
  # package will fail to build because it won't find the gitmojis.json file at runtime
  data = lib.importJSON "${gitmoji}/packages/gitmojis/src/gitmojis.json";
in
lib.mkIf config.purpose.dev.enable {
  home.packages = [ pkgs.gitmoji-cli ];

  home.file.".gitmojirc.json".text = toJSON {
    autoAdd = false;
    emojiFormat = "emoji";
    scopePrompt = true;
    messagePrompt = true;
    capitalizeTitle = true;
    gitmojisUrl = "https://gitmoji.dev/api/gitmojis";
  };

  home.file.".gitmoji/gitmojis.json".text = toJSON data.gitmojis;
}
