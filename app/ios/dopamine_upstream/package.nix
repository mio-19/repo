{ dopamine }:

# Vanilla opa334 Dopamine (no WebKitPlayground DYLD_FRAMEWORK_PATH patches).
#   nix build .#ios_dopamine_upstream
dopamine.override { withWebKitPlaygroundPatches = false; }
