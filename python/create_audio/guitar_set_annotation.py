import json
import os
from typing import Any, Literal

from annotation import create_time_annotation_csv_from_slices
from path import get_file_name, get_sorted_audio_paths, get_source_name

__FileType = Literal["comp", "solo"]


class __ObjectLike(dict[str, object]):
    __getattr__ = dict.get


def __get_annotation_path_from_audio_file_path(path: str, file_type: __FileType) -> str:
    file_name = get_file_name(path)
    index = file_name.find(file_type)
    file_name = file_name[: index + len(file_type)]

    return os.path.join(
        "assets",
        "evals",
        "3371780",
        "annotation",
        f"{file_name}.jams",
    )


def __map_chord_type_name_from_guitar_set(label: str) -> str:
    match label:
        case "maj":
            return ""
        case "min":
            return "m"
        case "7":
            return "7"
        case "hdim7":
            return "m7b5"
        case name:
            raise NotImplementedError(name)


def __get_chord_label(json: Any) -> str:
    note, type = json.value.split(":")

    return str(note) + __map_chord_type_name_from_guitar_set(type)


def __get_slice(json: Any) -> tuple[float, float]:
    return (json.time, json.time + json.duration)


def __create_chord_annotation_from_audio_path(path: str, is_simple: bool = True) -> None:
    assert "comp" in path

    annotation_path = __get_annotation_path_from_audio_file_path(path, "comp")

    source_name = get_source_name(path)
    file_name = get_file_name(path)
    output_dir_path = os.path.join(
        "assets",
        "csv",
        source_name,
    )
    os.makedirs(output_dir_path, exist_ok=True)

    with open(annotation_path) as f:
        obj = json.load(f, object_hook=__ObjectLike)

        chord_annotation_index = 14 if is_simple else 15

        data = obj.annotations[chord_annotation_index].data
        # print(data)  # コードのリスト

        labels = list(map(__get_chord_label, data))
        slices = list(map(__get_slice, data))

        create_time_annotation_csv_from_slices(
            labels,
            slices,
            output_path=os.path.join(output_dir_path, f"{file_name}.csv"),
        )


if __name__ == "__main__":
    audio_mono_mic_dir_path = "assets/evals/3371780/audio_mono-mic"

    for path in get_sorted_audio_paths(audio_mono_mic_dir_path):
        if "comp" not in path:
            continue

        __create_chord_annotation_from_audio_path(path)
