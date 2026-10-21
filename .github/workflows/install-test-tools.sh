#!/bin/bash -e

# Installs the package manager tooling the unit specs shell out to on GitHub
# Actions runners. Versions match the ones in the Dockerfile.

GRADLE_VERSION=5.6.4
JDK_VERSION=11

TOOLS_DIR="${RUNNER_TEMP:-/tmp}/license_finder-tools"
mkdir -p "$TOOLS_DIR"

# godep
go install github.com/tools/godep@latest
echo "$(go env GOPATH)/bin" >> "$GITHUB_PATH"

# JDK: Gradle 5 doesn't run on the runner's default JDK
curl -sSL -o "$TOOLS_DIR/jdk.tar.gz" \
  "https://api.adoptium.net/v3/binary/latest/$JDK_VERSION/ga/linux/x64/jdk/hotspot/normal/eclipse"
mkdir -p "$TOOLS_DIR/jdk"
tar -xzf "$TOOLS_DIR/jdk.tar.gz" -C "$TOOLS_DIR/jdk" --strip-components=1
echo "JAVA_HOME=$TOOLS_DIR/jdk" >> "$GITHUB_ENV"
echo "$TOOLS_DIR/jdk/bin" >> "$GITHUB_PATH"

# Gradle: newer versions refuse to run outside of a Gradle build
curl -sSL -o "$TOOLS_DIR/gradle.zip" \
  "https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip"
unzip -q "$TOOLS_DIR/gradle.zip" -d "$TOOLS_DIR"
echo "$TOOLS_DIR/gradle-$GRADLE_VERSION/bin" >> "$GITHUB_PATH"
