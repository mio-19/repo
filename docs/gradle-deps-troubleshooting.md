# Gradle Dependency Troubleshooting

> **When to use this guide:** Only when the package's `mitmCache.updateScript` has failed and you need to diagnose *why*. Always try the `updateScript` first — this is the canonical approach and must be preferred.

---

## Background

`gradle.fetchDeps` generates a `mitmCache.updateScript` that, when run, resolves all Gradle dependencies and writes the lock JSON (e.g. `*_deps.json`). In complex multi-project builds, this script can fail for non-obvious reasons. This document records patterns encountered and how to fix them.

---

## Common Failure Patterns

### 1. `updateScript` attribute not found

**Symptom:** `nix build .#mypkg.mitmCache.updateScript` fails with "does not provide attribute".

**Root Cause:** `gradle.fetchDeps` only auto-generates an `updateScript` when the `data` parameter is a **concrete file path** (e.g. `./my_deps.json`). If `data` is a Nix expression like `lib.recursiveUpdate a b`, no `updateScript` is emitted.

**Fix:** Temporarily set `data = ./my_deps.json;` in the `mitmCache` block, run the `updateScript`, then restore the original expression.

---

### 2. Composite build fails: `Cannot convert URI 'file://null' to a file`

**Symptom:** During `gradleUpdateScript`, a composite sub-project (e.g. `morphe-patcher`) fails with this URI error.

**Root Cause:** The sub-project's `build.gradle.kts` reads an environment variable (e.g. `System.getenv("MORPHE_LIBRARY_M2")`) to locate a local Maven repo. Inside the Nix sandbox, the variable is not set, so it resolves to `null`.

**Fix:** Add the missing env var to the package's `env` attribute:
```nix
env = {
  JAVA_HOME = jdk21_headless.passthru.home;
  MORPHE_LIBRARY_M2 = "${morphe-library-m2}";  # ← add this
  # ...
};
```

---

### 3. Dependency version mismatch between packages

**Symptom:** `updateScript` or main build fails with `Could not find com.example:artifact:X.Y.Z` even though an older version is present in the local Maven repo.

**Root Cause:** A pre-built local Maven repo derivation (e.g. `morphe-library-m2`) was hardcoded to publish a specific version (e.g. `jadb:1.2.1`), but the package being built now requires a newer version (e.g. `jadb:1.2.3`).

**Fix:** Update the derivation that builds the local Maven repo to publish **both** the old and the new version. Example pattern:
```bash
# In postUnpack / buildPhase of the m2 derivation:
mkdir -p "$root/.m2/repository/com/example/artifact/1.2.1"
mkdir -p "$root/.m2/repository/com/example/artifact/1.2.3"
# ... build the jar once, copy/link it under both version dirs
jar cf "$root/.m2/repository/com/example/artifact/1.2.1/artifact-1.2.1.jar" .
jar cf "$root/.m2/repository/com/example/artifact/1.2.3/artifact-1.2.3.jar" .
# write a matching .pom for each version
```
This keeps backward compatibility for packages that still need the old version.

---

### 4. Gradle 8 vs Gradle 9 resolution incompatibilities

**Symptom:** The `updateScript` succeeds with one Gradle version but the main build fails with a different version, with missing OSGi/Maven plugin transitive dependencies.

**Root Cause:** Gradle 8 and 9 resolve certain plugin dependency trees differently. A lock file generated under Gradle 9 will not match what Gradle 8 expects (it may omit some transitive deps like `org.osgi:org.osgi.annotation.bundle`).

**Fix:** Make the `updateScript` and the main derivation use the **same** Gradle version. If the project works fine on Gradle 9, change the derivation to use `gradle_9_x`:
```nix
let
  gradle = gradle_9_3_1;  # must match what updateScript was run with
in ...
```

---

## Diagnostic Workflow

When `updateScript` fails, follow this checklist:

1. **Can you even build the `updateScript` derivation?**
   ```bash
   nix build .#mypkg.mitmCache.updateScript --no-link --print-out-paths
   ```
   If not, check if `data` is a file path (see pattern #1).

2. **Run the update script and capture the full log:**
   ```bash
   script=$(nix build .#mypkg.mitmCache.updateScript --no-link --print-out-paths)
   $script 2>&1 | tee /tmp/update-log.txt
   ```

3. **Check the error for environment variable issues** (pattern #2) — look for `null` in URIs or file paths.

4. **Check for version mismatches** (pattern #3) — `Could not find group:artifact:X.Y.Z` where a different version exists locally.

5. **Check the Gradle version** (pattern #4) — does the `updateScript` use the same `gradle_x_y_z` package as the main build derivation?

6. **Once all issues are resolved, re-run the `updateScript` cleanly** and commit only the generated `*_deps.json` file. Do not manually edit the lockfile.

---

## Important Reminders

- Always prefer the `updateScript` approach. Manual edits to `*_deps.json` are fragile.
- The `updateScript` needs network access (it is a fixed-output derivation). Run it outside of a sandbox.
- Cleanup errors at the end of `gradleUpdateScript` are expected and harmless — they do not affect the generated lockfile.
- After regenerating a lockfile, run `git add` before `nix build` if the path is a new file (Nix needs the file tracked to access it).
