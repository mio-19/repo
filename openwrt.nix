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
            # https://github.com/astro/nix-openwrt-imagebuilder/issues/53
            "luci"
            # btop tmux curl nano diffutils git git-lfs git-http: for me
            "btop"
            "tmux"
            "curl"
            "nano"
            "diffutils"
            "git"
            "git-lfs"
            "git-http"
            "tailscale"
            "luci-app-aria2"
            "luci-app-irqbalance"
            "luci-app-https-dns-proxy"
            "docker"
            "dockerd"
            "luci-app-dockerman"
            # shadow : try out nix/lix
            "shadow"
            # kmod-fs-btrfs btrfs-progs kmod-usb-storage kmod-usb-storage-uas block-mount parted : usb storage - https://openwrt.org/docs/guide-user/additional-software/extroot_configuration
            "kmod-fs-btrfs"
            "btrfs-progs"
            "kmod-usb-storage"
            "kmod-usb-storage-uas"
            "block-mount"
            "parted"
          ];

          disabledServices = [ ];

          # include files in the images.
          # to set UCI configuration, create a uci-defauts scripts as per
          # official OpenWRT ImageBuilder recommendation.
          files = pkgs.runCommand "image-files" { } "mkdir -p $out";
        };

      in
      openwrt-imagebuilder.lib.build config;
  };
}
