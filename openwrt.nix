{
  withSystem,
  inputs,
  ...
}:
let
  inherit (inputs) nixpkgs openwrt-imagebuilder;
in
{
  flake = {

    packages.x86_64-linux.flient2 =
      let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;

        profiles = openwrt-imagebuilder.lib.profiles { inherit pkgs; };

        config = profiles.identifyProfile "glinet_gl-mt6000" // {
          # add package to include in the image, ie. packages that you don't
          # want to install manually later
          packages = [
            "tmux"
            "curl"
            "nano"
            "diffutils"
            "tailscale"
            "luci-app-aria2"
            "luci-app-irqbalance"
            "luci-app-https-dns-proxy"
            "docker"
            "dockerd"
            "luci-app-dockerman"
            "shadow"
          ];

          disabledServices = [ ];

          # include files in the images.
          # to set UCI configuration, create a uci-defauts scripts as per
          # official OpenWRT ImageBuilder recommendation.
          files = pkgs.runCommand "image-files" { } "";
        };

      in
      openwrt-imagebuilder.lib.build config;
  };
}
