{ ... }:

final: prev:

{
  inkscape = prev.inkscape.overrideAttrs (
    finalAttrs: prevAttrs: {
      preFixup = (prevAttrs.preFixup or "") + ''
        gappsWrapperArgs+=(
          --prefix XDG_DATA_DIRS : "${prev.hicolor-icon-theme}/share" # or adwaita-icon-theme
        )
      '';
    }
  );
}
