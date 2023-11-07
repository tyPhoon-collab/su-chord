import argparse

import matplotlib.pyplot as plt

X_LABELS = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


def __get_x_labels(is_pcp: bool) -> list[str]:
    if is_pcp:
        return X_LABELS
    else:
        return list(map(str, range(len(args.values))))


# Command-line argument parsing
parser = argparse.ArgumentParser()
parser.add_argument("values", type=float, nargs="+", help="List of values")
parser.add_argument("--title", type=str, help="Title for the plot")
parser.add_argument("--output", type=str, help="Output file path")
parser.add_argument("--ymin", type=float, help="Minimum value for the Y-axis")
parser.add_argument("--ymax", type=float, help="Maximum value for the Y-axis")
parser.add_argument("--pcp", action="store_true", help="Use chromatic scale labels")
args = parser.parse_args()

if args.title:
    plt.title(args.title)

plt.bar(__get_x_labels(args.pcp), args.values)

if args.ymin is not None and args.ymax is not None:
    plt.ylim(args.ymin, args.ymax)
elif args.ymin is not None:
    plt.ylim(bottom=args.ymin)
elif args.ymax is not None:
    plt.ylim(top=args.ymax)

if args.output:
    plt.savefig(args.output)
else:
    plt.show()
