import os
import sys
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any, Callable

import numpy as np
import pandas as pd

sys.path.append(".")

from python.analyzer.analyze import get_scores_with_average  # noqa
from python.path_util import get_sorted_csv_paths  # noqa
from python.terminal_util import print_divider  # noqa

WINDOW_LENGTHS = [
    1024,
    2048,
    4096,
    8192,
    16384,
]


class FixedSize2DArray:
    def __init__(self, rows: int, cols: int, initial_value: Any = 0.0) -> None:
        self.array = np.full((rows, cols), initial_value)
        self.rows = rows
        self.cols = cols

    def __getitem__(self, index: tuple[int, int]) -> Any:
        row, col = index
        return self.array[row][col]

    def __setitem__(self, index: tuple[int, int], value: Any) -> None:
        row, col = index
        self.array[row][col] = value

    def to_latex(
        self,
        index: list[Any] | None = None,
        columns: list[Any] | None = None,
        float_format: Callable[[float], str] | None = None,
    ) -> str:
        return str(pd.DataFrame(self.array, index=index, columns=columns).to_latex(float_format=float_format))


Tables = dict[str, FixedSize2DArray]


class LaTeXFormattable(ABC):
    """Tables to string and print it"""

    @abstractmethod
    def __call__(self) -> None:
        ...

    @classmethod
    def print(cls, key: str, fig: str) -> None:
        print(key)
        print_divider()
        print(fig)
        print_divider()


@dataclass
class SimpleLaTeXFormatter(LaTeXFormattable):
    tables: Tables

    def __call__(self) -> None:
        for key, table in tables.items():
            fig = table.to_latex(
                index=[
                    "コムフィルタ",
                    "コムフィルタ+対数",
                    "平均律ビン",
                    "平均律ビン+対数",
                    "コムフィルタ*",
                    "コムフィルタ+対数*",
                    "平均律ビン*",
                    "平均律ビン+対数*",
                ],
                columns=WINDOW_LENGTHS,
            )

            self.print(key, fig)


@dataclass
class BoldLaTeXFormatter(LaTeXFormattable):
    tables: Tables

    def __call__(self) -> None:
        for key, table in tables.items():
            fig = table.to_latex(
                index=[
                    "コムフィルタ",
                    "コムフィルタ+対数",
                    "平均律ビン",
                    "平均律ビン+対数",
                    "コムフィルタ*",
                    "コムフィルタ+対数*",
                    "平均律ビン*",
                    "平均律ビン+対数*",
                ],
                columns=WINDOW_LENGTHS,
                float_format=self.__fmt,
            )

            max_indices = np.argmax(table.array, axis=0)
            for i, max_index in enumerate(max_indices):
                value = self.__fmt(table[max_index, i])
                fig = fig.replace(value, "\\textbf{" + value + "}")

            self.print(key, fig)

    @staticmethod
    def __fmt(x: float) -> str:
        return f"{x*100:.3f}"


def __get_experiment_dir_path(window_length: int) -> str:
    base_path = "test/outputs/cross_validations/ICS/chunkSize_{}__chunkStride_0__sampleRate_22050__window_hanning"
    return base_path.format(window_length)


def __get_figure_key(basename: str) -> str:
    if "search_tree" in basename:
        return "search tree"

    if "mean_matching_cosine_similarity_none_template_scaled" in basename:
        return "matching"

    if "mean_matching_cosine_similarity_harmonic_0.6-4_template_scaled" in basename:
        return "matching 4"

    if "mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled" in basename:
        return "matching 6"

    raise NotImplementedError()


def __get_index(basename: str) -> int:
    if "normal_distribution_comb_filter__stft_mags_none_scaled" in basename:
        return 0
    if "normal_distribution_comb_filter__stft_mags_ln_scaled" in basename:
        return 1
    if "et-scale_sparse_non_reassign_frequency_none_scaled" in basename:
        return 2
    if "et-scale_sparse_non_reassign_frequency_ln_scaled" in basename:
        return 3
    if "normal_distribution_comb_filter__sparse_mags_none_scaled" in basename:
        return 4
    if "normal_distribution_comb_filter__sparse_mags_ln_scaled" in basename:
        return 5
    if "et-scale_sparse_none_scaled" in basename:
        return 6
    if "et-scale_sparse_ln_scaled" in basename:
        return 7

    raise NotImplementedError()


tables: Tables = {}

for window_index, window_length in enumerate(WINDOW_LENGTHS):
    dir_path = __get_experiment_dir_path(window_length)

    for path in get_sorted_csv_paths(dir_path):
        df = pd.read_csv(path, dtype=str, skiprows=1, header=None)

        basename = os.path.basename(path)
        score = get_scores_with_average(df)[-1]

        figure_key = __get_figure_key(basename)
        row_index = __get_index(basename)

        array = tables.setdefault(figure_key, FixedSize2DArray(8, 5))
        array[row_index, window_index] = score


formatter = BoldLaTeXFormatter(tables)
formatter()
