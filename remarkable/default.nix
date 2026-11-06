{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      # The reMarkable Paper Pro (codename ferrari) is aarch64 and runs a Yocto
      # glibc userland with a read-only rootfs. Fully static musl builds are the
      # least surprising thing to drop into /home/root: they depend on nothing
      # from the device besides the kernel. Note that plain
      # "aarch64-multiplatform-musl" still links against the musl dynamic
      # loader from the store, which does not exist on the tablet, so pkgsStatic
      # is required here.
      rmppPkgs = pkgs.pkgsCross.aarch64-multiplatform-musl.pkgsStatic;

      # Command line tools that are useful on the tablet itself. Syncthing is
      # the well-trodden way to get files on and off a Paper Pro (headless
      # daemon, web UI from another machine); the rest are quality of life.
      cliTools = [
        rmppPkgs.syncthing
        rmppPkgs.tmux
        rmppPkgs.htop
        rmppPkgs.rsync
        rmppPkgs.strace
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
            description = "Static aarch64 command line tools for the reMarkable Paper Pro";
            platforms = lib.platforms.all;
          };
        };
      };
    };
}
