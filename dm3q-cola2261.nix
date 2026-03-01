args@{
  config,
  pkgs,
  lib,
  ...
}:
{
  buildDateTime = 1772004451;
  imports = [ ./los.nix ];
  manufactor = "samsung";
  kernel-short = "sm8550";
  defconfig = "arch/arm64/configs/dm3q_defconfig";
  device = "dm3q";
  flavorVersion = "23.2";
  lindroid = false;
  ksu = false;
  gapps = false;
  microg.enable = true;

  source.dirs = {
    "device/samsung/dm3q".src = pkgs.fetchgit {
      url = "https://github.com/samsung-sm8550-cola2261/android_device_samsung_dm3q.git";
      rev = "26ca623ab21c2906db387eb3841d0ddddf5f079b";
      sha256 = "04aqwc3qccg73gaipa1xp8zaavvjc9bzpyx070fxil8f5v57hspm";
    };
    "device/samsung/sm8550-common".src = pkgs.fetchgit {
      url = "https://github.com/samsung-sm8550-cola2261/android_device_samsung_sm8550-common.git";
      rev = "af65cfede153db281cf6d63f9a2dffa272668fea";
      sha256 = "14c654m49jrjvrkxicspy0jvn88hx1nq80h9jhsk1k2w96jis9zs";
    };
    "vendor/samsung/dm3q".src = pkgs.fetchgit {
      url = "https://github.com/samsung-sm8550-cola2261/proprietary_vendor_samsung_dm3q.git";
      rev = "6c9589925d9fa9bed768941f33bd6813311f9a93";
      sha256 = "1zrn6rychfga34kz1did2bnxb8b1hwd15fcj8yxk1cpi2nxra87c";
    };
    "vendor/samsung/sm8550-common".src = pkgs.fetchgit {
      url = "https://github.com/samsung-sm8550-cola2261/proprietary_vendor_samsung_sm8550-common.git";
      rev = "d3cc54106b546f18c69aaac776d3b4125dd11948";
      sha256 = "1ja37fcxqixgcfc7dlkw019xy01cv60282mssbq2asrm99qbbcbx";
    };
    "kernel/samsung/sm8550".src = pkgs.fetchgit {
      url = "https://github.com/samsung-sm8550-cola2261/android_kernel_samsung_sm8550.git";
      rev = "aaa49d9a8f4e0f8d86e8a68cff0f2e21cf1a0c3a";
      sha256 = "08rml1w7w7kdwg5rd8xvwwhcb9az9j3zlql4px7cxvcdy8056dbz";
    };
    "kernel/samsung/sm8550-modules".src = pkgs.fetchgit {
      url = "https://github.com/samsung-sm8550-cola2261/android_kernel_samsung_sm8550-modules.git";
      rev = "9e3fd2d8bfe1c9cf77c25e0a3af73714f0823933";
      sha256 = "1phvp22m5m4is66h4cyrcfw027djbysn7ika2rb8fd2xvz151qxx";
    };
    "hardware/samsung".src = pkgs.fetchgit {
      url = "https://github.com/samsung-sm8550-cola2261/android_hardware_samsung.git";
      rev = "4f3afca5e2af0b447b3efd3973ecb69c63a5f918";
      sha256 = "0d6f47rmdq2fckb729956qvhwhy9rcn6fxchxkn4qhzgmk0xn1mr";
    };
  };
}
