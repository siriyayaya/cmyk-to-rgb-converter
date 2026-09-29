# cmyk-to-rgb-converter

A small macOS shell script that converts CMYK JPG/PNG/TIFF images to sRGB
using the built-in `sips` tool — without the quality collapse `sips`
produces by default.

## The problem

Running the "obvious" `sips` command to convert color space:

```bash
sips -m "sRGB Profile.icc" --matchTo "sRGB Profile.icc" in.jpg --out out.jpg
```

silently re-encodes the JPEG at `sips`'s default ("normal") quality preset.
For a near-lossless print master, that can shrink the file to a fraction of
its original size and visibly soften fine detail — even though the only
thing you asked for was a color space change.

## The fix

Add `--setProperty formatOptions best`:

```bash
sips -m "sRGB Profile.icc" --matchTo "sRGB Profile.icc" \
     --setProperty formatOptions best \
     in.jpg --out out.jpg
```

This script wraps that up into a one-liner you can point at a single file
or a whole folder, and it only touches files that are actually CMYK —
anything already RGB is left alone (or copied through, in batch mode).

## Usage

```bash
# single file (writes photo_rgb.jpg next to the original if no output given)
./cmyk2rgb.sh photo_cmyk.jpg
./cmyk2rgb.sh photo_cmyk.jpg photo_rgb.jpg

# whole folder — converts every CMYK image inside, copies RGB ones through
./cmyk2rgb.sh ./originals ./rgb
```

Supported input types: `.jpg`, `.jpeg`, `.png`, `.tif`, `.tiff`.

## Requirements

- macOS (uses the built-in `sips` command-line tool — no install needed)

## Verifying the result

```bash
sips -g space -g pixelWidth -g pixelHeight before.jpg after.jpg
```

Pixel dimensions and DPI should be unchanged, and file size should stay in
the same ballpark as the original (not a fraction of it) — that's the
signal the conversion didn't quietly re-compress the image.
