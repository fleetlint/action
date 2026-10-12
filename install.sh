#!/usr/bin/env bash
# Downloads a fleetlint release for this runner, verifies it and puts it on PATH.
set -euo pipefail
repo=https://github.com/fleetlint/fleetlint

version=$INPUT_VERSION
if [ "$version" = latest ]; then
  url=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "$repo/releases/latest")
  version=${url##*/}
fi
v=${version#v}

case "$RUNNER_OS" in
  Linux) os=linux ext=tar.gz ;;
  macOS) os=darwin ext=tar.gz ;;
  Windows) os=windows ext=zip ;;
  *) echo "::error::fleetlint has no build for runner OS $RUNNER_OS"; exit 1 ;;
esac
case "$RUNNER_ARCH" in
  X64) arch=amd64 ;;
  ARM64) arch=arm64 ;;
  *) echo "::error::fleetlint has no build for runner architecture $RUNNER_ARCH"; exit 1 ;;
esac

archive="fleetlint_${v}_${os}_${arch}.${ext}"
base="$repo/releases/download/v$v"
dir="$RUNNER_TEMP/fleetlint-$v"
mkdir -p "$dir"
cd "$dir"
curl -fsSLO "$base/$archive"
curl -fsSLO "$base/checksums.txt"

case "$INPUT_VERIFY" in
  auto | cosign)
    if command -v cosign >/dev/null; then
      curl -fsSLO "$base/checksums.txt.sigstore.json"
      cosign verify-blob --bundle checksums.txt.sigstore.json \
        --certificate-identity "$repo/.github/workflows/release.yml@refs/tags/v$v" \
        --certificate-oidc-issuer https://token.actions.githubusercontent.com \
        checksums.txt
    elif [ "$INPUT_VERIFY" = cosign ]; then
      echo "::error::verify: cosign needs cosign on PATH (sigstore/cosign-installer)"
      exit 1
    fi
    ;;
  checksum) ;;
  *) echo "::error::verify must be auto, cosign or checksum, not $INPUT_VERIFY"; exit 1 ;;
esac

line=$(grep " $archive\$" checksums.txt)
if command -v sha256sum >/dev/null; then
  echo "$line" | sha256sum -c -
else
  echo "$line" | shasum -a 256 -c -
fi

if [ "$ext" = zip ]; then
  unzip -oq "$archive"
else
  tar -xzf "$archive"
fi
echo "$dir" >>"$GITHUB_PATH"
echo "version=v$v" >>"$GITHUB_OUTPUT"
