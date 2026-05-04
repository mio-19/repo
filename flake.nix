{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nix-github-actions.url = "github:nix-community/nix-github-actions";
    nix-github-actions.inputs.nixpkgs.follows = "nixpkgs";
    android-nixpkgs = {
      #url = "github:tadfisher/android-nixpkgs/stable";
      # this thing cause rebuild with no real thing changed everyday. pin.
      url = "github:tadfisher/android-nixpkgs/2026-05-01-stable";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    robotnix = {
      #  --option extra-substituters https://robotnix.cachix.org --option extra-trusted-public-keys robotnix.cachix.org-1:+y88eX6KTvkJyernp1knbpttlaLTboVp4vq/b24BIv0=
      url = "git+https://github.com/nix-community/robotnix.git?shallow=1";
      #url = "github:nix-community/robotnix/grapheneos_2026-04-04";
      #url = "github:mio-19/robotnix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.androidPkgs.follows = "android-nixpkgs";
      inputs.nixpkgs-nixfmt-old.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-utils.url = "github:numtide/flake-utils";
    # https://github.com/xddxdd/nix-kernelsu-builder
    nix-kernelsu-builder = {
      url = "github:xddxdd/nix-kernelsu-builder/cc0fce340e330ad07331692b7c3673d9974be377";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pre-commit-hooks-nix.inputs.flake-compat.follows = "flake-compat";
      inputs.nur-xddxdd.inputs.treefmt-nix.follows = "treefmt-nix";
    };
    # --option extra-substituters https://nixos-apple-silicon.cachix.org --option extra-trusted-public-keys nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20=
    nixos-apple-silicon = {
      #url = "github:nix-community/nixos-apple-silicon";
      # merged with https://github.com/nix-community/nixos-apple-silicon/pull/353
      #url = "github:mio-19/nixos-apple-silicon";
      # https://github.com/nix-community/nixos-apple-silicon/issues/384
      url = "github:mio-19/nixos-apple-silicon/mio-release-2025-08-23";
      #inputs.nixpkgs.follows = "nixpkgs"; # needs to comment out this to use binary cache
      inputs.flake-compat.follows = "flake-compat";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };
    openwrt-imagebuilder = {
      url = "github:astro/nix-openwrt-imagebuilder";
      #url = "github:mio-19/nix-openwrt-imagebuilder";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.systems.follows = "flake-utils/systems";
    };
    gradle2nix = {
      url = "github:tadfisher/gradle2nix/v2";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    mvn2nix = {
      #url = "github:fzakaria/mvn2nix";
      # https://github.com/fzakaria/mvn2nix/pull/64
      url = "github:benaryorg/mvn2nix/6dc27e1897453a0efcb783094cd4522af88c09ee";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
    };
    squish-find-the-brains = {
      url = "github:7mind/squish-find-the-brains";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      imports = [
        inputs.nix-kernelsu-builder.flakeModules.default
        ./openwrt.nix
        ./robotnix.nix
        ./app
        ./mc
      ];
      perSystem =
        { pkgs, system, ... }:
        let
          inherit (pkgs) fetchpatch applyPatches;
          robotSrc = applyPatches {
            src = inputs.robotnix.outPath;
            name = "robotnix-patched";
            patches = [
            ];
          };
          robotnixPatched =
            (import "${robotSrc}/flake.nix").outputs (
              inputs.robotnix.inputs
              // {
                self = robotnixPatched;
                inherit nixpkgs;
              }
            )
            // {
              inherit (robotSrc) outPath;
            };

          gradle2nixSrc = applyPatches {
            src = inputs.gradle2nix.outPath;
            name = "gradle2nix-patched";
            patches = [
              (fetchpatch {
                name = "v2: gradleFlags: use -Dorg.gradle.console=plain";
                url = "https://github.com/tadfisher/gradle2nix/pull/92.patch";
                hash = "sha256-q9qHgFA2FHfO91ltgub+D4QmElveQ4LT0jDoz/WGdGE=";
              })
              (fetchpatch {
                name = "fix gradle 7.5 support";
                url = "https://github.com/tadfisher/gradle2nix/pull/88.patch";
                hash = "sha256-mvtKycVDJ3NMV/CPRcsWKg0irLDxYDlLRU/3X3YBB60=";
              })
            ];
          };
          gradle2nixPatched =
            (import "${gradle2nixSrc}/flake.nix").outputs (
              inputs.gradle2nix.inputs
              // {
                self = gradle2nixPatched;
                inherit nixpkgs;
              }
            )
            // {
              inherit (gradle2nixSrc) outPath;
            };

          nixpkgsSrc = applyPatches {
            src = inputs.nixpkgs;
            name = "nixpkgs-patched";
            patches = [
              (fetchpatch {
                name = "gradle: reduce keytool noise";
                url = "https://github.com/NixOS/nixpkgs/pull/472580.patch";
                hash = "sha256-dtQ8pFVnvTFwmpbMxEG9mnCbi1t6wweA1E/ufBdPsws=";
              })
            ];
            /*
              # already merged
              # https://github.com/NixOS/nixpkgs/pull/508847
              postPatch = ''
                substituteInPlace \
                  pkgs/development/tools/build-managers/gradle/setup-hook.sh \
                  --replace-fail '--console plain' '-Dorg.gradle.console=plain'
              '';
            */
          };
          nixpkgs =
            (import "${nixpkgsSrc}/flake.nix").outputs (
              inputs.nixpkgs.inputs
              // {
                self = nixpkgs;
              }
            )
            // {
              inherit (nixpkgsSrc) outPath;
            };
          pkgsPatched = import nixpkgs {
            config = pkgs.config // {
              allowUnfree = true;
            };
            inherit system;
            overlays = [
              (final: prev: rec {
                inherit (selfPackages) ant;
                maven = selfPackages.maven_3_9_14;
                gradle_9 = selfPackages.gradle_9_4_1;
                gradle_9-unwrapped = gradle_9.unwrapped;
                gradle =
                  assert prev.gradle == prev.gradle_8;
                  assert lib.versions.major prev.gradle.version == "8";
                  gradle_8;
                gradle-unwrapped =
                  assert prev.gradle-unwrapped == prev.gradle_8-unwrapped;
                  gradle_8-unwrapped;
                gradle_8 = selfPackages.gradle_8_14_4;
                gradle_8-unwrapped = gradle_8.unwrapped;
                mitm-cache =
                  assert prev.mitm-cache.fetch == prev.mitm-cache.passthru.fetch;
                  prev.mitm-cache.overrideAttrs (old: {
                    passthru = old.passthru // {
                      fetch = selfLegacyPackages.mitm-cache-fetch;
                    };
                  });
              })
            ];
          };
          inputsPatched = inputs // {
            nixpkgs = nixpkgs;
            robotnix = robotnixPatched;
            gradle2nix = gradle2nixPatched;
          };
          selfPackages = self.packages."${system}";
          selfLegacyPackages = self.legacyPackages."${system}";
          inherit (pkgsPatched) lib stdenv;
          squish-find-the-brains =
            (import "${inputs.squish-find-the-brains}/flake.nix").outputs (
              inputs.squish-find-the-brains.inputs
              // {
                self = squish-find-the-brains;
                inherit nixpkgs;
              }
            )
            // {
              inherit (inputs.squish-find-the-brains) outPath;
            };
        in
        let
          pkgs = pkgsPatched;
        in
        {
          _module.args = {
            inherit pkgsPatched squish-find-the-brains inputsPatched;
            gradle2nixPatched =
              assert pkgsPatched.mitm-cache.fetch == selfLegacyPackages.mitm-cache-fetch;
              assert pkgsPatched.mitm-cache.fetch == pkgsPatched.mitm-cache.passthru.fetch;
              gradle2nixPatched;
          };

          # nix run github:mio-19/repo#gradle2nix
          packages.gradle2nix = gradle2nixPatched.packages.${system}.gradle2nix;
          packages.gradle2nixSrc = gradle2nixPatched.outPath;
          # nix run github:mio-19/repo#mvn2nix > mvn2nix-lock.json
          packages.mvn2nix = inputs.mvn2nix.packages.${system}.mvn2nix;

          formatter = pkgs.nixfmt;

          legacyPackages."${system}".packages."${system}" = selfPackages;

          packages.github-actions-cached = pkgs.symlinkJoin {
            name = "github-actions-cached";
            paths =
              with selfPackages;
              [
                gradle2nix
                mvn2nix

                gradle_9_4_1

                apk_joplin
                apk_meditrak
                apk_sunup
              ]
              ++ lib.optionals stdenv.isLinux [
                apk_nix-on-droid
              ];
          };

          packages.garnix-cached = pkgs.symlinkJoin {
            name = "garnix-cached";
            paths =
              with selfPackages;
              [
                github-actions-cached

                apk_comaps
                apk_tailscale
                apk_pdfviewer
                apk_gamenative
                apk_droidspaces
                apk_forkgram.signScript
              ]
              ++ lib.optionals stdenv.isLinux [
                apk_immich
              ];
          };

          # https://github.com/nix-community/nixos-apple-silicon/pull/353
          packages.zfs-installer =
            (nixpkgs.lib.nixosSystem {
              inherit system;
              pkgs = import nixpkgs {
                crossSystem.system = "aarch64-linux";
                localSystem.system = system;
                overlays = [ inputs.nixos-apple-silicon.overlays.default ];
              };
              modules = [
                inputs.nixos-apple-silicon.outputs.nixosModules.apple-silicon-installer
                {
                  hardware.asahi.pkgsSystem = system;
                  nixpkgs.hostPlatform.system = "aarch64-linux";
                  nixpkgs.buildPlatform.system = system;
                }
                (
                  { pkgs, ... }:
                  {
                    boot.supportedFilesystems.zfs = true;
                    networking.hostId = "AAAAAAAA";
                    environment.systemPackages = with pkgs; [
                      git
                      rsync
                    ];
                  }
                )
              ];
            }).config.system.build.isoImage;
        };
    };
  nixConfig = {
    extra-substituters = [
      # https://garnix.io/docs/caching # garnix sometimes often 504 Gateway Time-out. to avoid waiting on this garnix, supply `--offline` to nix commands.
      "https://cache.garnix.io"
      "https://mio-repo.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "mio-repo.cachix.org-1:+l5kqQn5w9e3i3tDZY9o3pVQABC0Z/d0kAqhQpqKP8g="
    ];
  };
}
