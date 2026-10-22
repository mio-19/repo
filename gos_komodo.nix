{
  imports = [
    ./gos_caiman.nix
    ./gos/gos_komodo_high_emission_frequency.nix
  ];
  config = {
    device = "komodo";
    #launcherVariant = "los";
  };
}
