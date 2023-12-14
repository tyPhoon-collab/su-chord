from argparse import Namespace

import matplotlib.pyplot as plt


def set_x_limit(args: Namespace) -> None:
    if args.x_min is not None and args.x_max is not None:
        plt.xlim(args.x_min, args.x_max)
    elif args.x_min is not None:
        plt.xlim(left=args.x_min)
    elif args.x_max is not None:
        plt.xlim(right=args.x_max)


def set_y_limit(args: Namespace) -> None:
    if args.y_min is not None and args.y_max is not None:
        plt.ylim(args.y_min, args.y_max)
    elif args.y_min is not None:
        plt.ylim(bottom=args.y_min)
    elif args.y_max is not None:
        plt.ylim(top=args.y_max)


def output(args: Namespace, as_suptitle: bool = False) -> None:
    title = args.title
    if title:
        if as_suptitle:
            plt.suptitle(title)
        else:
            plt.title(title)

    if args.output:
        plt.savefig(args.output)
    else:
        plt.show()
