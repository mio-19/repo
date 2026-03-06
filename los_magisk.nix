# based on https://github.com/nix-community/robotnix/pull/266
args@{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    mkForce
    types
    optionalString
    ;

  cfg = config.magisk;
  otaTools = config.build.otaTools;

  # Keep this wrapper logic in sync with robotnix modules/release.nix:wrapScript.
  # We duplicate it here because Magisk needs a custom img/release flow, but the
  # signing env and tool PATH should otherwise behave the same as upstream.
  wrapScript =
    {
      commands,
      keysDir,
      verifyKeys,
    }:
    let
      jre = if (config.androidVersion >= 11) then pkgs.jdk11_headless else pkgs.jre8_headless;
      deps = with pkgs; [
        otaTools
        openssl
        jre
        zip
        unzip
        getopt
        which
        toybox
        vboot_reference
        util-linux
        python3
        bash
      ];
    in
    ''
      export PATH=${lib.makeBinPath deps}:$PATH
      export EXT2FS_NO_MTAB_OK=yes

      export KEYSDIR=${keysDir}
      if [[ "$KEYSDIR" ]]; then
        if [[ ! -d "$KEYSDIR" ]]; then
          echo "Signing keys dir $KEYSDIR is missing."
          exit 1
        fi
        ${optionalString verifyKeys "${config.build.verifyKeysScript} \"$KEYSDIR\" || exit 1"}
        NEW_KEYSDIR=$(mktemp -d /dev/shm/robotnix_keys.XXXXXXXXXX)
        trap "rm -rf \"$NEW_KEYSDIR\"" EXIT
        cp -r "$KEYSDIR"/* "$NEW_KEYSDIR"
        chmod u+w -R "$NEW_KEYSDIR"
        KEYSDIR=$NEW_KEYSDIR
      fi

      ${commands}
    '';

  runWrappedCommandWithTestKeys =
    name: script: args:
    pkgs.runCommand "${config.device}-${name}-${config.buildNumber}.zip" { } (wrapScript {
      commands = script (args // { out = "$out"; });
      keysDir = config.source.dirs."build/make".src + /target/product/security;
      verifyKeys = false;
    });

  signedTargetFilesName = "${config.device}-signed_target_files-${config.buildNumber}.zip";

  # Keep in sync with robotnix modules/release.nix:signedTargetFilesScript.
  signedTargetFilesScript =
    { targetFiles, out }:
    ''
      ( OUT=$(realpath ${out})
        ${lib.getExe pkgs.signing-validator} ${
          toString (config.signing.apkFlags ++ config.signing.apexFlags)
        } ${targetFiles}
        cd ${otaTools}
        sign_target_files_apks \
          -o ${toString config.signing.signTargetFilesArgs} \
          ${targetFiles} $OUT
      )
    '';

  # Keep in sync with robotnix modules/release.nix:otaScript.
  otaScript =
    {
      targetFiles,
      prevTargetFiles ? null,
      out,
      otaKey,
    }:
    ''
      ota_from_target_files  \
        -k "${otaKey}" \
        ${toString config.otaArgs} \
        ${optionalString (prevTargetFiles != null) "-i ${prevTargetFiles}"} \
        ${targetFiles} ${out}
    '';

  # Custom to this module: patch boot.img inside target_files using Magisk, then
  # hand the modified archive to img_from_target_files.
  magiskImgScript =
    { targetFiles, out }:
    ''
      targetFiles="$(pwd)/targetFiles.zip"
      cp ${targetFiles} "$targetFiles"
      chmod +w "$targetFiles"

      (
        mkdir magisk
        cd magisk

        unzip ${cfg.apk}

        ln -sr assets/*.sh .
        ln -sr assets/stub.apk .

        # Use target-arch Magisk userspace bits and host-arch magiskboot.
        for file in lib/arm64-v8a/lib*.so lib/x86_64/libmagiskboot.so; do
          name="$(basename "$file")"
          dest="''${name:3:-3}"
          ln -srfn "$file" "$dest"
          chmod +x "$file"
        done

        unzip "$targetFiles" IMAGES/boot.img

        export BOOTMODE=true
        PATH="$(pwd):${pkgs.writeShellScriptBin "getprop" "echo \"$@\""}/bin:$PATH" \
          bash boot_patch.sh IMAGES/boot.img
        mv new-boot.img IMAGES/boot.img

        zip "$targetFiles" IMAGES/boot.img
      )

      img_from_target_files "$targetFiles" ${out}
    '';

  # Keep in sync with robotnix modules/release.nix:factoryImgScript.
  factoryImgScript =
    {
      targetFiles,
      img,
      out,
    }:
    ''
      ln -s ${targetFiles} ${config.targetFilesName} || true
      ln -s ${img} ${config.device}-img-${config.buildNumber}.zip || true

      export DEVICE=${config.device}
      export PRODUCT=${config.device}
      export BUILD=${config.buildNumber}
      export VERSION=${lib.toLower config.buildNumber}

      get_radio_image() {
        ${lib.getBin pkgs.unzip}/bin/unzip -p ${targetFiles} OTA/android-info.txt \
          | grep "require version-$1" | cut -d'=' -f2 | tr '[:upper:]' '[:lower:]' || exit 1
      }
      export BOOTLOADER=$(get_radio_image bootloader)
      export RADIO=$(get_radio_image baseband)

      export PATH=${lib.getBin pkgs.zip}/bin:${lib.getBin pkgs.unzip}/bin:$PATH
      ${pkgs.runtimeShell} ${config.source.dirs."device/common".src}/generate-factory-images-common.sh
      mv $PRODUCT-factory-$VERSION.zip ${out}
    '';
in
{
  options.magisk = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Patch boot.img inside LOS img/factory artifacts using Magisk.";
    };
    apk = mkOption {
      type = types.path;
      default = pkgs.fetchurl {
        url = "https://github.com/topjohnwu/Magisk/releases/download/v29.0/Magisk-v29.0.apk";
        hash = "sha256-mdQN8aaKBaXnhFKpzU8tdTQ012IrrutE6hSugjjBqco=";
      };
      description = "Magisk APK used as the source of boot_patch.sh and Magisk binaries.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.flavor == "lineageos";
        message = "magisk.enable is currently only intended for LineageOS builds";
      }
    ];

    build.img = mkForce (
      runWrappedCommandWithTestKeys "img" magiskImgScript {
        targetFiles = config.build.targetFiles;
      }
    );

    build.factoryImg = mkForce (
      runWrappedCommandWithTestKeys "factory" factoryImgScript {
        targetFiles = config.build.targetFiles;
        img = config.build.img;
      }
    );

    # Keep this in sync with robotnix modules/release.nix:config.build.releaseScript.
    # The only intended behavioral difference is the ".img file" step using
    # magiskImgScript before building the factory image.
    build.releaseScript = mkForce (
      pkgs.writeShellScript "release.sh" (
        ''
          set -euo pipefail

          if [[ $# -ge 2 ]]; then
            PREV_BUILDNUMBER="$2"
          else
            PREV_BUILDNUMBER=""
          fi
        ''
        + (wrapScript {
          keysDir = "$1";
          verifyKeys = true;
          commands = ''
            echo Signing target files
            ${signedTargetFilesScript {
              targetFiles = config.build.targetFiles;
              out = signedTargetFilesName;
            }}
            echo Building OTA zip
            ${otaScript {
              otaKey = "$KEYSDIR/${config.device}/releasekey";
              targetFiles = signedTargetFilesName;
              out = config.build.ota.name;
            }}
            if [[ ! -z "$PREV_BUILDNUMBER" ]]; then
              echo Building incremental OTA zip
              ${otaScript {
                targetFiles = signedTargetFilesName;
                prevTargetFiles =
                  "${config.device}-target_files"
                  + optionalString (config.androidVersion < 14) "-$PREV_BUILDNUMBER.zip";
                out = "${config.device}-incremental${
                  optionalString (config.androidVersion < 14) "-$PREV_BUILDNUMBER-${config.buildNumber}"
                }.zip";
                otaKey = "$KEYSDIR/${config.device}/releasekey";
              }}
            fi
            echo Building .img file
            ${magiskImgScript {
              targetFiles = signedTargetFilesName;
              out = config.build.img.name;
            }}
            echo Building factory image
            ${factoryImgScript {
              targetFiles = signedTargetFilesName;
              img = config.build.img.name;
              out = config.build.factoryImg.name;
            }}
          ''
          + optionalString config.apps.updater.enable ''
            echo Writing updater metadata
            sed -e "s:\"ROM_SIZE\":$(du -b ${config.build.ota.name} | cut -f1):" ${config.build.otaMetadata} > ./lineageos-${config.device}.json
          '';
        })
      )
    );
  };
}
