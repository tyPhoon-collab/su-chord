import glob
import os

import natsort
import pandas as pd
from path import DIR_PATHS
from pydub import AudioSegment
from pydub.silence import detect_nonsilent

correct_df = None


def create_time_annotation_csv_from_durations(labels: list[str], durations: list[int], output_path: str) -> None:
    slices = []
    seek = 0
    for duration in durations:
        slices.append((seek, duration + seek))
        seek += duration

    create_time_annotation_csv_from_slices(labels, slices, output_path)


def create_time_annotation_csv_from_slices(labels: list[str], slices: list[tuple[int, int]], output_path: str) -> None:
    assert len(labels) == len(slices)

    df = pd.DataFrame(
        [[labels[i], *slice] for i, slice in enumerate(slices)],
        columns=["label", "start", "end"],
    )
    df.to_csv(output_path, index=False)


def get_labels_from_conv(sound_index: int) -> list[str]:
    global correct_df
    if correct_df is None:
        correct_df = pd.read_csv("assets/csv/correct_only_sharp.csv")

    return list[str](correct_df.iloc[sound_index][1:].to_list())


if __name__ == "__main__":
    # migration conv to prop
    for dir_path in DIR_PATHS:
        files = glob.glob(f"{dir_path}/*.wav")
        sorted_files = natsort.natsorted(files)

        for index, file in enumerate(sorted_files):
            sound = AudioSegment.from_file(file)
            ranges = detect_nonsilent(sound, min_silence_len=100, silence_thresh=-40)

            sound_source_name = dir_path.split("/")[-1]
            file_name = file.split("/")[-1]

            output_dir_path = os.path.join(
                "assets",
                "csv",
                sound_source_name,
            )
            os.makedirs(output_dir_path, exist_ok=True)

            create_time_annotation_csv_from_slices(
                get_labels_from_conv(index),
                ranges,
                output_path=os.path.join(output_dir_path, f"{file_name}.csv"),
            )

            print("done: " + file)

    # sound = AudioSegment.from_file("assets/evals/Halion_CleanGuitarVX/1_青春の影.wav")
    # ranges = detect_nonsilent(sound, min_silence_len=100, silence_thresh=-40)

    # print(ranges)

    # assert len(ranges) == 20

    # create_time_annotation_csv(
    #     ranges,
    #     output_path="assets/csv/correct_time_annotation_Halion_CleanGuitarVX.csv",
    # )

    # sound = AudioSegment.from_file("assets/evals/HojoGuitar/1_Hojo.wav")
    # ranges = detect_nonsilent(sound, min_silence_len=100, silence_thresh=-40)

    # print(ranges)

    # assert len(ranges) == 20

    # create_time_annotation_csv_from_slices(
    #     ranges,
    #     output_path="assets/csv/correct_time_annotation_HojoGuitar.csv",
    # )
