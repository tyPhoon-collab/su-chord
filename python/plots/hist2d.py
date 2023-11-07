import argparse

import matplotlib.pyplot as plt
import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument("path", type=str, help="Path to the CSV file")
parser.add_argument("--x_bin", type=float, nargs="+", help="X bin list")
parser.add_argument("--y_bin", type=float, nargs="+", help="y bin list")
parser.add_argument("--title", type=str, help="Title for the plot")
parser.add_argument("--output", type=str, help="Output file path")
args = parser.parse_args()

df = pd.read_csv(args.path)

if len(df.columns) != 3:
    raise ValueError("The CSV file must contain 3 columns: x, y, and c")

x_data = df["x"].to_numpy()
y_data = df["y"].to_numpy()
c_data = df["c"].to_numpy()

plt.hist2d(x_data, y_data, bins=[args.x_bin, args.y_bin], weights=c_data, cmap="magma")

plt.yscale("log")

if args.title:
    plt.title(args.title)

if args.output:
    plt.savefig(args.output)
else:
    plt.show()
