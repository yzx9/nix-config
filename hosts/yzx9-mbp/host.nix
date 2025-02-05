{
  imports = [ ./linux-builder.nix ];

  homebrew = {
    casks = [
      # science
      "zotero"
      # "master-pdf-editor"
      "fiji"

      # design
      "blender"
      "krita"
      "inkscape"

      # misc
      "logitech-options" # mouse
      "steam" # game
      "vmware-fusion" # virtual machine
      "vial" # keyboard
      "bambu-studio" # 3d ptinter
    ];
  };
}
