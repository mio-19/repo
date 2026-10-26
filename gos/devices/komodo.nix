{
  imports = [
    ./caiman.nix
    ../gos_komodo_high_emission_frequency.nix
  ];
  config = {
    device = "komodo";
    #launcherVariant = "los";
  };
}
