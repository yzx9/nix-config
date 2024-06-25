{ pkgs, ... }:

{
  home.packages = with pkgs; [
    go
    gotools
    gopls
    golangci-lint
    golangci-lint-langserver
    delve
  ];

  programs.helix.languages.language = [
    {
      name = "go";
      auto-format = true;
      formatter.command = "goimports";
    }
  ];
}
