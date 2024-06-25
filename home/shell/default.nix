{ username, ... }:

{
  imports = [
    ./alacritty.nix # terminal
    ./zellij.nix # terminal multiplexer
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };

  programs.nushell = {
    enable = true;
    extraConfig = ''
      let carapace_completer = {|spans|
        carapace $spans.0 nushell $spans | from json
      }
      $env.config = {
        show_banner: false,
        completions: {
          case_sensitive: false # case-sensitive completions
          quick: true           # set to false to prevent auto-selecting completions
          partial: true         # set to false to prevent partial filling of the prompt
          algorithm: "fuzzy"    # prefix or fuzzy
          external: {
              enable: true      # set to false to prevent nushell looking into $env.PATH to find more suggestions
              max_results: 100  # set to lower can improve completion performance at the cost of omitting some options
              completer: $carapace_completer # check 'carapace_completer'
          }
        }
      }
      #$env.PATH = ($env.PATH |
      #  split row (char esep) |
      #  prepend /home/${username}/.apps |
      #  append /usr/bin/env
      #)
      def nuopen [arg, --raw (-r)] { if $raw { open -r $arg } else { open $arg } }
      alias open = ^open
    '';
  };

  # auto-completion for nushell
  programs.carapace = {
    enable = true;
    enableNushellIntegration = true;
  };

  # prompt
  programs.starship = {
    enable = true;

    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;

    settings = {
      character = {
        success_symbol = "[›](bold green)";
        error_symbol = "[›](bold red)";
      };
    };
  };

  #   home.shellAliases = {};
}
