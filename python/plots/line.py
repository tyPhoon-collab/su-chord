import argparse

import matplotlib.pyplot as plt
import pandas as pd

from args import set_x_limit, set_y_limit, output

parser = argparse.ArgumentParser()
parser.add_argument("path", type=str, help="Path to the CSV file")
parser.add_argument("--title", type=str, help="Title for the graph")
parser.add_argument("--output", type=str, help="Output file path")
parser.add_argument("--y_min", type=float, help="Minimum value for the Y-axis")
parser.add_argument("--y_max", type=float, help="Maximum value for the Y-axis")
parser.add_argument("--x_min", type=float, help="Minimum value for the X-axis")
parser.add_argument("--x_max", type=float, help="Maximum value for the X-axis")

args = parser.parse_args()

df = pd.read_csv(args.path, header=None)

data = df.to_numpy()

plt.plot(data[0], data[1], marker=None)

# plt.xscale("log")

set_x_limit(args)

set_y_limit(args)

output(args)
