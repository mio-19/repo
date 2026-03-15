{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      androidSdk = inputs.android-nixpkgs.sdk.${system} (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-35
        s.build-tools-35-0-0
        s.ndk-21-4-7075529
      ]);
    in
    {
      packages.forkgram = pkgs.callPackage ./forkgram {
        inherit androidSdk;
        gradle2nixBuilders = inputs.gradle2nix.builders.${system};
      };
    };
}
