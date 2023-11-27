from abc import ABC, abstractmethod

from pydub import AudioSegment
from pydub.silence import split_on_silence


class ChordAudioSegmentPreprocess(ABC):
    @abstractmethod
    def __call__(self, sound: AudioSegment) -> AudioSegment:
        pass


class TanakaMLabChordAudioSegmentPreprocessor(ChordAudioSegmentPreprocess):
    def __call__(self, sound: AudioSegment) -> AudioSegment:
        sound = sound.set_channels(1)

        chunks = split_on_silence(sound, min_silence_len=100, silence_thresh=-35)

        # assert len(chunks) == 1, f"chunks length is {len(chunks)}"

        return sum(chunks)


class TanakaMLabLastOneChordAudioSegmentPreprocessor(ChordAudioSegmentPreprocess):
    def __call__(self, sound: AudioSegment) -> AudioSegment:
        sound = sound.set_channels(1)

        chunks = split_on_silence(sound, min_silence_len=200, silence_thresh=-25, keep_silence=100)

        print(len(chunks))

        return sum(chunks[-1])
