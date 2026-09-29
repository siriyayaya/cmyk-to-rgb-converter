#!/usr/bin/env bash
#
# cmyk2rgb.sh — Convert CMYK JPG/PNG/TIFF images to sRGB using macOS `sips`,
# without the quality/size collapse that `sips` produces by default.
#
# Why this exists:
#   Running `sips -m <profile> --matchTo <profile> in.jpg --out out.jpg`
#   silently re-encodes the JPEG at a "normal" quality preset, which can
#   shrink a near-lossless print master by 4-5x and visibly degrade it.
#   Adding `--setProperty formatOptions best` fixes this — output stays
#   close in size and quality to the original.
#
# Usage:
#   ./cmyk2rgb.sh <input> [output]
#   ./cmyk2rgb.sh <input-dir> <output-dir>
#
# Examples:
#   ./cmyk2rgb.sh photo_cmyk.jpg photo_rgb.jpg
#   ./cmyk2rgb.sh ./originals ./rgb          # batch-converts every image in the folder
#
# Only files whose color space is actually CMYK are converted; RGB files
# are skipped (or copied through, in batch mode) so you can safely point
# this at a folder with a mix of both.

set -euo pipefail

SRGB_PROFILE="/System/Library/ColorSync/Profiles/sRGB Profile.icc"

usage() {
  echo "Usage:"
  echo "  $(basename "$0") <input-file> [output-file]"
  echo "  $(basename "$0") <input-dir> <output-dir>"
  exit 1
}

convert_one() {
  local in="$1" out="$2"
  local space
  space=$(sips -g space "$in" 2>/dev/null | awk '/space:/{print $2}')

  if [ "$space" != "CMYK" ]; then
    echo "skip (already ${space:-unknown}): $in"
    if [ "$in" != "$out" ]; then
      cp "$in" "$out"
    fi
    return 0
  fi

  sips -m "$SRGB_PROFILE" --matchTo "$SRGB_PROFILE" \
       --setProperty formatOptions best \
       "$in" --out "$out" >/dev/null

  local in_size out_size
  in_size=$(stat -f%z "$in")
  out_size=$(stat -f%z "$out")
  echo "converted: $in  (CMYK, $((in_size/1024))KB) -> $out  (RGB, $((out_size/1024))KB)"
}

main() {
  [ $# -ge 1 ] || usage
  local input="$1"

  if [ -d "$input" ]; then
    local outdir="${2:-}"
    [ -n "$outdir" ] || usage
    mkdir -p "$outdir"
    local found=0
    while IFS= read -r -d '' f; do
      found=1
      local base
      base=$(basename "$f")
      convert_one "$f" "$outdir/$base"
    done < <(find "$input" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.tif' -o -iname '*.tiff' \) -print0)
    if [ "$found" -eq 0 ]; then
      echo "No image files found in: $input" >&2
      exit 1
    fi
  elif [ -f "$input" ]; then
    local output="${2:-${input%.*}_rgb.${input##*.}}"
    convert_one "$input" "$output"
  else
    echo "Not found: $input" >&2
    exit 1
  fi
}

main "$@"
