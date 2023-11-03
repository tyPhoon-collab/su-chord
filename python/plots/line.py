import argparse

import matplotlib.pyplot as plt
import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument("path", type=str, help="Path to the CSV file")
parser.add_argument("--title", type=str, help="Title for the graph")
parser.add_argument("--output", type=str, help="Output file path")
args = parser.parse_args()

df = pd.read_csv(args.path, header=None)

data = df.to_numpy()

plt.plot(data[0], data[1], marker="o")

if args.title:
    plt.title(args.title)

if args.output:
    plt.savefig(args.output)
else:
    plt.show()
