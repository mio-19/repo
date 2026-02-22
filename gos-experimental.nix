args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  /*
    # WIP: ERROR: building adevtool dependencies: Or did you mean ["libdisk"]
    source.dirs."bootable/recovery" = lib.mkForce {
      src = pkgs.fetchFromGitHub {
        owner = "LineageOS";
        repo = "android_bootable_recovery";
        rev = "833e2948bfe4bbfbf73796391a9336850108e7bd";
        hash = "sha256-QFrwYPZ6Vt/KoUaHWd7w72KB7s4SeYQ2xFoymgi7JeE=";
      };
    };
    source.dirs."build/soong".patches = with pkgs; [
      # required for export_cflags
      (fetchpatch {
        name = "soong: Add equivalent for LOCAL_EXPORT_CFLAGS";
        url = "https://github.com/LineageOS/android_build_soong/commit/25aa912a6cadab1f47753c719b05c6596022c5f8.patch";
        hash = "sha256-o+nQlmA8RoVRxrSYqSJoJQh725RVJLp5J9SUILX0bHA=";
      })
    ];
  */
  source.dirs."bootable/recovery".patches = with pkgs; [
    (fetchpatch {
      name = "recovery: Enable the menu for User builds";
      url = "https://github.com/LineageOS/android_bootable_recovery/commit/0e5fd009ce1f8bcb681f6bfb2590ebc70734ea6a.patch";
      hash = "sha256-BZuXJ9xhp70TUbS5/bt6ihvLfmezc6tazDM9uM9Ahe0=";
    })
    (fetchpatch {
      name = "recovery: ui: Default to touch enabled";
      url = "https://github.com/LineageOS/android_bootable_recovery/commit/79d69877ceae07c6667b553aa1d70284e58fd9a0.patch";
      hash = "sha256-JnLk5SkP3g34wODCQklzZs/Eu3GE+j3KsNude/Z5Mp8=";
    })
    (fetchpatch {
      name = "recovery: ui: Minor cleanup for touch code";
      url = "https://github.com/LineageOS/android_bootable_recovery/commit/e96b582105e9b0666db9e8944690649a908f2f8e.patch";
      hash = "sha256-4zE4U7fIPYfvxSD/NonZWB7oxkANDdrVG4R/bLggDrA=";
    })
    (fetchpatch {
      name = "recovery: ui: Support hardware virtual keys";
      url = "https://github.com/LineageOS/android_bootable_recovery/commit/3dbea2b64134979cdddb4494b746f2ede1409861.patch";
      hash = "sha256-pJTHHatikhksfq+p1ylnwRhMc5tRmOLxmvLQeaR4Zok=";
    })
    (fetchpatch {
      name = "recovery: Provide sideload cancellation";
      url = "https://github.com/LineageOS/android_bootable_recovery/commit/f7420e5b2ffae5aa08a637cf740287414c22bab4.patch";
      hash = "sha256-GAb8Bi6ZxLjEoYrLeHRruHbzBk0c91ZQaLu+eFT9giY=";
    })
    (fetchpatch {
      name = "recovery: Expose reboot to recovery option";
      url = "https://github.com/LineageOS/android_bootable_recovery/commit/a27249584cbc29b6c2d1444ffa62f6377d9546bc.patch";
      hash = "sha256-/S3jLQ0LcXwQzuD5G9iskf9Qtmm7ICsDA+QIcUJo30M=";
    })
    (fetchpatch {
      name = "recovery: allow opting-in to fastbootd";
      url = "https://github.com/LineageOS/android_bootable_recovery/commit/7b0e123bb7eaffe2e23ee74a3da6891d9860efa2.patch";
      hash = "sha256-24yzRx/2L6ZGI3vQGjne88HN/hB11sjGTBTDTcWe8uk=";
    })
    (fetchpatch {
      name = "recovery: simple graphical ui";
      url = "https://github.com/LineageOS/android_bootable_recovery/commit/f7f5867e72a6508b133f4df1da21e42ebcc859b0.patch";
      hash = "sha256-78q4UZp+Rh8ebmOO+NDeYqaOh5tklugEqvpR5FMXdHw=";
    })
    (fetchpatch {
      name = "recovery: touch UI";
      url = "https://github.com/LineageOS/android_bootable_recovery/commit/0b541577bdf9530401dfd7cf69324add6a090a56.patch";
      hash = "sha256-9hZebY0J2vFO26X26bB9OjykRfgs2OZrEwvytfd3P4s=";
    })
    # git format-patch -3 --full-index --binary 009525d9969a8c63c7574a87d7b87c45f2dd9c2c
    # https://github.com/LineageOS/android_bootable_recovery/commit/009525d9969a8c63c7574a87d7b87c45f2dd9c2c.patch
    # https://stackoverflow.com/questions/50677861/git-binary-diffs-are-not-supported-error-using-yocto
    ./0003-recovery-New-install-progress-animation.patch
    (fetchpatch {
      name = "recovery: calibrate touchscreen";
      url = "https://github.com/LineageOS/android_bootable_recovery/commit/0a608171e55afc39e1e73ca3ce07cea1d8aa60df.patch";
      hash = "sha256-Bi7CFTgk0X3ri9+/xKPPy6x0cNFiWgki6WR982W07w8=";
    })
    (fetchpatch {
      name = "recovery: Dejank the menus ";
      url = "https://github.com/LineageOS/android_bootable_recovery/commit/c61625a3e89eaa31914ba206db3680ed63a2f4dc.patch";
      hash = "sha256-ZvkOC/UFyz5+8ZutVZe1VAK20+fFYJiODV12SNvjF+k=";
    })
    (fetchpatch {
      name = "recovery: compute displayable item count while drawing";
      url = "https://github.com/LineageOS/android_bootable_recovery/commit/60c1298e8d7a28105b98ab5accf02d9b47e7f653.patch";
      hash = "sha256-j7n2MV3iSjAG/yf3Rx3h4UJK8mlWgfUDGVvtrACxwXU=";
    })
    (fetchpatch {
      name = "recovery: add new recovery and fastbootd logos";
      url = "https://github.com/LineageOS/android_bootable_recovery/commit/e3c138ed10c8f796bdb498ee94e2a6089aa6da8a.patch";
      hash = "sha256-atPLdO5zKa/jDNK2eeJ1YdI55X7Hj0HXX054bPLvtB8=";
    })
    (fetchpatch {
      name = "recovery: Stop showing fastbootd logo for devices without it";
      url = "https://github.com/LineageOS/android_bootable_recovery/commit/a9c5d70adea0ffdded623b58444e90bfa4e53476.patch";
      hash = "sha256-ko+oMHRx6h/hdmlwq0k/qtqJSpdnv9LklmPDCRNIdW0=";
    })
    (fetchpatch {
      name = "recovery: apply new design to menu padding, color and arrow";
      url = "https://github.com/LineageOS/android_bootable_recovery/commit/d9f009193bc6967cc8379ebef73352ed2376edcc.patch";
      hash = "sha256-tS16H7AL8LuPpkjmgZPTKg6nQfqBJClgH1w71WbfAGI=";
    })
    (fetchpatch {
      name = "recovery: Fix scrolling when touch is rotated";
      url = "https://github.com/LineageOS/android_bootable_recovery/commit/833e2948bfe4bbfbf73796391a9336850108e7bd.patch";
      hash = "sha256-riyeyBW9hyRmdQO2SmiXSizJWGmgbLnhzw0/l1/ZePg=";
    })
  ];
}
