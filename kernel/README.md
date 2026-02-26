# kernel - patch -p1 --no-backup-if-mismatch

## husky kernel

prefer pixel8pro-stock-fix-3840Hz.patch with pixel8pro-lindroid.patch

+ <https://grapheneos.org/build#prebuilt-code>
+ <https://github.com/updateing/android_kernel_google_zuma/commits/14.0.0-sultan-pwm/>
+ <https://xdaforums.com/t/a-mod-on-pwm-frequency-v3-20241027.4683727/>
+ <https://xdaforums.com/t/a-mod-on-pwm-frequency-v3-20241027.4683727/post-89634948>
+ <https://xdaforums.com/t/a-mod-on-pwm-frequency-v3-20241027.4683727/page-8#post-89915781>
+ <https://www.androidcentral.com/phones/google-pixel-8-pro-display-upgrade>

adjusted patch from sultan branch <https://github.com/updateing/android_kernel_google_zuma.git> 14.0.0-sultan-pwm: pixel8pro-14.0.0-sultan-pwm.patch

adjusted patch with  Stock-based variant: pixel8pro-stock.patch with kernel crash fix: pixel8pro-stock-fix.patch - pixel8pro-14.0.0-sultan-pwm.patch and pixel8pro-stock.patch don't have actual code difference; pixel8pro-stock-fix-3840Hz.patch

adjusted patch from <https://github.com/elephant-43/kernel_google-modules_display_samsung> <https://github.com/elephant-43/kernel_devices_google_shusky> pixel8pro-elephant-43.patch with kernel crash fix: pixel8pro-elephant-43-fix.patch

adjusted patch from <https://github.com/elephant-43/kernel_google-modules_display> <https://github.com/elephant-43/kernel_devices_google_shusky> pixel8pro-elephant-43-b.patch (not that different from pixel8pro-elephant-43.patch) TODO: correct this patch

```zsh
sudo apt install libssl-dev
KLEAF_REPO_MANIFEST=aosp_manifest.xml ./build_shusky.sh --lto=full
```

### lindroid extra steps 

patch c360d6f7b22ab710a27193f62669f5a257cd259d.patch on aosp. from <https://gitlab.com/ubports/porting/reference-device-ports/halium12/volla-x23/kernel-volla-mt6789/-/commit/c360d6f7b22ab710a27193f62669f5a257cd259d> <https://t.me/linux_on_droid/7889>

them:
```zsh
wget https://github.com/mmeimm/GKI-Custom/raw/refs/heads/main/patchs/0ac686b9e81ba331c2ad9b420fd21262a80daaa4.patch
wget https://github.com/mmeimm/GKI-Custom/raw/refs/heads/main/patchs/3dcc884c689681dda2d9ad24a9e219013f70cfe8.patch
wget https://github.com/mmeimm/GKI-Custom/raw/refs/heads/main/patchs/750b43051d2e4317121c7250544ae38fdf28d4c7.patch
wget https://github.com/mmeimm/GKI-Custom/raw/refs/heads/main/patchs/a0aa446ca326b5d26ac1dec057efd8c07d2bcbff.patch
wget https://github.com/mmeimm/GKI-Custom/raw/refs/heads/main/patchs/a72032ecf33c63d8a4abb64b08c1a0b847c82a32.patch
```

for debug `--sandbox_debug --verbose_failures`

TODO: consider CONFIG_POSIX_MQUEUE

lindroid-partial6
```zsh
tee -a private/devices/google/shusky/shusky_defconfig << 'EOF'

# lindroid
CONFIG_SYSVIPC=y
CONFIG_UTS_NS=y
CONFIG_PID_NS=y
CONFIG_USER_NS=y
CONFIG_NET_NS=y
CONFIG_CGROUP_DEVICE=y
CONFIG_CGROUP_FREEZER=y
CONFIG_DRM_LINDROID_EVDI=y
CONFIG_TMPFS_POSIX_ACL=y
EOF

sed -i '/^# CONFIG_PID_NS is not set$/d' aosp/arch/arm64/configs/gki_defconfig
sed -i '/^CONFIG_NAMESPACES=y$/a CONFIG_USER_NS=y' aosp/arch/arm64/configs/gki_defconfig

sed -i '/^  __fsnotify_parent$/a\  from_kuid' aosp/android/abi_gki_aarch64_pixel
sed -i '/^  from_kuid$/a\  from_kuid_munged' aosp/android/abi_gki_aarch64_pixel
sed -i '/^  mac_pton$/a\  make_kuid' aosp/android/abi_gki_aarch64_pixel
```

lindroid-partial-b1 - maybe private/devices/google/shusky/shusky_defconfig is not the right one

```zsh
sed -i '/^# CONFIG_PID_NS is not set$/d' aosp/arch/arm64/configs/gki_defconfig
sed -i '/^CONFIG_NAMESPACES=y$/a CONFIG_USER_NS=y' aosp/arch/arm64/configs/gki_defconfig

sed -i '/^  __fsnotify_parent$/a\  from_kuid' aosp/android/abi_gki_aarch64_pixel
sed -i '/^  from_kuid$/a\  from_kuid_munged' aosp/android/abi_gki_aarch64_pixel
sed -i '/^  mac_pton$/a\  make_kuid' aosp/android/abi_gki_aarch64_pixel
```

lindroid-partial-b2 - maybe private/devices/google/shusky/shusky_defconfig is not the right one

```zsh
sed -i '/^# CONFIG_PID_NS is not set$/d' aosp/arch/arm64/configs/gki_defconfig
sed -i '/^CONFIG_NAMESPACES=y$/a CONFIG_USER_NS=y' aosp/arch/arm64/configs/gki_defconfig
sed -i '/^CONFIG_NAMESPACES=y$/a CONFIG_DRM_LINDROID_EVDI=y' aosp/arch/arm64/configs/gki_defconfig

sed -i '/^  __fsnotify_parent$/a\  from_kuid' aosp/android/abi_gki_aarch64_pixel
sed -i '/^  from_kuid$/a\  from_kuid_munged' aosp/android/abi_gki_aarch64_pixel
sed -i '/^  mac_pton$/a\  make_kuid' aosp/android/abi_gki_aarch64_pixel
```

lindroid common

```zsh

git clone https://github.com/Linux-on-droid/lindroid-drm-loopback.git aosp/drivers/lindroid-drm
echo 'obj-y += lindroid-drm/' >> aosp/drivers/Makefile
sed -i "/endmenu/i\source \"drivers/lindroid-drm/Kconfig\"" aosp/drivers/Kconfig

cd aosp
for patch in 0ac686b9e81ba331c2ad9b420fd21262a80daaa4.patch  3dcc884c689681dda2d9ad24a9e219013f70cfe8.patch a72032ecf33c63d8a4abb64b08c1a0b847c82a32.patch; do
patch -p1 --no-backup-if-mismatch < ~/Documents/repo/kernel/$patch
done
cd ..
```

### ksu

```zsh
cd aosp
# https://kernelsu-next.github.io/webpage/pages/installation.html
curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -
cd ..
sed -i 's|^KSU_VERSION_FALLBACK := 1$|KSU_VERSION_FALLBACK := 32967|' aosp/KernelSU-Next/kernel/Kbuild
sed -i 's|^KSU_VERSION_TAG_FALLBACK := v0.0.1$|KSU_VERSION_TAG_FALLBACK := v3.0.1|' aosp/KernelSU-Next/kernel/Kbuild
```