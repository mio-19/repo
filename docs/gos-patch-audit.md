# Downstream GrapheneOS patch audit

Audit date: 2026-10-31. Repository baseline: `63251d045aba3c49bbb82c6cefe0f121303a01f4`.
Configured GrapheneOS release: `2026102100` for all seven devices.

This review covers all 36 local patches in `gos/`, their Nix activation and device
configuration, the eleven local kernel patches referenced by `gos/kernels/`, and
the active fetched application/framework patches. Findings below distinguish
currently enabled code from optional and inactive code. No patches were changed.
P1 means a high-priority security defect or a build blocker; P2 means a
correctness defect or an unnecessarily broad loss of a release safeguard; P3
means a smaller behavior mismatch. Security findings are source-review findings,
not device exploit demonstrations.

## Findings

1. **P1: A package-name substring authorizes access to the attestation private keys.**
   [play-integrity-frameworks-base.patch:4418](../gos/play-integrity-frameworks-base.patch#L4418)
   uses `targets.contains(pkg)` to authorize all four new ActivityManager Binder
   methods, including `getSpoofTrickyStoreKeyBox()`. With the normal GMS target,
   an unrelated app named `com.google.android` passes this test. The returned
   keybox contains the imported signing private keys. Matching also accidentally
   authorizes commented-out targets and targets with the explicit skip suffix.
   Parse the supported target syntax once and authorize exact package names;
   separate access to secret key material from access to public configuration.
   Enabled on `tangorpro`; optional through `playIntegritySpoofing` elsewhere.

2. **P1: Keybox/configuration Binder reads cross the Android user boundary.**
   [play-integrity-frameworks-base.patch:4411](../gos/play-integrity-frameworks-base.patch#L4411)
   and [line 4451](../gos/play-integrity-frameworks-base.patch#L4451) read
   `Settings.Secure` through ActivityManager's system-user resolver after
   clearing Binder identity. They never select the calling UID's user. The
   reviewed `Settings.Secure.getString()` implementation selects
   `resolver.getUserId()`, not the original Binder caller. Consequently a target
   package in a secondary user can receive the owner's keybox, while settings
   imported through Settings in that secondary user are ignored. Capture the
   calling user before clearing identity and use it consistently for both
   authorization and all four configuration reads. Same activation as finding 1.

3. **P1: Production Terminal accepts an automatically installed archive with unchecked paths.**
   [ImageArchive-allow-sdcard-images-even-when-os-is-not-debuggable.patch:47](../gos/ImageArchive-allow-sdcard-images-even-when-os-is-not-debuggable.patch#L47)
   removes the debug-build gate and auto-installs the shared-storage archive on
   resume. In the resulting `ImageArchive.kt`, `installTo()` takes each tar entry
   name, removes only `./`, calls `dir.resolve(name)`, and copies with
   `REPLACE_EXISTING`. There is no check that the resolved path remains inside
   `dir`. An absolute name or `../` name can overwrite other files writable by
   the Terminal app. The prerequisite is the ability to place a crafted archive
   at the recognized shared-storage path, followed by opening the installer; it
   does not establish root access. Validate archive entry paths and types before
   copying, and require an explicit choice before importing a local image.
   Enabled on every configured device. The unsafe extractor is upstream code
   newly exposed to this production input by the patch.

4. **P1: The Mustang firmware cannot evaluate its selected kernel source.**
   [kernels/mustang.nix:21](../gos/kernels/mustang.nix#L21) pins `2026091900`,
   while [devices/mustang.nix:27](../gos/devices/mustang.nix#L27) asserts equality
   with release `2026102100`. Evaluating that source fails with
   `string '"2026091900"' is not equal to string '"2026102100"'`.
   The fetch hash is also still empty. Select the matching kernel release and
   obtain its real fixed-output hash before attempting the firmware build.

5. **P2: An invalid DRM property blob can cause a kernel null dereference.**
   [pixel8pro-stock.patch:675](../kernel/pixel8pro-stock.patch#L675),
   [pixel9pro-stock-0x01.patch:370](../kernel/pixel9pro-stock-0x01.patch#L370),
   and [pixel10-stock-0x01.patch:479](../kernel/pixel10-stock-0x01.patch#L479)
   call `exynos_drm_replace_property_blob_from_id()` and then dereference
   `linear_matrix_override->data` without checking `ret`. The actual upstream
   helper returns `-EINVAL` for a nonexistent or incorrectly sized blob and
   leaves the old pointer unchanged. When that pointer is null and `val != 0`,
   the new code dereferences null instead of rejecting the ioctl. The five
   Pixel 8 patch variants share this code; `pixel8pro-stock-fix-attempt3.patch`
   does not fix it. A caller needs access to the affected DRM property interface;
   this review does not show reachability from an ordinary sandboxed app.
   Return on failure before changing global state or dereferencing the blob.
   Affected enabled kernels: Husky, Caiman and Komodo; Mustang once buildable.

6. **P2: The SYSVIPC workaround disables the entire VINTF release check.**
   [skip-VINTF-check-for-CONFIG_SYSVIPC.patch:20](../gos/skip-VINTF-check-for-CONFIG_SYSVIPC.patch#L20)
   comments out `CheckVintf()` altogether. This suppresses unrelated framework,
   vendor, HAL and kernel compatibility failures as well as the intended kernel
   configuration mismatch. Keep the full check and narrowly resolve the
   downstream SYSVIPC requirement. Enabled on Tangorpro through Lindroid and
   Droidspaces; conditional on either feature elsewhere.

7. **P2: Komodo's PWM control changes the displayed setting without applying it live.**
   [komodo-high-emission-frequency-adevtool.patch:19](../gos/komodo-high-emission-frequency-adevtool.patch#L19)
   gives every write action an `on boot && property:...` trigger. The Settings
   controller only changes that property and immediately reports success. After
   the `boot` event, changing the property does not run these actions, so the
   hardware remains at the previous threshold until reboot. Use a property-only
   trigger once the node is ready, or explicitly implement and describe a
   reboot-required setting. Android's [init documentation](https://android.googlesource.com/platform/system/core/+/refs/heads/main/init/README.md)
   explicitly describes this event/property behavior. Enabled on Komodo.

8. **P2: The optional carrier-hiding feature is stale and cannot be enabled as supplied.**
   A dry run of [hide-carrier-info-frameworks-base.patch](../gos/hide-carrier-info-frameworks-base.patch)
   against the successfully built current Husky framework rejects hunks in
   ActivityThreadHooks, AppBindArgs, GosPackageStateFlag, SettingsIntents,
   ZygoteExtraArgs, Zygote JNI and ActivityManager. Beyond context drift,
   [line 38](../gos/hide-carrier-info-frameworks-base.patch#L38) allocates bind-args
   index 3, which current upstream already uses for
   `FLAGS_IDX_GSERVICES_FLAGS_REDIRECT`. A rebase must choose an unused index,
   update Java/JNI serialization together, and retain downstream persistent
   package flags 58/59. Disabled by default on all configured devices.

9. **P2: Location-indicator hiding does not cover apps in a child profile.**
   [Add-toggle-to-hide-location-access-indicator-on-a-per-app-basis.patch:115](../gos/Add-toggle-to-hide-location-access-indicator-on-a-per-app-basis.patch#L115)
   grants SystemUI read access to the new flag but no cross-profile read
   permission. The monitor calls `GosPackageState.get(packageName, userId)` for
   the app's UID, including profile apps. The reviewed
   `GosPackageStatePermission.checkCrossUserPermissions()` rejects such access
   without `ALLOW_CROSS_USER_PROFILE_READS`; it does not infer this from normal
   Android cross-user privileges. The hide flag is therefore unavailable to the
   parent user's SystemUI for these apps. Add the narrow profile read permission
   and exercise a work/private-profile location request. Enabled on all devices.

10. **P2: The desktop keyboard drops normal IME editing operations.**
    [desktop-external-display-trackpad-keyboard.patch:299](../gos/desktop-external-display-trackpad-keyboard.patch#L299)
    forwards only nonempty insertions, then clears the EditText. Software IMEs
    commonly delete through `InputConnection.deleteSurroundingText()` rather
    than sending key events; those deletions never become Backspace on the
    external display. Composition replacements can also send provisional text
    multiple times. At [line 656](../gos/desktop-external-display-trackpad-keyboard.patch#L656),
    text that `KeyCharacterMap.getEvents()` cannot represent is silently dropped.
    Use an input connection that forwards commit, composition and deletion
    semantics, with a defined path for characters lacking keycodes. Enabled by
    default on all devices; device/IME testing is still required.

11. **P2: Cancelling a desktop drag leaves its mouse button pressed.**
    [desktop-external-display-trackpad-keyboard.patch:406](../gos/desktop-external-display-trackpad-keyboard.patch#L406)
    presses the primary button for double-tap dragging, but the touch handler
    releases it only on `ACTION_UP`. It has no `ACTION_CANCEL` handling and no
    corresponding release in `onPause()`. A gesture cancelled by the system can
    leave the remote pointer dragging until a later release or virtual-device
    teardown. Centralize gesture reset and release held buttons on cancellation
    and loss of activity input. Same activation as finding 10.

12. **P2: Apple's probe endpoint is interpreted as a captive portal.**
    [gos-apple.nix:19](../gos/gos-apple.nix#L19) installs a NetworkStack patch that
    only changes the chosen HTTP/HTTPS URLs to `captive.apple.com`. The reviewed
    NetworkMonitor accepts a custom 200 response only through its content
    matching configuration, whose default length range is 0..0 and whose
    success expression is empty. The [Apple endpoint](https://captive.apple.com/)
    returned `HTTP/1.1 200 OK`, `Content-Length: 69` and an HTML Success page
    during this audit. This remains a 200 probe result instead of the expected
    204 success, producing incorrect network validation when Apple is selected.
    Add narrowly scoped expected-content validation and tests for both genuine
    success and an actual portal response. The option is offered on all devices;
    the default server remains GrapheneOS.

13. **P3: The Bluetooth spoofing property's off value does not undo the spoof.**
    [bluetooth-apple-vendorid-and-l2cap.patch:32](../gos/bluetooth-apple-vendorid-and-l2cap.patch#L32)
    makes runtime rewriting conditional on `persist.bluetooth.spoof_apple_did`,
    but [line 51](../gos/bluetooth-apple-vendorid-and-l2cap.patch#L51) independently
    hardcodes the Apple identity in `bt_did.conf`. Disabling the property only
    skips the second rewrite; the configured identity is still Apple. Keep a
    genuine default in the config and apply the optional override in one place.
    Enabled on Tangorpro through bundled LibrePods.

## Deliberate security changes and remaining validation

These are visible changes in security policy, not additional accidental exploits
claimed by this review:

- Lindroid allows a permissive `perspectived` domain on production builds and
  relaxes an init-directory neverallow for that domain. Tangorpro enables it.
  Building a patched source tree does not establish that the final policy is
  least-privilege or that container boundaries remain secure.
- The inactive `gos_user_su.nix` combination removes the general permissive-domain
  build check and adds permissive `su` policy. It is explicitly marked unfinished
  and is not imported by `default.nix`. It should not be treated as a production
  hardening feature.
- The inactive SPL downgrade patch intentionally bypasses recovery's rollback
  gate, and its tests are changed to accept that behavior. The current default
  configuration comments it out with a device-bricking warning.
- Wireless ADB without Wi-Fi retains TLS/key authorization but deliberately
  removes the remembered-AP shutdown boundary for sessions started without an
  AP. Tangorpro enables this. Exercise Wi-Fi/Ethernet transitions and explicit
  disable before relying on its network exposure behavior.
- The L2CAP change makes ERTM fallback global rather than retaining the upstream
  device allowlist. Test other ERTM consumers as well as AirPods.
- Play Integrity software generation temporarily creates private key material
  inside the requesting process, then imports it into Keystore. Its certificates
  intentionally misrepresent provenance. That path changes the trust model even
  when imported-key authorization restrictions are retained.
- `gos/kernels/common.nix` still uses multiple `sed -i` source edits, contrary to
  the repository's current patch-generation rules. This is a maintenance-rule
  violation rather than evidence of a new runtime vulnerability.

No full Android firmware compilation, emulator execution, on-device tests,
flashing, attestation-verdict test, or practical exploit was performed. The
inactive experimental recovery image patch was inspected as binary image
changes/metadata, not decoded and visually or boot tested. Upstream LLVM patch
series listed by the optional source-built-toolchain module and inactive remote
PR references were not independently audited; they are not local downstream GOS
patches. Absence of a finding is not a certification of a patch's safety.

## Build and source checks

Successful `nix build --no-link --print-out-paths` source targets:

| Device | `config.source.dirs` target |
| --- | --- |
| Husky | `frameworks/base`, `packages/apps/Settings`, `packages/modules/Permission` |
| Husky | `packages/modules/Virtualization`, `packages/apps/Updater`, `packages/apps/SetupWizard2`, `packages/modules/NetworkStack` |
| Tangorpro | `frameworks/base`, `packages/apps/Settings`, `packages/modules/Bluetooth`, `system/sepolicy` |
| Komodo | `vendor/adevtool` |

For example:

```sh
nix build '.#gos.husky.config.source.dirs."frameworks/base".src' --no-link --print-out-paths
```

These derivations produce patched source trees: they verify fetching, patch
application and configured post-patch steps, **not Android compilation**.
The built Tangorpro ActivityThread was also checked: the startup calls for
`spoofBuildFields()`, `spoofProvider()` and `spoofSignature()` are present.

The current `kernel_pixel` fixed-output source was checked by copying only the
touched upstream files into disposable directories and applying these patch
sequences with GNU patch: Husky stock plus `pixel8pro-stock-fix-attempt3.patch`,
Pixel 9 PWM, and Daria plus the GPU metrics null guards. All applied successfully.
The four other Pixel 8 parameter variants were compared against stock; only the
initial normal-mode command byte differs. The Pixel 10 kernel was not built.

The carrier patch dry run fails as described in finding 8. The Mustang kernel
source evaluation fails as described in finding 4. No source files or generated
metadata were edited during these checks.

## Local patch coverage

“No additional finding” means the patch was read and no further specific defect
was established; it does not imply execution or full compilation.

| Local patch in `gos/` | Activation / result |
| --- | --- |
| `0003-recovery-New-install-progress-animation.patch` | Inactive experimental recovery; binary image metadata reviewed only |
| `16qpr2-Ignore-uevent-s-with-null-name-for-Extcon-WiredAcces.patch` | Lindroid; straightforward null guards, no additional finding |
| `Add-toggle-to-hide-location-access-indicator-on-a-per-app-basis.patch` | All devices; finding 9; persistent flag 60 avoids low-ID collisions |
| `Allow-perspectived-as-a-permissive-domain.patch` | Lindroid; deliberate policy exception discussed above |
| `ImageArchive-allow-sdcard-images-even-when-os-is-not-debuggable.patch` | All devices; finding 3 |
| `SystemUIProxy-Add-onLongPressKeyEvent.patch` | Nonstock launcher; existing caller-verification helper retained |
| `SystemUIProxy-Add-onSleepEvent.patch` | Nonstock launcher; existing caller-verification helper retained |
| `adevtool-100p-4G.patch` | Inactive bigger-zram module; no additional established defect |
| `adevtool-bigger-zram.patch` | Inactive bigger-zram module; memory/writeback tuning needs device stress tests |
| `adevtool-call-vendor-lindroid.patch` | Lindroid; product inclusion, no additional finding |
| `adevtool-exclude-replacements.patch` | Inactive bigger-zram module; replacement library coverage needs a full build |
| `advanced-power-menu.patch` | Optional, off in all shipped device definitions; reboot permission checks retained |
| `bluetooth-apple-vendorid-and-l2cap.patch` | LibrePods/Tangorpro; finding 13 and global fallback scope noted |
| `desktop-external-display-trackpad-keyboard.patch` | All devices by default; findings 10 and 11 |
| `evox-launcher3-add-current-aconfig-flags.patch` | Optional EvoX launcher, not selected; no additional finding |
| `hide-carrier-info-frameworks-base.patch` | Optional, off; finding 8 |
| `husky-high-emission-frequency-adevtool.patch` | Husky; property-only actions, no Komodo boot-trigger defect |
| `husky-high-emission-frequency-sepolicy.patch` | Husky; property labeling, final-policy/device validation outstanding |
| `husky-high-emission-frequency-settings.patch` | Husky; values bounded to the displayed list; hardware readback not tested |
| `inputflinger.patch` | Lindroid; configuration-controlled disable, no additional finding |
| `komodo-high-emission-frequency-adevtool.patch` | Komodo; finding 7 |
| `komodo-high-emission-frequency-sepolicy.patch` | Komodo; property labeling, final-policy/device validation outstanding |
| `komodo-high-emission-frequency-settings.patch` | Komodo; finding 7 integration |
| `location-indicator-per-app.patch` | Inactive local alternative; active fetched version also read |
| `los-allapps-make-search-bar-look-good-https-github.com-G.patch` | LOS launcher/Tangorpro; dimensions only, no additional finding |
| `platform_system_sepolicy-remove-check-of-permissive-.patch` | Inactive `gos_user_su.nix`; broad guard removal discussed above |
| `play-integrity-frameworks-base.patch` | Tangorpro; findings 1 and 2; startup hooks confirmed present |
| `play-integrity-settings.patch` | Tangorpro; configuration flows reviewed; imported status is not proof of a valid/verifiable keybox |
| `port-su-to-user-builds.patch` | Inactive `gos_user_su.nix`; deliberate permissive `su`, unfinished integration |
| `settings-add-taskbar-navigation-options.patch` | Nonstock launcher/Tangorpro; settings keys require launcher integration tests |
| `setupwizard-skip-embargo-and-countdown.patch` | All devices; deliberate removal of preview page/unlock countdown |
| `skip-VINTF-check-for-CONFIG_SYSVIPC.patch` | Lindroid/Droidspaces; finding 6 |
| `spl_downgrade.patch` | Inactive; intentional rollback-check bypass discussed above |
| `updater-disable-security-preview.patch` | All devices; preview forced off and UI disabled consistently |
| `wireless-debugging-without-wifi-frameworks-base.patch` | Tangorpro; deliberate network-boundary change discussed above |
| `wireless-debugging-without-wifi-settings.patch` | Tangorpro; corresponding Settings restrictions removed |

Referenced local kernel patches reviewed: `pixel8pro-stock.patch`,
`pixel8pro-stock-0x01.patch`, `pixel8pro-stock-0x02.patch`,
`pixel8pro-stock-0x05.patch`, `pixel8pro-stock-3840Hz.patch`,
`pixel8pro-stock-fix-attempt3.patch`, `pixel9pro-stock-0x01.patch`,
`pixel10-stock-0x01.patch`, `0001-daria.patch`, `sidharth-hack.patch`, and
`3dcc884c689681dda2d9ad24a9e219013f70cfe8.patch`. Display blob handling has finding
5. The overlayfs patch intentionally removes casefold-safety checks and shifts
responsibility for selecting case-sensitive directories to the container setup.

Active fetched changes reviewed include the three Apple connectivity patches
(finding 12), secure screenshot/recording toggles, restart-required notification,
Hotspot settings destination, per-app location-indicator PermissionController UI,
Android Auto PhoneAccount permission, missing Play Games notification blocking,
NetworkLocation/geocoder corrections, Gallery launcher restoration and translated
labels, recovery user-build menu, Lindroid init-directory policy/attribute, and
the two libhybris compatibility changes. Their local Nix URLs/hashes pin the
reviewed patch contents. Inherited robotnix build-system patches were treated as
baseline infrastructure, not as newly audited downstream application behavior.
