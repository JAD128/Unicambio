#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-9.0.3}"
DEST_DIR="${MLKIT_BUNDLES_DIR:-ios/mlkit_bundles}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

BUNDLES=(
  "MLKitImageLabelingResources.bundle"
  "MLKitObjectDetectionCommonResources.bundle"
  "LatinOCRResources.bundle"
)

mkdir -p "$DEST_DIR"

for BUNDLE in "${BUNDLES[@]}"; do
  ZIP_PATH="$TMP_DIR/${BUNDLE}.zip"
  URL="https://github.com/d-date/google-mlkit-swiftpm/releases/download/${VERSION}/${BUNDLE}.zip"

  echo "Descargando ${BUNDLE} desde ${URL}"
  curl -fL --retry 3 --silent --show-error -o "$ZIP_PATH" "$URL"
  unzip -q -o "$ZIP_PATH" -d "$DEST_DIR"

  if [[ ! -d "$DEST_DIR/$BUNDLE" ]]; then
    echo "Faltó ${BUNDLE} después de descomprimir"
    exit 1
  fi

  echo "Listo: $DEST_DIR/$BUNDLE"
done
