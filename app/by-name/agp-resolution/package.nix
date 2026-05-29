# Generates a pluginManagement resolutionStrategy block for Gradle settings files.
#
# This avoids the need for plugin-marker artifacts in the locked dependency set,
# by resolving Android (and optionally other) Gradle plugin IDs directly to their
# implementation modules.
#
# Usage in postPatch:
#   let agpRes = import ../_shared/agp-resolution.nix; in
#   ...
#   postPatch = agpRes.patchSettingsGradle { agpVersion = "9.0.0"; } + ''
#     # other postPatch commands
#   '';
#
# Or with extra plugin mappings (e.g. Kotlin):
#   postPatch = agpRes.patchSettingsGradle {
#     agpVersion = "9.1.0";
#     extraPlugins = [
#       { ids = [ "org.jetbrains.kotlin.android" ]; module = "org.jetbrains.kotlin:kotlin-gradle-plugin"; version = "2.3.10"; }
#     ];
#   } + ''...''
#
# Or for Groovy settings.gradle (auto-detected from file extension):
#   postPatch = agpRes.patchSettingsGradle {
#     file = "settings.gradle";
#     agpVersion = "9.1.1";
#   } + ''...''
{ }:
let
  # Build a resolutionStrategy block string that replaces "pluginManagement {"
  # in a Gradle settings file.
  #
  # The output starts with "pluginManagement {\n    resolutionStrategy {..."
  # and does NOT include the closing "}" for pluginManagement, since the
  # original file already has it.
  mkResolutionBlock =
    {
      # List of Android plugin IDs to intercept.
      pluginIds ? [
        "com.android.application"
        "com.android.library"
      ],
      # Default AGP version when the build script doesn't specify one.
      agpVersion,
      # "kotlin" for settings.gradle.kts (val), "groovy" for settings.gradle (def)
      lang ? "kotlin",
      # Extra plugin mappings: list of { ids, module, version }
      extraPlugins ? [ ],
    }:
    let
      keyword = if lang == "kotlin" then "val" else "def";
      # In Kotlin DSL, ${var} is native string interpolation.
      # In Groovy DSL, we need ${ to be passed through literally,
      # but since this ends up going through substituteInPlace as a bash
      # argument, we just use the Kotlin-style ${...} for both — Groovy
      # also supports ${...} in strings.
      quote = id: "\"${id}\"";
      idChecks = builtins.concatStringsSep " || " (map (id: "requested.id.id == ${quote id}") pluginIds);
      mkPluginBlock =
        {
          checks,
          varName,
          module,
          version,
        }:
        builtins.concatStringsSep "\n" [
          "            if (${checks}) {"
          "                ${keyword} ${varName} = requested.version ?: \"${version}\""
          "                useModule(\"${module}:\$${varName}\")"
          "            }"
        ];
      agpBlock = mkPluginBlock {
        checks = idChecks;
        varName = "agpVersion";
        module = "com.android.tools.build:gradle";
        version = agpVersion;
      };
      mkExtraPluginBlock =
        {
          ids,
          module,
          version,
          varName ? null,
        }:
        let
          checks = builtins.concatStringsSep " || " (map (id: "requested.id.id == ${quote id}") ids);
          # Derive variable name: use explicit varName, or take the last segment
          # of the module coordinate (e.g. "kotlin-gradle-plugin" → "kotlinVersion")
          lastSegment = builtins.elemAt (builtins.split ":" module) 2;
          # "kotlin-gradle-plugin" → "kotlin"  (take first word before hyphen)
          firstName = builtins.head (builtins.split "-" lastSegment);
          derivedVarName = "${firstName}Version";
          finalVarName = if varName != null then varName else derivedVarName;
        in
        mkPluginBlock {
          inherit checks module version;
          varName = finalVarName;
        };
      allPluginBlocks = builtins.concatStringsSep "\n" (
        [ agpBlock ] ++ (map mkExtraPluginBlock extraPlugins)
      );
    in
    builtins.concatStringsSep "\n" [
      "pluginManagement {"
      "    resolutionStrategy {"
      "        eachPlugin {"
      allPluginBlocks
      "        }"
      "    }"
      ""
    ];

  # Generate a postPatch snippet that replaces "pluginManagement {" in the given
  # settings file with a version that includes the resolutionStrategy.
  patchSettingsGradle =
    {
      # The settings file to patch.  Defaults to settings.gradle.kts.
      file ? "settings.gradle.kts",
      # All other args forwarded to mkResolutionBlock.
      ...
    }@args:
    let
      blockArgs = builtins.removeAttrs args [ "file" ];
      # Auto-detect lang from file extension if not explicitly set.
      autoLang = if builtins.match ".*\\.kts$" file != null then "kotlin" else "groovy";
      finalArgs = {
        lang = autoLang;
      }
      // blockArgs;
      block = mkResolutionBlock finalArgs;
      # Escape the block for use in bash $'...' quoting:
      # - single quotes become \'
      # - backslashes become \\
      # - newlines become \n (which $'...' interprets as actual newline)
      escaped =
        builtins.replaceStrings
          [
            "\\"
            "'"
            "\n"
          ]
          [
            "\\\\"
            "\\'"
            "\\n"
          ]
          block;
    in
    ''
      substituteInPlace ${file} \
        --replace-fail "pluginManagement {" $'${escaped}'
    '';
in
{
  inherit mkResolutionBlock patchSettingsGradle;
}
