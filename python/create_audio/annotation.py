import pandas as pd

correct_df = None


def create_time_annotation_csv_from_durations(
    labels: list[str],
    durations: list[float],
    output_path: str,
) -> None:
    slices = []
    seek = 0.0
    for duration in durations:
        slices.append((seek, duration + seek))
        seek += duration

    create_time_annotation_csv_from_slices(labels, slices, output_path)


def create_time_annotation_csv_from_slices(
    labels: list[str],
    slices: list[tuple[float, float]],
    output_path: str,
) -> None:
    assert len(labels) == len(slices)

    df = pd.DataFrame(
        [[labels[i], *slice] for i, slice in enumerate(slices)],
        columns=["label", "start", "end"],
    )
    df.to_csv(output_path, index=False)


def get_chord_labels_from_conv(sound_index: int) -> list[str]:
    global correct_df
    if correct_df is None:
        correct_df = pd.read_csv("assets/csv/correct_only_sharp.csv")

    return list[str](correct_df.iloc[sound_index][1:].to_list())


def map_milliseconds_to_seconds(ranges: list[tuple[int, int]]) -> list[tuple[float, float]]:
    return list(map(lambda range: (range[0] / 1000, range[1] / 1000), ranges))
