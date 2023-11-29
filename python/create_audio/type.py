from dataclasses import dataclass
from typing import Literal

__Note = Literal["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


@dataclass
class Chord:
    root: __Note
    type: str

    def __str__(self) -> str:
        return self.root + self.__get_type_name()

    def __get_type_name(self) -> str:
        match (self.type):
            case "major":
                return ""
            case "major_seventh":
                return "M7"
            case "minor":
                return "m"
            case "minor_seventh":
                return "m7"
            case "seventh":
                return "7"
            case _:
                raise NotImplementedError()
