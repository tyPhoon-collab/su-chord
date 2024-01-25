import pandas as pd
from matplotlib import pyplot as plt

Y_TICKS = [
    179.80566353615984,
    190.4974646733462,
    201.82503339042393,
    213.8261743949866,
    226.5409403795228,
    240.01176569355388,
    254.28360796433077,
    269.40409813873583,
    285.42369944714034,
    302.3958758197448,
    320.377270317476,
    339.4278941729375,
]

df = pd.read_csv("assets/csv/osawa/reassignment_G.csv")

if len(df.columns) != 3:
    raise ValueError("The CSV file must contain 3 columns: x, y, and c")

x_data = df["x"].to_numpy()
y_data = df["y"].to_numpy()
c_data = df["c"].to_numpy()


plt.hist2d(
    x_data,
    y_data,
    bins=(
        [4096 / 22050 * i for i in range(23)],
        Y_TICKS,
    ),
    weights=c_data,
    cmap="magma",
)

# plt.yscale("log")

plt.ylim(Y_TICKS[0], Y_TICKS[-1])

plt.gca().set_yticks(Y_TICKS)

plt.xlabel("Time[s]")
plt.ylabel("Frequency[Hz]")

# グラフの表示
plt.show()
