import argparse

import matplotlib.pyplot as plt
import pandas as pd

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

if args.x_min is not None and args.x_max is not None:
    plt.xlim(args.x_min, args.x_max)
elif args.x_min is not None:
    plt.xlim(left=args.x_min)
elif args.x_max is not None:
    plt.xlim(right=args.x_max)

if args.y_min is not None and args.y_max is not None:
    plt.ylim(args.y_min, args.y_max)
elif args.y_min is not None:
    plt.ylim(bottom=args.y_min)
elif args.y_max is not None:
    plt.ylim(top=args.y_max)


if args.title:
    plt.title(args.title)

if args.output:
    plt.savefig(args.output)
else:
    plt.show()
