{ config, lib, ... }:

let
  # Homebrew Mirror
  homebrew_mirror_env = {
    HOMEBREW_API_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api";
    HOMEBREW_BOTTLE_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles";
    HOMEBREW_BREW_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git";
    HOMEBREW_CORE_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git";
    HOMEBREW_PIP_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple";
  };
in
{
  # Set variables for you to manually install homebrew packages.
  # environment.variables = homebrew_mirror_env;

  # Set environment variables for nix-darwin before run `brew bundle`.
  system.activationScripts.homebrew.text =
    let
      env_script = lib.attrsets.foldlAttrs (
        acc: name: value:
        acc + "\nexport ${name}=${value}"
      ) "" homebrew_mirror_env;
    in
    lib.mkBefore ''
      echo >&2 '${env_script}'
      ${env_script}
    '';

  # To make this work, homebrew need to be installed manually, see https://brew.sh
  #
  # The apps installed by homebrew are not managed by nix, and not reproducible!
  # But on macOS, homebrew has a much larger selection of apps than nixpkgs, especially for GUI apps!
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      cleanup = "zap"; # 'zap': uninstalls all formulae(and related files) not listed here.
    };

    taps = [ ];

    # `brew install`
    brews = [ ];

    # `brew install --cask`
    casks =
      let
        inherit (config.purpose) daily gui;
      in
      lib.optionals daily [
        "canon-ufrii-driver" # printer
      ]
      ++ lib.optionals gui [
        "middleclick" # mouse
        "snipaste" # screen shot
      ]
      ++ lib.optionals (daily && gui) [
        # productivity
        "eudic" # dictionary
        "microsoft-word"
        "microsoft-excel"
        "microsoft-powerpoint"
        "microsoft-outlook" # email
        "onedrive" # cloud storage
        "tencent-meeting" # video conference
        "visual-studio-code" # editor
        "logseq" # knowledge base # NOTE: nixpkgs's logseq not working, so we add a cask here

        # science
        "fiji" # image viewer
        # "master-pdf-editor"
        "zotero"

        # design
        "krita" # 2D design
        "blender" # 3D design
        "bambu-studio" # 3D ptinter

        # misc
        "google-chrome" # browser
        "scroll-reverser" # mouse
        "steam" # game
        "vmware-fusion" # virtual machine
        "vial" # keyboard
        "wechat" # chat
      ];
  };
}
