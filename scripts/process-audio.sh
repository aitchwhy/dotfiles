#!/bin/bash

# Configuration
API_URL="http://localhost:8000"
DATA_DIR="data"
LOG_FILE="diarization_batch_$(date +%Y%m%d_%H%M%S).log"

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Initialize log file
echo "Starting batch processing at $(date)" >"$LOG_FILE"

# Function to log messages to both console and file
log() {
  echo -e "${2:-$NC}$1${NC}"
  echo "$1" >>"$LOG_FILE"
}

# Function to check job status
check_job_status() {
  local job_id=$1
  local filename=$2
  local attempt=0
  local max_attempts=60 # 10 minutes with 10-second intervals

  while [ $attempt -lt $max_attempts ]; do
    status_response=$(curl -s "${API_URL}/status/${job_id}")

    if echo "$status_response" | grep -q "completed"; then
      log "✓ Processing completed for $filename" "$GREEN"
      return 0
    elif echo "$status_response" | grep -q "failed"; then
      log "✗ Processing failed for $filename" "$RED"
      return 1
    fi

    attempt=$((attempt + 1))
    echo -n "."
    sleep 10
  done

  log "✗ Timeout waiting for $filename to complete" "$RED"
  return 1
}

# Find all audio files in data directory
audio_files=($(find "$DATA_DIR" -type f \( -name "*.wav" -o -name "*.m4a" -o -name "*.mp3" \)))
total_files=${#audio_files[@]}

if [ $total_files -eq 0 ]; then
  log "No audio files found in $DATA_DIR" "$RED"
  exit 1
fi

log "Found $total_files audio files to process" "$YELLOW"
echo "----------------------------------------"

# Process each file
for ((i = 0; i < ${#audio_files[@]}; i++)); do
  file="${audio_files[$i]}"
  filename=$(basename "$file")
  progress=$((($i + 1) * 100 / $total_files))

  log "[$((i + 1))/$total_files] Processing $filename (${progress}%)" "$YELLOW"

  # Submit diarization job
  response=$(curl -s -X POST "${API_URL}/diarize" \
    -H "Content-Type: application/json" \
    -d "{\"file_path\": \"$file\", \"use_webhook\": false}")

  # Extract job ID
  job_id=$(echo $response | grep -o '"job_id":"[^"]*' | cut -d'"' -f4)

  if [ -z "$job_id" ]; then
    log "✗ Failed to submit $filename" "$RED"
    continue
  fi

  log "→ Job ID: $job_id" "$GREEN"
  echo -n "Waiting for processing to complete"

  # Check job status
  check_job_status "$job_id" "$filename"
  echo # New line after status dots
done

echo "----------------------------------------"
log "Batch processing completed" "$GREEN"
log "See $LOG_FILE for details" "$YELLOW"

