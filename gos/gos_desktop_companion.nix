args@{
  config,
  lib,
  ...
}:
{
  options = {
    desktopExternalDisplayInput = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable the virtual trackpad and keyboard companion UI and notification when connected to an external display in desktop mode.";
    };
  };

  config = lib.mkIf config.desktopExternalDisplayInput {
    source.dirs."frameworks/base".patches = [
      ./desktop-external-display-trackpad-keyboard.patch
    ];
  };
}
