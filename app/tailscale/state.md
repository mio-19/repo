# Tailscale Packaging State

Current upstream target:
- App repo: `tailscale/tailscale-android`
- Release: `1.96.2`
- Commit: `a82504d6b278d1c2cf55191395a9d063574ea66b`
- F-Droid recipe reference: `com.tailscale.ipn.yml`

## Goal

Build the Android app from source with `nix build .#tailscale`.

## What Was Tried

### 1. Follow the F-Droid flow directly

The initial direction matched F-Droid:
- build from `tailscale-android`
- use the pinned Tailscale Go toolchain revision from `go.toolchain.rev`
- run `make libtailscale`
- then run the Android Gradle build

This got blocked before the app build for two reasons:
- nixpkgs' old `ndk-23-1-7779620` is broken here and fails in auto-patchelf
- rebuilding Tailscale's forked Go toolchain inside the derivation is very expensive and was not getting to the Android phase fast enough

### 2. Move to NDK 26 and patch the Android build

I switched the package to:
- `ndk-26-1-10909125`
- patch `android/build.gradle` from `23.1.7779620` to `26.1.10909125`

That part works. The build gets past the NDK setup.

### 3. Build with nixpkgs `go_1_26.1` instead of rebuilding Tailscale's Go fork

This simplified the derivation and removed the long custom Go bootstrap from the normal path:
- `TOOLCHAINDIR="${go_1_26}/share/go"`
- `PATH="$TOOLCHAINDIR/bin:$PATH"`

This works well enough to get to `gomobile bind`.

### 4. Patch `golang.org/x/mobile` used by `gomobile`

The package now vendors a patched local checkout of `golang/mobile` and replaces:
- `golang.org/x/mobile => ./x-mobile`

Patch file:
- `gomobile-avoid-empty-go-mod.patch`

That patch does three things:
- removes `-tags=...` from `go list -m all`
- avoids writing an empty temp `go.mod`
- avoids running `go mod tidy` when no temp `go.mod` exists

This fixed the earlier hard failures:
- `go mod tidy failed`
- `missing module declaration`
- `go.mod file not found ...` during the `tidy` phase

### 5. Refresh the fixed-output Go module cache with the same replacement

The `goModCache` derivation now also:
- copies in the patched `x-mobile`
- applies the same patch
- runs `go mod edit -replace=golang.org/x/mobile=./x-mobile`
- runs `go mod download`

This changed the fixed-output hash to:
- `sha256-ehqH2q9/+Nj86BQEfQ6OXKmSUr2/GM8GS5p1DD+lyAY=`

## Current Failure

`nix build .#tailscale` still fails in `gomobile bind` while compiling `./gobind`.

Current error shape:

```text
cannot find package "github.com/tailscale/tailscale-android/libtailscale"
cannot find package "golang.org/x/mobile/bind/java"
cannot find package "golang.org/x/mobile/bind/seq"
```

Observed search paths in the failure:
- `$GOROOT/src/...`
- `/build/gomobile-work-.../src/...`
- `/build/go/src/...`

This means `gomobile` is still building `./gobind` in a GOPATH-style temp tree that does not contain:
- the main module path `github.com/tailscale/tailscale-android`
- the `golang.org/x/mobile` source tree under GOPATH

## Why It Still Fails

The remaining blocker is not Gradle yet.

The real issue is that `gomobile bind` still does not consistently stay in module mode for the generated `gobind` build. Once it falls back to GOPATH-style package resolution, the temp work tree is incomplete and the build cannot see either:
- the app module itself
- `x/mobile` bind support packages

So the problem is now specifically:
- `gomobile` temp workdir/module handling
- not Android SDK setup
- not the Gradle dependency lock
- not the Tailscale app sources themselves

## Next Likely Fixes

The next useful directions are:

1. Patch `gomobile` further so the `gobind` build always uses a generated module, not GOPATH fallback.
2. If that is too invasive, patch the temp workdir assembly so GOPATH mode includes:
   - `src/github.com/tailscale/tailscale-android`
   - `src/golang.org/x/mobile`
3. Only after `make libtailscale` succeeds should we refresh `tailscale_deps.json` and debug any later Gradle issues.

## Files In This WIP

- `app/tailscale/default.nix`
- `app/tailscale/gomobile-avoid-empty-go-mod.patch`
