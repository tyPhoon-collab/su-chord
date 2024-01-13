from dataclasses import dataclass
from typing import Any

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy.stats import norm


@dataclass
class __Loader:
    hz: float
    path: str
    note_label: str

    def load_data(self) -> tuple[Any, float, str]:
        return pd.read_csv(self.path, header=None).to_numpy(dtype=float)[0], self.hz, self.note_label


def __load_gaussian_data(mu: float, sigma: float, start: float, end: float) -> Any:
    # ガウス分布のx値の範囲
    x = np.linspace(start, end, 1000)

    return x, norm.pdf(x, mu, sigma)


def __annotate_mu(label: str, mu: float) -> None:
    plt.axvline(x=mu, color="black", linestyle="--", lw=3)

    plt.annotate(
        label,
        xy=(mu, 0),
        xytext=(mu + 1, -3),
        arrowprops=dict(facecolor="tab:gray", arrowstyle="->"),
        ha="center",
    )


# 周波数は以下のURLを参照
# https://tomari.org/main/java/oto.html
loader = __Loader(hz=195.998, path="assets/csv/osawa/spectrum_G.csv", note_label="G3")
# loader = __Loader(hz=130.813, path="assets/csv/osawa/spectrum_C.csv", note_label="C3")


data, mu, label = loader.load_data()

sigma = mu / 72
offset = 6 * sigma
delta_freq = 22050 / 8192

x, gaussian = __load_gaussian_data(
    mu,
    sigma,
    start=mu - 3 * sigma,
    end=mu + 3 * sigma,
)

# 棒グラフをプロット
plt.bar(
    [i * delta_freq for i in range(len(data))],
    height=data,
    width=delta_freq * 0.75,
)

# ガウス分布を重ねてプロット
plt.plot(x, gaussian * max(data) * 4, color="tab:red", lw=3)

__annotate_mu(f"{label} ({mu}Hz)", mu)


plt.xlim(mu - offset, mu + offset)

plt.yticks(color="None")

# グラフの表示
plt.show()
