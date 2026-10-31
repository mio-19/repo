# shellcheck shell=bash
#
# Shared bash helpers for the `passthru.updateScript`s of APK packages.
#
# `nix-update --src-only` only bumps `version` and the source hash. Every other
# fixed-output derivation of a package (vendored Rust crates, Go module caches,
# ...) keeps its now stale hash, so the build that follows the update fails with
# a hash mismatch. Packages that carry such derivations list them in
# `passthru.updateDeps` and call `refresh_update_deps` after the `nix-update`
# call; each hash is then recomputed against the new source.

: "${package_file:?set package_file to the package.nix holding the hashes before sourcing update-script-helpers.sh}"
: "${package_attr:?set package_attr to the flake attribute of the package, e.g. .#apk_haven, before sourcing update-script-helpers.sh}"
: "${fake_hash:?set fake_hash to a deliberately wrong SRI hash, e.g. lib.fakeHash, before sourcing update-script-helpers.sh}"

# Replace every occurrence of a literal string in the package file. Uses awk so
# hashes containing regex metacharacters (+, /, =) are matched verbatim.
replace_literal() {
  local old="$1"
  local new="$2"
  local tmp

  tmp="$(mktemp "${package_file}.XXXXXX")"
  awk -v old="$old" -v new="$new" '
    {
      while ((i = index($0, old)) > 0)
        $0 = substr($0, 1, i - 1) new substr($0, i + length(old))
      print
    }
  ' "$package_file" >"$tmp"
  mv "$tmp" "$package_file"
}

# Rewrite the `hash` of a single fixed-output derivation: point it at a known
# wrong value, build it so Nix reports the real hash, then store that value.
refresh_fod_hash() {
  local attr="$1"
  local old_hash new_hash build_log occurrences

  if ! old_hash="$(nix eval --impure --raw "$package_attr.$attr.outputHash" 2>/dev/null)"; then
    echo "error: $attr is not a fixed-output derivation of $package_attr" >&2
    return 1
  fi

  occurrences="$(grep -c -F -- "$old_hash" "$package_file" || true)"
  if [[ "$occurrences" -ne 1 ]]; then
    echo "error: the hash of $attr ($old_hash) appears $occurrences times in $package_file, refusing to rewrite it unambiguously" >&2
    return 1
  fi

  replace_literal "$old_hash" "$fake_hash"

  if build_log="$(nix build "$package_attr.$attr" --no-link 2>&1)"; then
    replace_literal "$fake_hash" "$old_hash"
    echo "  $attr: unchanged"
    return 0
  fi

  new_hash="$(sed -n 's/^ *got: *//p' <<<"$build_log" | head -n 1)"
  if [[ -z "$new_hash" ]]; then
    replace_literal "$fake_hash" "$old_hash"
    echo "error: could not determine the hash of $attr:" >&2
    echo "$build_log" >&2
    return 1
  fi

  replace_literal "$fake_hash" "$new_hash"
  if [[ "$new_hash" == "$old_hash" ]]; then
    echo "  $attr: unchanged"
  else
    echo "  $attr: $old_hash -> $new_hash"
  fi
}

# Refresh the hashes of all the fixed-output derivations given as arguments,
# conventionally `passthru.updateDeps` of the package.
refresh_update_deps() {
  local attr

  for attr in "$@"; do
    refresh_fod_hash "$attr"
  done
}

# Regenerate the Gradle dependency lockfile (mitm cache) of the package.
refresh_mitm_cache() {
  local update_script

  update_script="$(nix build "$package_attr.mitmCache.updateScript" --no-link --print-out-paths)"
  "$update_script"
}
