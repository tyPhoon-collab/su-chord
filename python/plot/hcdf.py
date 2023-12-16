import argparse
import hashlib

import librosa
import matplotlib.pyplot as plt
import pandas as pd
from args import output
from matplotlib.axes import Axes
from matplotlib.collections import BrokenBarHCollection
from matplotlib.colors import Colormap

__BAR_HEIGHT = 3
__FIG_SIZE = (16, 8)
__FIG_HALF_SIZE = (16, 4)
__BAR_INTERVAL = __BAR_HEIGHT + 2


def __str_to_color(string: str, cmap: Colormap | None = None) -> tuple[float, float, float, float]:
    hashed = hashlib.sha256(string.encode()).hexdigest()
    cm = cmap or plt.get_cmap("coolwarm")

    level = int(hashed, 16) % 256  # 0から255の範囲の数値を0から1の範囲に変換

    return cm(level)


def __plt_chromagram(chromas_path: str, sample_rate: int, win_length: int, hop_length: int, ax: Axes) -> None:
    data = pd.read_csv(chromas_path, header=None)

    librosa.display.specshow(
        data.to_numpy().T,
        x_axis="time",
        y_axis="chroma",
        sr=sample_rate,
        win_length=win_length,
        hop_length=hop_length if args.hop_length != 0 else args.win_length,
        cmap="magma",
        ax=ax,
    )


def __plt_bar(df: pd.DataFrame, y_range: tuple[int, int], ax: Axes | None = None) -> BrokenBarHCollection:
    if len(df.columns) != 3:
        raise ValueError("The CSV file must contain 3 columns: label, start, end")

    label_data = df["label"].to_numpy()
    start_data = df["start"].to_numpy()
    end_data = df["end"].to_numpy()

    x_ranges = [(start, end - start) for start, end in zip(start_data, end_data)]

    ax = ax or plt.gca()

    collection = ax.broken_barh(
        x_ranges,
        y_range,
        facecolor=[__str_to_color(label) for label in label_data],
    )

    for i, (start, width) in enumerate(x_ranges):
        x = start + width / 2
        y = y_range[0] + y_range[1] / 2
        plt.text(x, y, label_data[i], ha="center", va="center")

    return collection


def __plt_bars(correct_df: pd.DataFrame, predict_df: pd.DataFrame, ax: Axes | None = None) -> None:
    __plt_bar(correct_df, (__BAR_INTERVAL, __BAR_HEIGHT), ax=ax)
    __plt_bar(predict_df, (0, __BAR_HEIGHT), ax=ax)

    plt.yticks(
        [0 + __BAR_HEIGHT / 2, __BAR_INTERVAL + __BAR_HEIGHT / 2],
        labels=["predict", "correct"],
    )


parser = argparse.ArgumentParser()
parser.add_argument("correct_path", type=str, help="Path to the CSV file")
parser.add_argument("predict_path", type=str, help="Path to the CSV file")
parser.add_argument("--chromas_path", type=str, help="Path to the input data file (CSV format)")
parser.add_argument("--sample_rate", type=int, help="Sample rate for the data")
parser.add_argument("--win_length", type=int, help="Window size for stft")
parser.add_argument("--hop_length", type=int, help="Stride length for stft")
parser.add_argument("--title", type=str, help="Title for the plot")
parser.add_argument("--output", type=str, help="Output file path")
args = parser.parse_args()


correct_df = pd.read_csv(args.correct_path)
predict_df = pd.read_csv(args.predict_path)

as_suptitle = False

if args.chromas_path:
    if args.sample_rate is None or args.win_length is None or args.hop_length is None:
        raise ValueError("If set chromas path, you need sample rate, win length and hop length")

    plt.figure(figsize=__FIG_SIZE)

    ax_top = plt.subplot(2, 1, 1)
    ax_bottom = plt.subplot(2, 1, 2)

    __plt_chromagram(
        args.chromas_path,
        args.sample_rate,
        args.win_length,
        args.hop_length,
        ax=ax_top,
    )

    __plt_bars(correct_df, predict_df, ax_bottom)

    ax_bottom.sharex(ax_top)

    as_suptitle = True

else:
    plt.figure(figsize=__FIG_HALF_SIZE)

    __plt_bars(correct_df, predict_df)

plt.subplots_adjust(left=0.05, right=0.95)

output(args, as_suptitle)
