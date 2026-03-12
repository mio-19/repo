{ axp_kernel_patches }:
/*
  Derived from:
  - https://git.disroot.org/AXP.OS/build/raw/branch/axp/Scripts/LineageOS-22.2/CVE_Patchers/android_kernel_oneplus_sm8250.sh
  - https://git.disroot.org/AXP.OS/kernel_patches at commit
    3aa8873aa23dcac8469b02684093c4c025500f20

  Selection method:
  - start from the AXP.OS sm8250 script entries relevant to this 4.19 kernel
  - keep only patches that pass git apply --check against
    android_kernel_samsung_sm8250 lineage-23.2
  - then re-apply that reduced list sequentially in upstream order and keep the
    cumulative set that still applies cleanly
  - exclude subtree-only patches that need git apply --directory=... because
    nix-kernelsu-builder's kernelPatches hook applies patches from repo root
*/
let
  mkAxpPatch = rel: axp_kernel_patches + "/${rel}";
in
map mkAxpPatch [
  "0003-syzkaller-Misc/ANY/0008.patch"
  "0008-Graphene-Kernel_Hardening-allocsize/4.19/0003.patch"
  "0008-Graphene-Kernel_Hardening-allocsize/4.19/0012.patch"
  "0008-Graphene-Kernel_Hardening-allocsize/4.19/0017.patch"
  "0008-Graphene-Kernel_Hardening-allocsize/4.19/0022.patch"
  "0008-Graphene-Kernel_Hardening-bugon/4.19/0005.patch"
  "0008-Graphene-Kernel_Hardening-bugon/4.19/0011.patch"
  "0008-Graphene-Kernel_Hardening-fortify/4.19/0005.patch"
  "0008-Graphene-Kernel_Hardening-misc/4.19/0002.patch"
  "0008-Graphene-Kernel_Hardening-misc/4.19/0006.patch"
  "0008-Graphene-Kernel_Hardening-misc/4.19/0011.patch"
  "0008-Graphene-Kernel_Hardening-misc/4.19/0019.patch"
  "0008-Graphene-Kernel_Hardening-random/4.19/0013.patch"
  "0008-Graphene-Kernel_Hardening-ro/4.19/0003.patch"
  "0008-Graphene-Kernel_Hardening-ro/4.19/0013.patch"
  "0008-Graphene-Kernel_Hardening-ro/4.19/0018.patch"
  "0008-Graphene-Kernel_Hardening-ro/4.19/0024.patch"
  "0008-Graphene-Kernel_Hardening-sanitize/4.19/0006.patch"
  "0008-Graphene-Kernel_Hardening-sanitize/4.19/0010.patch"
  "0008-Graphene-Kernel_Hardening-slab/4.19/0007.patch"
  "0008-Graphene-Kernel_Hardening-slab/4.19/0011.patch"
  "0008-Graphene-Kernel_Hardening-slab/4.19/0015.patch"
  "0008-Graphene-Kernel_Hardening-slab/4.19/0019.patch"
  "0009-rfc4941bis/ANY/0005.patch"
  "CVE-2015-7837/ANY/0001.patch"
  "CVE-2016-3695/ANY/0001.patch"
  "CVE-2018-5897/ANY/0001.patch"
  "CVE-2019-9444/ANY/0001.patch"
  "CVE-2019-15291/4.19/0005.patch"
  "CVE-2019-18786/4.19/0003.patch"
  "CVE-2019-19051/4.19/0010.patch"
  "CVE-2019-19068/4.19/0003.patch"
  "CVE-2020-11146/ANY/0001.patch"
  "CVE-2021-28950/4.19/0003.patch"
  "CVE-2021-46959/4.19/0004.patch"
  "CVE-2021-47173/4.19/0004.patch"
  "CVE-2022-4662/4.19/0004.patch"
  "CVE-2022-48966/4.19/0003.patch"
  "CVE-2023-1989/4.19/0005.patch"
  "CVE-2023-52604/4.19/0002.patch"
  "CVE-2023-52817/4.19/0002.patch"
  "CVE-2024-26720/4.19/0003.patch"
  "CVE-2024-26920/4.19/0003.patch"
  "CVE-2024-35933/4.19/0002.patch"
]
