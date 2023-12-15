import json
import os
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any, Literal

from annotation import create_time_annotation_csv_from_slices

from python.path_util import get_file_name, get_sorted_audio_paths, get_source_name

_FileType = Literal["comp", "solo"]

_CHORD_ANNOTATION_SIMPLE_INDEX = 14
_CHORD_ANNOTATION_COMPLEX_INDEX = 15


class _ObjectLike(dict[str, object]):
    __getattr__ = dict.get


class GuitarSetAnnotator(ABC):
    @abstractmethod
    def get_chord_label(self, json_obj: Any) -> str:
        pass

    def get_slice(self, json_obj: Any) -> tuple[float, float]:
        return json_obj.time, json_obj.time + json_obj.duration


class SimpleGuitarSetAnnotator(GuitarSetAnnotator):
    def get_chord_label(self, json_obj: Any) -> str:
        note, chord_type = json_obj.value.split(":")  # like C:maj

        return str(note) + self.__map_chord_type_name_from_guitar_set(chord_type)

    @staticmethod
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


class LooseComplexGuitarSetAnnotator(GuitarSetAnnotator):
    def get_chord_label(self, json_obj: Any) -> str:
        note, quality = json_obj.value.split(":")

        chord_type, _ = quality.split("/")

        return str(note) + self.__map_chord_type_name_from_guitar_set(chord_type)

    @staticmethod
    def __map_chord_type_name_from_guitar_set(label: str) -> str:
        label = label.split("(")[0]
        match label:
            case "":
                return ""  # maybe one note.
            case "maj":
                return ""
            case "maj6":
                return "6"
            case "maj7":
                return "M7"
            case "maj9":
                return "M9"
            case "min":
                return "m"
            case "min6":
                return "m6"
            case "min7":
                return "m7"
            case "minmaj7":
                return "mM7"
            case "min9":
                return "m9"
            case "min11":
                return "m11"
            case "7":
                return "7"
            case "9":
                return "9"
            case "11":
                return "11"
            case "aug":
                return "aug"
            case "dim7":
                return "dim7"
            case "hdim7":
                return "m7b5"
            case "sus2":
                return "sus2"  # deal as add9?
            case "sus4":
                return "sus4"

            case name:
                raise NotImplementedError(name)


class ComplexGuitarSetAnnotator(GuitarSetAnnotator):
    def __init__(self) -> None:
        super().__init__()
        raise NotImplementedError()

    def get_chord_label(self, json_obj: Any) -> str:
        note, quality = json_obj.value.split(":")

        chord_type, root = quality.split("/")

        return str(note) + self.__map_chord_type_name_from_guitar_set(chord_type)

    @staticmethod
    def __map_chord_type_name_from_guitar_set(label: str) -> str:
        label = label.split("(")[0]
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


@dataclass
class GuitarSetAnnotationCreator:
    chord_annotation_index: int
    annotator: GuitarSetAnnotator

    @staticmethod
    def get_annotation_path_from_audio_path(output_path: str, file_type: _FileType) -> str:
        file_name = get_file_name(output_path)
        index = file_name.find(file_type)
        file_name = file_name[: index + len(file_type)]

        return os.path.join(
            "assets",
            "evals",
            "3371780",
            "annotation",
            f"{file_name}.jams",
        )

    def create(self, audio_path: str) -> None:
        assert "comp" in audio_path

        annotation_path = self.get_annotation_path_from_audio_path(audio_path, "comp")

        source_name = get_source_name(audio_path)
        file_name = get_file_name(audio_path)
        output_dir_path = os.path.join(
            "assets",
            "csv",
            source_name,
        )
        os.makedirs(output_dir_path, exist_ok=True)
        output_path = os.path.join(output_dir_path, f"{file_name}.csv")

        with open(annotation_path) as f:
            obj = json.load(f, object_hook=_ObjectLike)

            data = obj.annotations[self.chord_annotation_index].data
            # print(data)  # コードのリスト

            labels = list(map(self.annotator.get_chord_label, data))
            slices = list(map(self.annotator.get_slice, data))

            create_time_annotation_csv_from_slices(labels, slices, output_path)


if __name__ == "__main__":
    audio_mono_mic_dir_path = "assets/evals/3371780/audio_mono-mic"

    for path in get_sorted_audio_paths(audio_mono_mic_dir_path):
        if "comp" not in path:
            continue

        # GuitarSetAnnotationCreator(_CHORD_ANNOTATION_SIMPLE_INDEX, SimpleGuitarSetAnnotator()).create(path)
        GuitarSetAnnotationCreator(_CHORD_ANNOTATION_COMPLEX_INDEX, LooseComplexGuitarSetAnnotator()).create(path)
