import glob
import os

import natsort
from annotation import create_time_annotation_csv_from_slices, get_labels_from_conv
from path import DIR_PATHS
from pydub import AudioSegment

# from pydub.playback import play
from pydub.silence import detect_nonsilent


def __create_nonsilent_audio(file_path: str) -> tuple[AudioSegment, list[tuple[int, int]]]:
    sound = AudioSegment.from_file(file_path)
    slices = detect_nonsilent(sound, min_silence_len=100, silence_thresh=-40)
    nonsilent_sound = sum([sound[slice[0] : slice[1]] for slice in slices])

    nonsilent_slices = []
    seek = 0
    for slice in slices:
        nonsilent_duration = (seek, seek + slice[1] - slice[0])
        seek = nonsilent_duration[1] + 1
        nonsilent_slices.append(nonsilent_duration)

    return nonsilent_sound, nonsilent_slices


if __name__ == "__main__":
    """
    無音部分を削除した音声を作成する
    """
    for dir_path in DIR_PATHS:
        files = glob.glob(f"{dir_path}/*.wav")
        sorted_files = natsort.natsorted(files)

        for index, file in enumerate(sorted_files):
            sound, slices = __create_nonsilent_audio(file)

            sound_source_name = dir_path.split("/")[-1] + "_nonsilent"
            file_name = file.split("/")[-1][:-4]

            output_dir_path = os.path.join(
                "assets",
                "evals",
                sound_source_name,
            )
            os.makedirs(output_dir_path, exist_ok=True)

            sound.export(os.path.join(output_dir_path, f"{file_name}.wav"), format="wav")

            # annotation
            annotation_output_dir_path = os.path.join(
                "assets",
                "csv",
                sound_source_name,
            )
            os.makedirs(annotation_output_dir_path, exist_ok=True)

            create_time_annotation_csv_from_slices(
                get_labels_from_conv(index),
                slices,
                output_path=os.path.join(annotation_output_dir_path, f"{file_name}.csv"),
            )

            print("done: " + file)
