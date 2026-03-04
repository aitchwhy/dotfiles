#!/bin/zsh
# convert-video-to-mp4.sh — Convert non-MP4 video files to MP4
# Usage: ./convert-video-to-mp4.sh <input-file>
# Called by Hazel rule (passes $1) or directly from CLI.
# Dependencies: ffmpeg, ffprobe (brew install ffmpeg)
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

INPUT="$1"
BASENAME="${INPUT:t:r}"
DIR="${INPUT:h}"
OUTPUT="${DIR}/${BASENAME}.mp4"

# --- Dependency check ---
for cmd in ffmpeg ffprobe; do
    if ! command -v "$cmd" &>/dev/null; then
        osascript -e "display notification \"$cmd not found. Run: brew install ffmpeg\" with title \"Hazel: Video Convert Failed\"" 2>/dev/null
        echo "ERROR: $cmd not found. Install with: brew install ffmpeg" >&2
        exit 1
    fi
done

# --- Guard: skip if already MP4 ---
[[ "${INPUT:e:l}" == "mp4" ]] && exit 0

# --- Avoid overwriting ---
if [[ -f "$OUTPUT" ]]; then
    OUTPUT="${DIR}/${BASENAME}_converted.mp4"
fi

# --- Detect existing codecs for smart remux ---
VIDEO_CODEC=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$INPUT" 2>/dev/null || echo "unknown")
AUDIO_CODEC=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$INPUT" 2>/dev/null || echo "none")

# --- Convert ---
if [[ "$VIDEO_CODEC" == "h264" && ("$AUDIO_CODEC" == "aac" || "$AUDIO_CODEC" == "none") ]]; then
    # Fast remux — already H.264/AAC, just repackage container (instant, lossless)
    ffmpeg -y -i "$INPUT" -c copy -movflags +faststart "$OUTPUT"
else
    # Re-encode: try Apple Silicon HW accel first, fall back to software
    ffmpeg -y -i "$INPUT" \
        -c:v h264_videotoolbox -q:v 65 \
        -c:a aac -b:a 128k \
        -movflags +faststart \
        "$OUTPUT" 2>/dev/null || \
    ffmpeg -y -i "$INPUT" \
        -c:v libx264 -preset medium -crf 23 \
        -c:a aac -b:a 128k \
        -movflags +faststart \
        "$OUTPUT"
fi

# --- Verify output and trash original ---
if [[ -f "$OUTPUT" && -s "$OUTPUT" ]]; then
    mv "$INPUT" ~/.Trash/
else
    echo "ERROR: Conversion failed — output missing or empty" >&2
    exit 1
fi
