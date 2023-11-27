from path_gettable import TanakaMLabChordAudioSourcePathGetter
from pydub import AudioSegment
from pydub.playback import play
from pydub.silence import split_on_silence
from type import Chord

from python.create_audio.chord_progression_creator import DEFAULT_INPUT_DIR_PATH

sound = AudioSegment.from_file(
    TanakaMLabChordAudioSourcePathGetter(
        dir_path=DEFAULT_INPUT_DIR_PATH,
        source_name="EG_1",
    )(Chord("B", "minor"))
)
sound = sound.set_channels(1)

chunks = split_on_silence(sound, min_silence_len=100, silence_thresh=-28)
print(chunks)
removed_sound = chunks[-1]
filtered_sound = removed_sound.fade_out(500)

play(filtered_sound)
