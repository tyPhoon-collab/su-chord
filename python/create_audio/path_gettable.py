import os
from abc import ABC, abstractmethod
from dataclasses import dataclass

from type import Chord


class ChordAudioSourcePathGettable(ABC):
    @abstractmethod
    def __call__(self, chord: Chord) -> str:
        pass


@dataclass
class TanakaMLabChordAudioSourcePathGetter(ChordAudioSourcePathGettable):
    dir_path: str
    source_name: str

    def __call__(self, chord: Chord) -> str:
        root_name = chord.root
        chord_type_name = self.__parse_chord_type(chord.type)
        return os.path.join(self.dir_path, self.source_name, chord_type_name, "1", f"{root_name}.WAV")

    @classmethod
    def __parse_chord_type(cls, chord_type: str) -> str:
        match chord_type:
            case "major":
                return "Major"
            case "major_seventh":
                return "Major_seventh"
            case "minor":
                return "minor"
            case "minor_seventh":
                return "minor_seventh"
            case "seventh":
                return "seventh"
            case _:
                raise NotImplementedError()
