import os
import sys

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

DIRECTORY_PATH = "test/outputs/cross_validations/NCSP_paper/window_sizes/chunkSize_{}__chunkStride_0__sampleRate_22050"

# MARKERS = ["o", "s", "^", "v", "<", ">", "x", "+", "*"]
MARKERS = ["o", "s", "^", "*"]
LINESTYLES = ["-", "--", "-.", ":"]

LABELS = ["Comb", "ET-scale", "Comb*", "ET-scale*"]


def __get_index(basename: str) -> int:
    if "normal_distribution_comb_filter__stft_mags_ln_scaled" in basename:
        return 0
    if "sparse_non_reassign_frequency_ln_scaled" in basename:
        return 1
    if "normal_distribution_comb_filter__sparse_mags_ln_scaled" in basename:
        return 2
    if "sparse_ln_scaled" in basename:
        return 3

    raise NotImplementedError()


scores = np.zeros((4, len(WINDOW_SIZES)))

for i, window in enumerate(WINDOW_SIZES):
    for path in get_sorted_csv_paths(DIRECTORY_PATH.format(window)):
        df = pd.read_csv(path, skiprows=1, header=None)
        score = get_scores_with_average(df)[-1]

        scores[__get_index(os.path.basename(path)), i] = score

print(scores)
for i, score in enumerate(scores):
    plt.plot(
        WINDOW_SIZES,
        score,
        marker=MARKERS[i],
        linestyle=LINESTYLES[i],
        label=LABELS[i],
    )

plt.xscale("log")
plt.xticks(WINDOW_SIZES)
plt.ylim(0, 1)
plt.xlabel("Window Size")
plt.ylabel("Accuracy")

xaxis = plt.gca().get_xaxis()

xaxis.set_major_formatter(matplotlib.ticker.ScalarFormatter())
xaxis.set_tick_params(which="minor", size=0)
xaxis.set_tick_params(which="minor", width=0)

plt.legend()

plt.show()
