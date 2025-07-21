# An emoji guide for your commit messages
# homepage: https://gitmoji.dev/
{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkIf config.purpose.dev.enable {
  home.packages = [ pkgs.gitmoji-cli ];

  home.file.".gitmojirc.json".text = lib.strings.toJSON {
    "autoAdd" = false;
    "emojiFormat" = "emoji";
    "scopePrompt" = true;
    "messagePrompt" = true;
    "capitalizeTitle" = true;
    "gitmojisUrl" = "https://gitmoji.dev/api/gitmojis";
  };
}
