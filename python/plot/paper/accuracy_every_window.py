import os
import sys
from enum import StrEnum

import japanize_matplotlib  # noqa
import matplotlib
import numpy as np
import pandas as pd
from matplotlib import pyplot as plt

sys.path.append(".")

from python.analyzer.analyze import get_scores_with_average  # noqa
from python.path_util import get_sorted_csv_paths  # noqa

WINDOW_SIZES = [
    1024,
    2048,
    4096,
    8192,
    16384,
]


class WindowFunction(StrEnum):
    HANNING = ("hanning",)
    HAMMING = ("hamming",)
    BLACKMAN = ("blackman",)
    BLACKMAN_HARRIS = ("blackmanHarris",)
    BARTLETT = ("bartlett",)


DIRECTORY_PATH = (
    "test/outputs/cross_validations/window_function/chunkSize_{}__chunkStride_0__sampleRate_22050__window_{}"  # noqa
)

# MARKERS = ["o", "s", "^", "v", "<", ">", "x", "+", "*"]
MARKERS = ["o", "s", "^", "*"]
LINESTYLES = ["-", "--", "-.", ":"]

# LABELS = ["Comb", "ET-scale", "Comb*", "ET-scale*"]
LABELS = ["コムフィルタ", "平均律ビン", "コムフィルタ*", "平均律ビン*"]


def __get_index(basename: str) -> int:
    scale = "none"
    # scale = "ln"
    if f"normal_distribution_comb_filter__stft_mags_{scale}_scaled" in basename:
        return 0
    if f"et-scale_sparse_non_reassign_frequency_{scale}_scaled" in basename:
        return 1
    if f"normal_distribution_comb_filter__sparse_mags_{scale}_scaled" in basename:
        return 2
    if f"et-scale_sparse_{scale}_scaled" in basename:
        return 3

    return -1


scores_list = np.zeros((4, len(WINDOW_SIZES)))

max_score = 0.0
max_window = 0.0

for i, size in enumerate(WINDOW_SIZES):
    dir_path = DIRECTORY_PATH.format(size, WindowFunction.BLACKMAN)
    paths = get_sorted_csv_paths(dir_path)
    if len(paths) == 0:
        print(f"There is no files window size of {size}. Please check directory path: {dir_path}")
    for path in paths:
        index = __get_index(os.path.basename(path))
        if index == -1:
            continue

        df = pd.read_csv(path, skiprows=1, header=None)
        score = get_scores_with_average(df)[-1] * 100

        if max_score < score:
            max_score = score
            max_window = size

        scores_list[index, i] = score

print(scores_list)
for i, scores in enumerate(scores_list):
    plt.plot(
        WINDOW_SIZES,
        scores,
        marker=MARKERS[i],
        linestyle=LINESTYLES[i],
        label=LABELS[i],
    )

plt.xscale("log")
plt.xticks(WINDOW_SIZES)
plt.ylim(0, 100)
plt.xlabel("Window Size")
plt.ylabel("Accuracy Rate[%]")

xaxis = plt.gca().get_xaxis()

xaxis.set_major_formatter(matplotlib.ticker.ScalarFormatter())
xaxis.set_tick_params(which="minor", size=0)
xaxis.set_tick_params(which="minor", width=0)

plt.annotate(
    f"Max: {max_score:.3f}",
    (max_window, max_score),
    textcoords="offset points",
    xytext=(0, 30),
    ha="center",
    arrowprops=dict(color="gray", arrowstyle="-|>"),
)

plt.legend()

plt.show()
