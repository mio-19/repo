# Rewrite google()/mavenCentral()/gradlePluginPortal() to mitmCache file:// repos.
# Used only for normal builds (not IN_GRADLE_UPDATE_DEPS); yarn-installed
# React Native / Expo included builds each declare their own repositories.
#
# Required env:
#   JOPLIN_MITM_CACHE   - path to mitmCache store output
#   JOPLIN_MITM_OVERLAY - local maven repo overlay (portal artifacts + overrides)

rewrite_gradle_repo_shortcuts() {
  local f="$1"
  if grep -q 'google()' "$f"; then
    substituteInPlace "$f" \
      --replace-fail 'google()' "maven { url = uri(\"${JOPLIN_MITM_CACHE}/https/dl.google.com/dl/android/maven2\") }"
  fi
  if grep -q 'mavenCentral()' "$f"; then
    substituteInPlace "$f" \
      --replace-fail 'mavenCentral()' "maven { url = uri(\"${JOPLIN_MITM_OVERLAY}\") }
        maven { url = uri(\"${JOPLIN_MITM_CACHE}/https/repo.maven.apache.org/maven2\") }"
  fi
  if grep -q 'gradlePluginPortal()' "$f"; then
    substituteInPlace "$f" \
      --replace-fail 'gradlePluginPortal()' "maven { url = uri(\"${JOPLIN_MITM_CACHE}/https/plugins.gradle.org/m2\") }"
  fi
}

# Some RN/Expo included builds only declare mavenCentral(); ensure the plugin
# portal shortcut exists so the rewrite below can map it into mitmCache.
ensure_gradle_plugin_portal() {
  local f="$1"
  [ -f "$f" ] || return 0
  if grep -q 'gradlePluginPortal()' "$f"; then
    return 0
  fi
  if grep -q 'repositories { mavenCentral() }' "$f"; then
    substituteInPlace "$f" \
      --replace-fail 'repositories { mavenCentral() }' 'repositories {
        gradlePluginPortal()
        mavenCentral()
      }'
  elif grep -q 'repositories {' "$f"; then
    substituteInPlace "$f" \
      --replace-fail 'repositories {' 'repositories {
        gradlePluginPortal()'
  fi
}

setup_joplin_mitm_overlay() {
  local artifact
  mkdir -p "$JOPLIN_MITM_OVERLAY"
  for artifact in \
    commons-codec/commons-codec/1.10 \
    commons-logging/commons-logging/1.2 \
    org/apache/httpcomponents/httpclient/4.5.6 \
    org/apache/httpcomponents/httpcomponents-client/4.5.6 \
    org/apache/httpcomponents/httpcore/4.4.10 \
    org/apache/httpcomponents/httpcomponents-core/4.4.10 \
    org/apache/httpcomponents/httpmime/4.5.6; do
    mkdir -p "$JOPLIN_MITM_OVERLAY/$artifact"
    ln -s "${JOPLIN_MITM_CACHE}/https/plugins.gradle.org/m2/$artifact/"* \
      "$JOPLIN_MITM_OVERLAY/$artifact/"
  done
  mkdir -p \
    "$JOPLIN_MITM_OVERLAY/com/google/errorprone/error_prone_annotations/2.28.0" \
    "$JOPLIN_MITM_OVERLAY/com/google/errorprone/error_prone_parent/2.28.0"
  ln -s "${ERROR_PRONE_ANNOTATIONS}/error_prone_annotations-2.28.0.jar" \
    "$JOPLIN_MITM_OVERLAY/com/google/errorprone/error_prone_annotations/2.28.0/"
  ln -s "${ERROR_PRONE_ANNOTATIONS}/error_prone_annotations-2.28.0.pom" \
    "$JOPLIN_MITM_OVERLAY/com/google/errorprone/error_prone_annotations/2.28.0/"
  ln -s "${ERROR_PRONE_ANNOTATIONS}/error_prone_parent-2.28.0.pom" \
    "$JOPLIN_MITM_OVERLAY/com/google/errorprone/error_prone_parent/2.28.0/"
}

pin_expo_kotlin_jvm_plugin() {
  local settings="packages/app-mobile/node_modules/expo-modules-autolinking/android/expo-gradle-plugin/settings.gradle.kts"
  [ -f "$settings" ] || return 0
  substituteInPlace "$settings" \
    --replace-fail 'pluginManagement {' 'pluginManagement {
        resolutionStrategy {
          eachPlugin {
            if (requested.id.id == "org.jetbrains.kotlin.jvm") {
              useModule("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
            }
          }
        }'
}

rewrite_joplin_mitm_repos() {
  setup_joplin_mitm_overlay
  find packages/app-mobile -type f \( \
    -name '*.gradle' -o -name '*.gradle.kts' \
    -o -name 'settings.gradle' -o -name 'settings.gradle.kts' \
  \) -print0 | while IFS= read -r -d '' f; do
    rewrite_gradle_repo_shortcuts "$f"
  done
}
