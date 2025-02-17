import os
import glob
import subprocess
import simpleaudio as sa
from pydub import AudioSegment
from pyannote.audio import Pipeline
import logging
import time
from datetime import datetime
import sys

###############################################################################
# USER CONFIG – EDIT THESE AS NEEDED
###############################################################################
# HF_TOKEN = os.getenv("HF_TOKEN", "<YOUR_HUGGINGFACE_ACCESS_TOKEN>")
HF_TOKEN = os.getenv("HF_TOKEN", "foobar")
DATA_FOLDER = "data"  # Folder containing your .m4a files
TEMP_FOLDER = "temp_wav"  # Temporary folder for intermediate WAV files
MERGED_WAV = "merged.wav"  # Final combined WAV file
FINAL_SPEAKER_LABEL = "spk0"  # Which speaker label to extract
FINAL_OUTPUT_WAV = "speaker_final.wav"  # Output WAV for extracted speaker
LOG_FILE = f"audio_processing_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
###############################################################################


def setup_logging():
    """Configure logging to both file and console."""
    if not os.path.exists("logs"):
        os.makedirs("logs")

    log_path = os.path.join("logs", LOG_FILE)

    logging.basicConfig(
        level=logging.DEBUG,
        format="%(asctime)s - %(levelname)s - %(message)s",
        handlers=[logging.FileHandler(log_path), logging.StreamHandler(sys.stdout)],
    )
    logging.info("Logging initialized - Log file: %s", log_path)
    return log_path


def convert_m4a_to_wav(input_file, output_file):
    """Convert a single M4A file to WAV with consistent parameters."""
    cmd = [
        "ffmpeg",
        "-y",  # Overwrite output file if it exists
        "-i",
        input_file,
        "-acodec",
        "pcm_s16le",  # Use PCM 16-bit encoding
        "-ac",
        "1",  # Convert to mono
        "-ar",
        "44100",  # Set sample rate to 44.1kHz
        output_file,
    ]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            logging.error(f"Error converting {input_file}: {result.stderr}")
            return False
        return True
    except Exception as e:
        logging.error(f"Exception converting {input_file}: {str(e)}")
        return False


def get_file_info(filepath):
    """Get file information including size and last modified time."""
    stats = os.stat(filepath)
    size_mb = stats.st_size / (1024 * 1024)
    modified_time = datetime.fromtimestamp(stats.st_mtime)
    return size_mb, modified_time


def log_file_details(filepath):
    """Log detailed information about a file."""
    if os.path.exists(filepath):
        size_mb, modified_time = get_file_info(filepath)
        logging.info(f"File: {filepath}")
        logging.info(f"  Size: {size_mb:.2f} MB")
        logging.info(f"  Last modified: {modified_time}")
    else:
        logging.warning(f"File not found: {filepath}")


def play_audio(wav_file):
    """Play audio using simpleaudio."""
    try:
        logging.info(f"Attempting to play audio file: {wav_file}")
        wave_obj = sa.WaveObject.from_wave_file(wav_file)
        play_obj = wave_obj.play()
        logging.info("Audio playback started")
        play_obj.wait_done()
        logging.info("Audio playback completed")
    except Exception as e:
        logging.error(f"Error playing audio: {str(e)}")
        raise


def main():
    start_time = time.time()
    log_path = setup_logging()

    logging.info("=== Audio Processing Script Started ===")
    logging.info(f"Python version: {sys.version}")
    logging.info(f"Working directory: {os.getcwd()}")

    try:
        # Create temp directory for WAV files
        if not os.path.exists(TEMP_FOLDER):
            os.makedirs(TEMP_FOLDER)
            logging.info(f"Created temporary directory: {TEMP_FOLDER}")

        # 1) Gather and convert all M4A files
        logging.info(f"Searching for .m4a files in {DATA_FOLDER}")
        m4a_files = sorted(glob.glob(os.path.join(DATA_FOLDER, "*.m4a")))
        if not m4a_files:
            logging.error(f"No .m4a files found in folder '{DATA_FOLDER}'. Exiting.")
            return

        logging.info(f"Found {len(m4a_files)} M4A files:")
        wav_files = []
        for i, m4a in enumerate(m4a_files, 1):
            size_mb, modified_time = get_file_info(m4a)
            logging.info(f"Converting {i}/{len(m4a_files)}: {m4a} ({size_mb:.2f} MB)")

            wav_file = os.path.join(TEMP_FOLDER, f"{i:03d}_converted.wav")
            if convert_m4a_to_wav(m4a, wav_file):
                wav_files.append(wav_file)
                log_file_details(wav_file)
            else:
                logging.error(f"Skipping {m4a} due to conversion error")

        if not wav_files:
            logging.error("No WAV files were successfully created. Exiting.")
            return

        # 2) Combine all WAV files
        logging.info(f"Combining {len(wav_files)} WAV files into {MERGED_WAV}")
        combine_cmd = [
            "ffmpeg",
            "-y",
            "-f",
            "concat",
            "-safe",
            "0",
            "-i",
            "-",
            "-c",
            "copy",
            MERGED_WAV,
        ]

        # Create input list for ffmpeg
        input_list = "".join(f"file '{f}'\n" for f in wav_files)

        logging.debug(f"FFmpeg command: {' '.join(combine_cmd)}")
        process = subprocess.run(
            combine_cmd, input=input_list, text=True, capture_output=True
        )

        if process.returncode != 0:
            logging.error(f"Error combining WAV files: {process.stderr}")
            raise Exception("FFmpeg merge command failed")

        log_file_details(MERGED_WAV)

        # 3) Speaker diarization
        logging.info("Initializing speaker diarization pipeline")
        pipeline = Pipeline.from_pretrained(
            "pyannote/speaker-diarization", use_auth_token=HF_TOKEN
        )
        logging.info("Running diarization...")
        diarization_result = pipeline(MERGED_WAV)

        # 4) Extract speaker segments
        logging.info(f"Processing segments for speaker '{FINAL_SPEAKER_LABEL}'")
        combined_audio = AudioSegment.from_wav(MERGED_WAV)
        speaker_audio = AudioSegment.empty()
        segment_count = 0
        total_duration = 0

        for segment, _, speaker_label in diarization_result.itertracks(
            yield_label=True
        ):
            start_ms = int(segment.start * 1000)
            end_ms = int(segment.end * 1000)
            duration = end_ms - start_ms

            if speaker_label == FINAL_SPEAKER_LABEL:
                segment_count += 1
                total_duration += duration
                speaker_audio += combined_audio[start_ms:end_ms]
                logging.debug(
                    f"Extracted segment {segment_count}: {duration / 1000:.2f}s at {start_ms / 1000:.2f}s"
                )

        # 5) Export final audio
        if len(speaker_audio) == 0:
            logging.warning(f"No audio found for speaker label '{FINAL_SPEAKER_LABEL}'")
        else:
            logging.info(f"Exporting to {FINAL_OUTPUT_WAV}")
            speaker_audio.export(FINAL_OUTPUT_WAV, format="wav")
            log_file_details(FINAL_OUTPUT_WAV)

            play_response = input("Would you like to play the processed audio? (y/n): ")
            if play_response.lower() == "y":
                logging.info("Starting audio playback")
                play_audio(FINAL_OUTPUT_WAV)

        # Cleanup
        logging.info("Cleaning up temporary files...")
        for wav_file in wav_files:
            try:
                os.remove(wav_file)
                logging.debug(f"Removed temporary file: {wav_file}")
            except Exception as e:
                logging.warning(f"Error removing {wav_file}: {str(e)}")
        try:
            os.rmdir(TEMP_FOLDER)
            logging.info(f"Removed temporary directory: {TEMP_FOLDER}")
        except Exception as e:
            logging.warning(f"Error removing temp directory: {str(e)}")

        total_time = time.time() - start_time
        logging.info(f"=== Processing completed in {total_time:.2f} seconds ===")
        logging.info(f"Log file location: {log_path}")

    except Exception as e:
        logging.error(f"Error during processing: {str(e)}", exc_info=True)
        raise
    finally:
        logging.info("=== Script Finished ===")


if __name__ == "__main__":
    main()
