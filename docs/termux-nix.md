# Termux Nix store

The optional `enableTermuxNix` GOS feature bundles the repository's source-built
Termux APK and bind-mounts `/data/user/0/com.termux/files/nix` at `/nix` after
the primary user's credential-encrypted storage is available. The directory is
owned by Termux's app UID, has mode `0700`, and is labeled with Termux's
per-app SELinux category. The bind mount keeps that app-data label, and Termux
uses its standard app SELinux domain so programs in the store can execute.
This is suitable for a daemonless, single-user Nix installation from Termux.

The feature exposes a writable store path; it does not install Nix or enable a
daemon. Install a Nix build supported by Termux, then use its single-user
installer. Nix's upstream `https://cache.nixos.org` substituter remains
available through the normal Nix configuration. Other upstream or Cachix
caches can be added to the user's `nix.conf` as usual.

The feature is off by default. Tangor Pro enables it. Its mount behavior and
Nix bootstrap still need validation on a device running the resulting image.
