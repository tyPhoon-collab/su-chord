import argparse
import hashlib

import matplotlib.pyplot as plt
import pandas as pd
from matplotlib.collections import BrokenBarHCollection
from matplotlib.colors import Colormap

BAR_HEIGHT = 4


def __str_to_color(str: str, cmap: Colormap | None = None) -> tuple[float, float, float, float]:
    hashed = hashlib.sha256(str.encode()).hexdigest()
    cm = cmap or plt.get_cmap("coolwarm")

    level = int(hashed, 16) % 256  # 0から255の範囲の数値を0から1の範囲に変換

    return cm(level)


def __plt_bar(df: pd.DataFrame, y_range: tuple[int, int]) -> BrokenBarHCollection:
    if len(df.columns) != 3:
        raise ValueError("The CSV file must contain 3 columns: label, start, end")

    label_data = df["label"].to_numpy()
    start_data = df["start"].to_numpy()
    end_data = df["end"].to_numpy()

    x_ranges = [(start, end - start) for start, end in zip(start_data, end_data)]

    collection = plt.broken_barh(
        x_ranges,
        y_range,
        facecolor=[__str_to_color(label) for label in label_data],
    )

    for i, (start, width) in enumerate(x_ranges):
        x = start + width / 2
        y = y_range[0] + y_range[1] / 2
        plt.text(x, y, label_data[i], ha="center", va="center")

    return collection


parser = argparse.ArgumentParser()
parser.add_argument("correct_path", type=str, help="Path to the CSV file")
parser.add_argument("predict_path", type=str, help="Path to the CSV file")
parser.add_argument("--title", type=str, help="Title for the plot")
parser.add_argument("--output", type=str, help="Output file path")
args = parser.parse_args()

plt.figure(figsize=(16, 4))

correct_df = pd.read_csv(args.correct_path)
predict_df = pd.read_csv(args.predict_path)

__plt_bar(correct_df, (6, BAR_HEIGHT))
__plt_bar(predict_df, (0, BAR_HEIGHT))

plt.yticks(
    [0 + BAR_HEIGHT / 2, 6 + BAR_HEIGHT / 2],
    labels=["predict", "correct"],
)

if args.title:
    plt.title(args.title)

plt.subplots_adjust(left=0.05, right=0.95)

if args.output:
    plt.savefig(args.output)
else:
    plt.show()
