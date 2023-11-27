import glob
import os

from annotation import create_time_annotation_csv
from pydub import AudioSegment

# from pydub.playback import play
from pydub.silence import detect_nonsilent

DIR_PATHS = [
    "assets/evals/Halion_CleanGuitarVX",
    "assets/evals/Halion_CleanStratGuitar",
    "assets/evals/HojoGuitar",
    "assets/evals/RealStrat",
]


def __create_nonsilent_audio(file_path: str) -> tuple[AudioSegment, list[tuple[int, int]]]:
    sound = AudioSegment.from_file(file_path)
    durations = detect_nonsilent(sound, min_silence_len=100, silence_thresh=-40)
    nonsilent_sound = sum([sound[range[0] : range[1]] for range in durations])

    nonsilent_durations = []
    seek = 0
    for duration in durations:
        nonsilent_duration = (seek, seek + duration[1] - duration[0])
        seek = nonsilent_duration[1] + 1
        nonsilent_durations.append(nonsilent_duration)

    return nonsilent_sound, nonsilent_durations


if __name__ == "__main__":
    for dir_path in DIR_PATHS:
        files = glob.glob(f"{dir_path}/*.wav")

        for file in files:
            sound, durations = __create_nonsilent_audio(file)
            # print(durations)
            # play(sound)
            output_dir_path = dir_path + "_nonsilent"
            os.makedirs(output_dir_path, exist_ok=True)

            file_name = file.split("/")[-1]

            sound.export(os.path.join(output_dir_path, file_name), format="wav")

            source_name = dir_path.split("/")[-1]

            # 一旦代表で一つだけアノテーションを採用する
            if file_name.startswith("1"):
                create_time_annotation_csv(
                    durations,
                    output_path=f"assets/csv/correct_time_annotation_{source_name}_nonsilent.csv",
                )

            print("done: " + file)
