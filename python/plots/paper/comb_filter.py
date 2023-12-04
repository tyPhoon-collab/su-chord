from typing import Any

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy.stats import norm


def __load_data() -> Any:
    data = pd.read_csv("assets/csv/osawa/spectrum_G.csv", header=None)
    return data.to_numpy(dtype=float)[0]


def __load_gaussian_data(mu: float, sigma: float, start: float, end: float) -> Any:
    # ガウス分布のx値の範囲
    x = np.linspace(start, end, 1000)

    return x, norm.pdf(x, mu, sigma)


def __annotate_mu(label: str, mu: float) -> None:
    plt.axvline(x=mu, color="red", linestyle="--")

    plt.annotate(
        label,
        xy=(mu, 0),
        xytext=(mu + 2, -5),
        arrowprops=dict(facecolor="black", arrowstyle="->"),
        ha="center",
    )


data = __load_data()

mu = 195.998
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
plt.plot(x, gaussian * max(data) * 4, color="black")

__annotate_mu(f"G3 ({mu}Hz)", mu)


plt.xlim(mu - offset, mu + offset)

plt.yticks(color="None")

# グラフの表示
plt.show()
