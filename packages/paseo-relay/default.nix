{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "paseo-relay";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "zenghongtu";
    repo = "paseo-relay";
    tag = "v${finalAttrs.version}";
    hash = "sha256-nu7SkS5DpGQSM+qm/KAEzeX+SqUOsYBdwDZpzG+YJF4=";
  };

  vendorHash = "sha256-0Qxw+MUYVgzgWB8vi3HBYtVXSq/btfh4ZfV/m1chNrA=";

  meta = {
    description = "Self-hosted relay server for Paseo";
    homepage = "https://github.com/zenghongtu/paseo-relay";
    license = lib.licenses.agpl3Plus;
    maintainers = with lib.maintainers; [ yzx9 ];
    mainProgram = "paseo-relay";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
