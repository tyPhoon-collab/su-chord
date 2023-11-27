from dataclasses import dataclass

from path_gettable import (
    ChordAudioSourcePathGettable,
    TanakaMLabChordAudioSourcePathGetter,
)
from process import (
    ChordAudioSegmentPreprocess,
    TanakaMLabChordAudioSegmentPreprocessor,
    TanakaMLabLastOneChordAudioSegmentPreprocessor,
)
from pydub import AudioSegment
from pydub.playback import play
from type import Chord

DEFAULT_INPUT_DIR_PATH = "assets/evals/guitar_dataset"
output_dir_path = "python/outputs"


@dataclass
class ChordAudioSegmentCreator:
    path_getter: ChordAudioSourcePathGettable
    preprocessor: ChordAudioSegmentPreprocess

    def __call__(self, chord: Chord) -> AudioSegment:
        base = AudioSegment.from_file(self.path_getter(chord))
        return self.preprocessor(base)


@dataclass
class ChordProgressionAudioCreator:
    chord_creator: ChordAudioSegmentCreator

    def __call__(self, chords: list[Chord], durations: list[int]) -> AudioSegment:
        """
        durations is list of milliseconds
        """
        assert len(chords) == len(durations)
        return sum([self.chord_creator(chord)[:duration] for chord, duration in zip(chords, durations)])


def __print_detail(sound: AudioSegment) -> None:
    print(sound)
    print(sound.duration_seconds)


if __name__ == "__main__":
    chord_creator = ChordAudioSegmentCreator(
        path_getter=TanakaMLabChordAudioSourcePathGetter(
            dir_path=DEFAULT_INPUT_DIR_PATH,
            source_name="EG_1",
        ),
        preprocessor=TanakaMLabChordAudioSegmentPreprocessor(),
        # preprocessor=TanakaMLabLastOneChordAudioSegmentPreprocessor(),
    )

    # sound = chord_creator(Chord("B", "minor"))

    progression_creator = ChordProgressionAudioCreator(chord_creator=chord_creator)

    sound = progression_creator(
        chords=[
            Chord("A", "minor"),
            Chord("F", "major"),
            Chord("G", "seventh"),
            Chord("C", "major_seventh"),
        ],
        durations=[
            1000,
            1500,
            1000,
            2400,
        ],
    )
    play(sound)
