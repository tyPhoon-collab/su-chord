import os

from annotation import (
    create_time_annotation_csv_from_slices,
    get_chord_labels_from_conv,
    map_milliseconds_to_seconds,
)
from path import DIR_PATHS, get_file_name, get_sorted_audio_paths, get_source_name
from pydub import AudioSegment
from pydub.silence import detect_nonsilent

if __name__ == "__main__":
    # migration conv to prop
    for dir_path in DIR_PATHS:
        for index, path in enumerate(get_sorted_audio_paths(dir_path)):
            sound = AudioSegment.from_file(path)
            ranges = detect_nonsilent(sound, min_silence_len=100, silence_thresh=-40)

            sound_source_name = get_source_name(path)
            file_name = get_file_name(path)

            output_dir_path = os.path.join(
                "assets",
                "csv",
                sound_source_name,
            )
            os.makedirs(output_dir_path, exist_ok=True)

            create_time_annotation_csv_from_slices(
                get_chord_labels_from_conv(index),
                map_milliseconds_to_seconds(ranges),
                output_path=os.path.join(output_dir_path, f"{file_name}.csv"),
            )

            print("done: " + path)
