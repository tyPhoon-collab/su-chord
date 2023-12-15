import os

from annotation import (
    create_time_annotation_csv_from_slices,
    get_chord_labels_from_conv,
    map_milliseconds_to_seconds,
)
from pydub import AudioSegment

# from pydub.playback import play
from pydub.silence import detect_nonsilent

from python.path_util import (
    DIR_PATHS,
    get_file_name,
    get_sorted_audio_paths,
    get_source_name,
)


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
        for index, path in enumerate(get_sorted_audio_paths(dir_path)):
            sound, slices = __create_nonsilent_audio(path)

            sound_source_name = get_source_name(path) + "_nonsilent"
            file_name = get_file_name(path)

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
                get_chord_labels_from_conv(index),
                map_milliseconds_to_seconds(slices),
                output_path=os.path.join(annotation_output_dir_path, f"{file_name}.csv"),
            )

            print("done: " + path)
