{ fetchpatch }:
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
[
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0003-syzkaller-Misc/ANY/0008.patch";
    hash = "sha256-9SOf00vGixqffsGO49wzg0B1n8Aspz2/rMfEiuUhcgY=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0008-Graphene-Kernel_Hardening-allocsize/4.19/0003.patch";
    hash = "sha256-0ZVDYE01cGvjjJWPQ3g5D5c0h55Xh2rZXgvfInXr3NM=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0008-Graphene-Kernel_Hardening-allocsize/4.19/0012.patch";
    hash = "sha256-aQklVFAg3sLhoIuDN408c4Y1zuWRkj90BAvHo3pd2po=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0008-Graphene-Kernel_Hardening-allocsize/4.19/0017.patch";
    hash = "sha256-jr3LQQ7VmDvEAZfPrrsAT/sANS5L9IvPzK/WgsOCaHI=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0008-Graphene-Kernel_Hardening-allocsize/4.19/0022.patch";
    hash = "sha256-XB+WPhfcE9EWVKG5lgbiIin9hAmn3piZUNL6t/T4Yd4=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0008-Graphene-Kernel_Hardening-bugon/4.19/0005.patch";
    hash = "sha256-R/5/Yc/nNfr7c3FLuWVCBmBXJA74ZZzynzjf7L8BDE8=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0008-Graphene-Kernel_Hardening-bugon/4.19/0011.patch";
    hash = "sha256-dk1nsRnSFQtJ3gKDmsbGCki/mcxAaqJ1N3LR5bywJ98=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0008-Graphene-Kernel_Hardening-fortify/4.19/0005.patch";
    hash = "sha256-OteSJcI0wdiSgNl89jJcJuamI72UGgDpXmETL7oWZSk=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0008-Graphene-Kernel_Hardening-misc/4.19/0002.patch";
    hash = "sha256-OqWk58WxlLRJ2ftsGJBK8Gqsk2284A/zM1jgb8JV1Yg=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0008-Graphene-Kernel_Hardening-misc/4.19/0006.patch";
    hash = "sha256-lnmYKhlub3riG02A/X6VwUWElosDcpN1PdNc2u3odP4=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0008-Graphene-Kernel_Hardening-misc/4.19/0011.patch";
    hash = "sha256-8eLcktg1PrXHarkEqfVhUmsauUBE99s4W1BuUhhj/ao=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0008-Graphene-Kernel_Hardening-misc/4.19/0019.patch";
    hash = "sha256-K8/e31UCWWovK9ykVTNvbnpvCUulK7fo0Vy7dLKxlkc=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0008-Graphene-Kernel_Hardening-random/4.19/0013.patch";
    hash = "sha256-I+G41qCDAujvyYubirwmvK1JcuddO+3STEvibDiZcZg=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0008-Graphene-Kernel_Hardening-ro/4.19/0003.patch";
    hash = "sha256-1e4gMBRCaVC98b34gqjMP/7AdMGuySCm7auAL+ebOZQ=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0008-Graphene-Kernel_Hardening-ro/4.19/0013.patch";
    hash = "sha256-5kE1r4JDmtJ9y1+MquHeqVwyMaVtpJ19UEImyA/IVwI=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0008-Graphene-Kernel_Hardening-ro/4.19/0018.patch";
    hash = "sha256-jvOt18FU8go3FeUsupUU/OEnqAjdcmZ2UX+DBYJbDhY=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0008-Graphene-Kernel_Hardening-ro/4.19/0024.patch";
    hash = "sha256-eIj5s+0wCnXLwP05XVbgxI1UO7tp1NJ3aCTMCbb8OTg=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0008-Graphene-Kernel_Hardening-sanitize/4.19/0006.patch";
    hash = "sha256-AuJzgWbrU9u21xkc6oV0KDbXg/5/yuxWPQXR4ui98yE=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0008-Graphene-Kernel_Hardening-sanitize/4.19/0010.patch";
    hash = "sha256-DVXvEfTu2LEBHGr8ZLpUdMdLLD1O22pnPzMMGZxbJ5g=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0008-Graphene-Kernel_Hardening-slab/4.19/0007.patch";
    hash = "sha256-JpQ9HMn9NrctEZsbfljSLRsArjvRgFE59PjqCt5lMco=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0008-Graphene-Kernel_Hardening-slab/4.19/0011.patch";
    hash = "sha256-vzKKzv0nLadrOMLEpnhKoJ/U7ZeCjBSHKYumrwDun2Q=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0008-Graphene-Kernel_Hardening-slab/4.19/0015.patch";
    hash = "sha256-IA5EhXXoLthv0zjGD8h9mozN8LtryaOPT2nFzwx0Ctg=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0008-Graphene-Kernel_Hardening-slab/4.19/0019.patch";
    hash = "sha256-DQ5FMoqgC7GK/zRG1NjizSXWb4MyYOXyznM7HGqq8RQ=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/0009-rfc4941bis/ANY/0005.patch";
    hash = "sha256-+zy0B4UzQ6UjOy5OkLwM9W/kAaThCuCoI9BHh7UjtCw=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/CVE-2015-7837/ANY/0001.patch";
    hash = "sha256-0OBPVKKIJIBFq5NPTvSMi82+h1H0Ad6GrShHzlvgLWI=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/CVE-2016-3695/ANY/0001.patch";
    hash = "sha256-g4jzoL0uJ9jFQ3HxtStQUfJNkiLbZp1KOzTZ6MdeKp0=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/CVE-2018-5897/ANY/0001.patch";
    hash = "sha256-+kEHA7fPqiopCYlVHWlXWAjLPLFiMm5c04GHxv00Kok=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/CVE-2019-9444/ANY/0001.patch";
    hash = "sha256-vuYxko6xFweHNHALc2vUr6qyhMO7gqPhYJICz7iwEYY=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/CVE-2019-15291/4.19/0005.patch";
    hash = "sha256-qKILDd2nCkEYvn2H1vv+tyjFAJNJSQvdDp9RDcTJLOU=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/CVE-2019-18786/4.19/0003.patch";
    hash = "sha256-R5qUlBvMTcpmif4zi1RAg+pzMQiqw823VouBJrqkhK0=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/CVE-2019-19051/4.19/0010.patch";
    hash = "sha256-+67tCXHb6i/bjhCVyz2EUZP/mtsNYOAf4Ovl8ZGA5jo=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/CVE-2019-19068/4.19/0003.patch";
    hash = "sha256-G3VGOgQnt9EeJtP2MVtLrVyJwtBr4h0CgVFgvJlYD9A=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/CVE-2020-11146/ANY/0001.patch";
    hash = "sha256-RPbQ2Q5UNzmujnNzgiZPK9AV36bGlLlv+YeW/4WprQY=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/CVE-2021-28950/4.19/0003.patch";
    hash = "sha256-SP7stYjcMMqSN12NpBFZi0muY0J/Md/daaXGmW9f/XI=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/CVE-2021-46959/4.19/0004.patch";
    hash = "sha256-jrQprKPf7Snxjl2Uf1oCjyrCPUw3xC/ajJw3i5uH5sM=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/CVE-2021-47173/4.19/0004.patch";
    hash = "sha256-8nYwzHii1+2uGaAdx9P2d0HLUg3X664CKOqHtQR5cbk=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/CVE-2022-4662/4.19/0004.patch";
    hash = "sha256-OKJSXuYiPcm78TulPekFR9wzxDickBl017dq727S8gM=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/CVE-2022-48966/4.19/0003.patch";
    hash = "sha256-VBCNBivxezqBtEnPwC7syXFIrHOUnuTTzKKLooR5JYg=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/CVE-2023-1989/4.19/0005.patch";
    hash = "sha256-511jMamoBeNY53pZdwz995FZY2CQKMcx6VvMGZqIvkE=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/CVE-2023-52604/4.19/0002.patch";
    hash = "sha256-3Ek5lVoBZ8VpXdxYM6+NcAtp/RWUCfl0CH3yevbnPb4=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/CVE-2023-52817/4.19/0002.patch";
    hash = "sha256-Nntg0xMkoYHDRdgaZ9XGWTSeQtNStB7P/Emxl1XQOx8=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/CVE-2024-26720/4.19/0003.patch";
    hash = "sha256-aV2WsbkUa7mXAGYVw36vPi+fz4Llwl+SZQcx+RVW58k=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/CVE-2024-26920/4.19/0003.patch";
    hash = "sha256-QZlzWgoQFvBy0PlOjzfD8kjeMrqQ6rU3dsjF5KyA98Y=";
  })
  (fetchpatch {
    url = "https://git.disroot.org/AXP.OS/kernel_patches/raw/commit/3aa8873aa23dcac8469b02684093c4c025500f20/CVE-2024-35933/4.19/0002.patch";
    hash = "sha256-wDKSt59bR993w7I0Tmn5/gSwYyUkikJ/smPzYSTJEyg=";
  })
]
