{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      # The reMarkable Paper Pro (codename ferrari) and Paper Pro Move are
      # aarch64 with a read-only rootfs. Tablet packages are built *natively*
      # for aarch64-linux rather than cross-compiled, so the derivations are
      # the ones cache.nixos.org already has and `nix build` substitutes them
      # instead of rebuilding a toolchain. They link against /nix/store, which
      # is fine because rmpp_nix_setup gives the tablet a real store: ship the
      # closure, not a bare binary. Building on an x86_64 host needs
      # `extra-platforms = aarch64-linux` and binfmt/qemu-user (cache hits need
      # only the former); see docs/remarkable-paper-pro.md.
      rmppPkgs = import pkgs.path {
        inherit (pkgs) config;
        system = "aarch64-linux";
      };

      # Command line tools that are useful on the tablet itself. Syncthing is
      # the well-trodden way to get files on and off a Paper Pro (headless
      # daemon, web UI from another machine); the rest are quality of life.
      cliTools = with rmppPkgs; [
        syncthing
        tmux
        htop
        rsync
        strace
      ];
    in
    {
      packages = {
        # Device-side helper for a persistent Nix store at /nix, bind mounted
        # from /home/root/nix. See docs/remarkable-paper-pro.md.
        # nix build .#rmpp_nix_setup -o rmpp-nix-setup
        rmpp_nix_setup = pkgs.stdenvNoCC.mkDerivation {
          pname = "rmpp-nix-setup";
          version = "1";

          src = ./nix-setup.sh;
          dontUnpack = true;

          # Keep the #!/bin/sh shebang: this runs on the tablet, not on the
          # build host, so a nix store bash path would be wrong.
          dontPatchShebangs = true;
          installPhase = ''
            runHook preInstall
            install -Dm755 $src $out/bin/rmpp-nix-setup
            runHook postInstall
          '';

          meta = {
            description = "Set up a persistent Nix store on a reMarkable Paper Pro";
            platforms = lib.platforms.all;
          };
        };

        # rmweb (https://github.com/exp78/rmweb, MIT) is a native WPE WebKit
        # browser for the Paper Pro. This is the one prebuilt thing here:
        # upstream cross-compiles WPE WebKit and Mesa llvmpipe against the
        # reMarkable "ferrari" Yocto SDK inside a linux/arm64 Docker image
        # (hours, tens of GB), so their self-contained release bundle is the
        # only artifact that can be produced and shipped to the tablet. The
        # bundle carries every library the stock OS lacks, links against the
        # device's own Qt 6, and is deployed verbatim to /home/root/rmweb.
        # nix build .#rmpp_rmweb -o rmweb-bundle
        rmpp_rmweb = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
          pname = "rmweb";
          version = "0.9.7";

          src = pkgs.fetchurl {
            url = "https://github.com/exp78/rmweb/releases/download/v${finalAttrs.version}/rmweb-${finalAttrs.version}.tar.gz";
            hash = "sha256-jfPkIO8CmSt55UitbdccjIMkumQekkd+e9KHB5UsPo4=";
          };

          # The bundle unpacks at the top level (bin/, lib/, install.sh, ...)
          # rather than into a single rmweb-<version> directory.
          sourceRoot = ".";

          # The tree runs on the tablet, not on the build host: keep the
          # #!/bin/sh shebangs (BusyBox ash), the aarch64 ELFs and their
          # $ORIGIN RPATHs exactly as shipped.
          dontPatchShebangs = true;
          dontStrip = true;
          dontPatchELF = true;
          dontBuild = true;

          installPhase = ''
            runHook preInstall
            # The release was rolled on macOS, so the archive is littered with
            # AppleDouble metadata files; they are noise on the device.
            find . -name '._*' -delete
            mkdir -p $out
            mv ./* $out/
            runHook postInstall
          '';

          meta = {
            description = "WPE WebKit e-ink browser for the reMarkable Paper Pro";
            homepage = "https://github.com/exp78/rmweb";
            license = lib.licenses.mit;
            platforms = lib.platforms.all;
            sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
          };
        });
      }
      # Cross-compiling Linux aarch64 binaries needs a Linux host.
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        # nix build .#rmpp_tools -o rmpp-tools
        # scp -r rmpp-tools/bin root@10.11.99.1:/home/root/rmpp-tools
        rmpp_tools = pkgs.symlinkJoin {
          name = "rmpp-tools";
          paths = cliTools;
          pathsToLink = [ "/bin" ];
          meta = {
            description = "Command line tools for the reMarkable Paper Pro";
            # The symlink tree itself builds anywhere; the tools it points at
            # are aarch64-linux derivations.
            platforms = lib.platforms.all;
          };
        };
      };
    };
}
