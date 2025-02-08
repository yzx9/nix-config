{
  imports = [ ./linux-builder.nix ];

  homebrew = {
    casks = [
      # science
      "zotero"
      # "master-pdf-editor"
      "fiji" # image viewer

      # design
      "blender"
      "krita"
      "inkscape"

      # productivity
      "tencent-meeting" # video conference
      "microsoft-word"
      "microsoft-excel"
      "microsoft-powerpoint"
      # I wish to use these in homebrew, but the migration is not easy
      # "microsoft-outlook"
      # "onedrive"

      # misc
      "logitech-options" # mouse
      "steam" # game
      "vmware-fusion" # virtual machine
      "vial" # keyboard
      "bambu-studio" # 3d ptinter
    ];
  };
}
