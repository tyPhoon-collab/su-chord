import pandas as pd
from pydub import AudioSegment
from pydub.silence import detect_nonsilent


def __get_sound_name(index: int) -> str:
    return str(index + 1)


def create_time_annotation_csv_from_durations(durations: list[int], output_path: str) -> None:
    slices = []
    seek = 0
    for duration in durations:
        slices.append((seek, duration + seek))
        seek += duration

    create_time_annotation_csv_from_slices(slices, output_path)


def create_time_annotation_csv_from_slices(slices: list[tuple[int, int]], output_path: str) -> None:
    df = pd.DataFrame(
        [[__get_sound_name(i), *slice] for i, slice in enumerate(slices)],
        columns=["count", "start", "end"],
    )
    df.to_csv(output_path, index=False)


if __name__ == "__main__":
    # sound = AudioSegment.from_file("assets/evals/Halion_CleanGuitarVX/1_青春の影.wav")
    # ranges = detect_nonsilent(sound, min_silence_len=100, silence_thresh=-40)

    # print(ranges)

    # assert len(ranges) == 20

    # create_time_annotation_csv(
    #     ranges,
    #     output_path="assets/csv/correct_time_annotation_Halion_CleanGuitarVX.csv",
    # )

    sound = AudioSegment.from_file("assets/evals/HojoGuitar/1_Hojo.wav")
    ranges = detect_nonsilent(sound, min_silence_len=100, silence_thresh=-40)

    print(ranges)

    assert len(ranges) == 20

    create_time_annotation_csv_from_slices(
        ranges,
        output_path="assets/csv/correct_time_annotation_HojoGuitar.csv",
    )
