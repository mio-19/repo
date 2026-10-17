{
  imports = [ ./gos_caiman.nix ];
  config = {
    device = "komodo";
    enableLindroid = true;
    #launcherVariant = "los";
  };
}
