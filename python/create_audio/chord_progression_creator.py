from dataclasses import dataclass

from pydub import AudioSegment

from path_gettable import (
    ChordAudioSourcePathGettable,
    TanakaMLabChordAudioSourcePathGetter,
)
from process import (  # TanakaMLabLastOneChordAudioSegmentPreprocessor,
    ChordAudioSegmentPreprocess,
    TanakaMLabChordAudioSegmentPreprocessor,
)
from python.create_audio.annotation import create_time_annotation_csv_from_durations
# from pydub.playback import play
from type import Chord

DEFAULT_INPUT_DIR_PATH = "assets/evals/guitar_dataset"


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
        durations are list of milliseconds
        """
        assert len(chords) == len(durations)
        return sum([self.chord_creator(chord)[:duration] for chord, duration in zip(chords, durations)])

    def save(self, chords: list[Chord], durations: list[int], audio_path: str, annotation_path: str) -> None:
        assert audio_path.endswith(".wav") and annotation_path.endswith(".csv")
        sound = self(chords, durations)
        sound.export(audio_path, format="wav")
        create_time_annotation_csv_from_durations(list(map(str, chords)), durations, annotation_path)


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

    progression_creator.save(
        chords=[
            Chord("A", "minor"),
            Chord("F", "major"),
            Chord("G", "seventh"),
            Chord("C", "major_seventh"),
        ],
        durations=[
            1000,
            1600,
            1000,
            2600,
        ],
        audio_path="assets/evals/osawa/Am-F-G-CM7.wav",
        annotation_path="assets/csv/osawa/Am-F-G-CM7.csv",
    )

    # sound = progression_creator(
    #     chords=[
    #         Chord("A", "minor"),
    #         Chord("F", "major"),
    #         Chord("G", "seventh"),
    #         Chord("C", "major_seventh"),
    #     ],
    #     durations=[
    #         1000,
    #         1600,
    #         1000,
    #         2600,
    #     ],
    # )
    # play(sound)
