import os
import glob
import subprocess
from pydub import AudioSegment
from pyannote.audio import Pipeline

###############################################################################
# USER CONFIG – EDIT THESE AS NEEDED
###############################################################################
HF_TOKEN = os.getenv("HF_TOKEN", "<YOUR_HUGGINGFACE_ACCESS_TOKEN>")
# If you don't want to store your token in the script, set an env variable:
#    export HF_TOKEN="hf_xxx..."
# and remove the default string above.

DATA_FOLDER = "data"  # Folder containing your .m4a files
MERGED_WAV = "merged.wav"  # Temporary combined file name
FINAL_SPEAKER_LABEL = (
    "spk0"  # Which speaker label to extract (e.g. spk0, spk1, spk2, etc.)
)
FINAL_OUTPUT_WAV = "speaker_final.wav"  # Name of output WAV for that speaker
###############################################################################


def main():
    # 1) Gather all .m4a files in data folder
    m4a_files = sorted(glob.glob(os.path.join(DATA_FOLDER, "*.m4a")))
    if not m4a_files:
        print(f"No .m4a files found in folder '{DATA_FOLDER}'. Exiting.")
        return

    print("Found M4A files:")
    for f in m4a_files:
        print(f"  - {f}")

    # 2) Create a temporary list file for ffmpeg concatenation
    #    This instructs ffmpeg how to merge
    list_file = "inputs.txt"
    with open(list_file, "w") as f:
        for m4a in m4a_files:
            # ffmpeg concat format: file 'path/to/file'
            f.write(f"file '{m4a}'\n")

    # 3) Combine all M4A into one merged WAV (mono, 44.1kHz)
    print(f"\nCombining into {MERGED_WAV} ...")
    cmd_combine = [
        "ffmpeg",
        "-f",
        "concat",
        "-safe",
        "0",
        "-i",
        list_file,
        "-ac",
        "1",  # mono
        "-ar",
        "44100",  # 44.1 kHz
        "-y",  # overwrite
        MERGED_WAV,
    ]
    subprocess.run(cmd_combine, check=True)
    print(f"Created {MERGED_WAV} successfully.")

    # 4) Speaker diarization using pyannote.audio Pipeline in Python
    print("\nRunning pyannote.audio speaker diarization...")
    pipeline = Pipeline.from_pretrained(
        "pyannote/speaker-diarization", use_auth_token=HF_TOKEN
    )
    diarization_result = pipeline(MERGED_WAV)
    # diarization_result is a pyannote.core.Annotation object

    # 5) Load merged WAV via pydub for segment extraction
    combined_audio = AudioSegment.from_wav(MERGED_WAV)

    # 6) Iterate over diarization segments; if label matches, slice that portion
    print(f"Extracting segments for speaker label '{FINAL_SPEAKER_LABEL}'...")
    speaker_audio = AudioSegment.empty()

    for segment, _, speaker_label in diarization_result.itertracks(yield_label=True):
        start_ms = int(segment.start * 1000)  # pydub uses milliseconds
        end_ms = int(segment.end * 1000)
        if speaker_label == FINAL_SPEAKER_LABEL:
            # Append this segment to our speaker_audio
            speaker_audio += combined_audio[start_ms:end_ms]

    # 7) Export final speaker-only WAV
    if len(speaker_audio) == 0:
        print(f"No audio found for speaker label '{FINAL_SPEAKER_LABEL}'.")
    else:
        speaker_audio.export(FINAL_OUTPUT_WAV, format="wav")
        print(
            f"\nFinal WAV created: {FINAL_OUTPUT_WAV} (speaker = {FINAL_SPEAKER_LABEL})"
        )

    # Clean-up: remove temporary list file if you like
    if os.path.exists(list_file):
        os.remove(list_file)

    print("\nDone.")


if __name__ == "__main__":
    main()
