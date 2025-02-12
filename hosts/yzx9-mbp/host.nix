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
      "microsoft-outlook" # email
      "onedrive" # cloud storage

      # misc
      "logitech-options" # mouse
      "steam" # game
      "vmware-fusion" # virtual machine
      "vial" # keyboard
      "bambu-studio" # 3d ptinter
    ];
  };
}
