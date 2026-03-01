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
  flavorVersion = "23.0";
  lindroid = false;
  ksu = false;
  gapps = false;
  microg.enable = true;

  source.dirs = {
    "device/samsung/dm3q".src = pkgs.fetchgit {
      url = "https://github.com/dmXq-development/android_device_samsung_dm3q.git";
      rev = "4b6e8019f439a16f8af1d1fe4bd1da70330e6976";
      sha256 = "09bkhw3j31qhyrgl0rl7qiiqx6mzdjqfyir1917ql0619fnl4jdv";
    };
    "device/samsung/sm8550-common".src = pkgs.fetchgit {
      url = "https://github.com/dmXq-development/android_device_samsung_sm8550-common.git";
      rev = "5a89fece5e20d84dc61b8d7a26916f40636a2a8e";
      sha256 = "02v99il43ibqixzbjx3ppnw4048p33dps364yqs6sy841frhmyjj";
    };
    "vendor/samsung/dm3q".src = pkgs.fetchgit {
      url = "https://github.com/dmXq-development/proprietary_vendor_samsung_dm3q.git";
      rev = "77f4fe8452b2b2e86beebc8af298059a552ddc78";
      sha256 = "142fh7gsfhmrj2g20gkxidgr1qj69s0bw50imhn1jfrphihkp4bi";
    };
    "vendor/samsung/sm8550-common".src = pkgs.fetchgit {
      url = "https://github.com/dmXq-development/proprietary_vendor_samsung_sm8550-common.git";
      rev = "2fc38b8ebf4f7a54c19c26e713b115b51b6304d3";
      sha256 = "112divlbpl42nswh1mxyxkq8nxz4hf97z9xz768vkylvgylrqxjx";
    };
    "kernel/samsung/sm8550".src = pkgs.fetchgit {
      url = "https://github.com/dmXq-development/android_kernel_samsung_sm8550.git";
      rev = "4d9a76924917a57a22181e1037ee24a6b1696cd7";
      sha256 = "12fwcvki9p3v1ggbsrqv8pcycmbhaymdvw88a7l6gg2lss96yf48";
    };
    "kernel/samsung/sm8550-modules".src = pkgs.fetchgit {
      url = "https://github.com/dmXq-development/android_kernel_samsung_sm8550-modules.git";
      rev = "1c76cec4fe06cbd5b43ca9543b2a1181fa06f4a5";
      sha256 = "04ag4rhfgcvq8vlq6gk38d332v6nwf0fdbjs6yay4waiaya2wqc0";
    };
  };
}
