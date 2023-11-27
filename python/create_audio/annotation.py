import pandas as pd
from pydub import AudioSegment
from pydub.silence import detect_nonsilent


def create_time_annotation_csv(durations: list[tuple[int, int]], output_path: str) -> None:
    df = pd.DataFrame(
        [[i + 1, *duration] for i, duration in enumerate(durations)],
        columns=["count", "start", "end"],
    )
    df.to_csv(output_path, index=False, encoding="utf-8")


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

    create_time_annotation_csv(
        ranges,
        output_path="assets/csv/correct_time_annotation_HojoGuitar.csv",
    )
