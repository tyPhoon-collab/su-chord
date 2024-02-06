from enum import StrEnum


class WindowFunction(StrEnum):
    HANNING = "hanning"
    HAMMING = "hamming"
    BLACKMAN = "blackman"
    BLACKMAN_HARRIS = "blackmanHarris"
    BARTLETT = "bartlett"


class Scaling(StrEnum):
    NONE = "none"
    LN = "ln"


WINDOW_SIZES = [
    1024,
    2048,
    4096,
    8192,
    16384,
]

# MARKERS = ["o", "s", "^", "v", "<", ">", "x", "+", "*"]
MARKER_STYLES = ["o", "s", "^", "*"]
LINE_STYLES = ["-", "--", "-.", ":"]
CHROMAS = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
