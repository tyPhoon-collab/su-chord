from dataclasses import dataclass


@dataclass
class Chord:
    root: str
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
