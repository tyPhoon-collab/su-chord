import argparse
from enum import StrEnum

import matplotlib.pyplot as plt
from args import output, set_y_limit

NOTES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


class XLabelType(StrEnum):
    NORMAL = "normal"
    PCP = "pcp"
    PITCH = "pitch"
    NONE = "none"


def __get_x_labels(x_label_type: XLabelType) -> list[str]:
    match x_label_type:
        case XLabelType.NORMAL | XLabelType.NONE:
            return list(map(str, range(len(args.values))))
        case XLabelType.PCP:
            return NOTES
        case XLabelType.PITCH:
            offset = 4  # E2 offset
            return [f"{NOTES[i % 12]}{i // 12 + 2}" for i in range(offset, len(args.values) + offset)]

    raise NotImplementedError("unexpected x label type")


def __set_figure_size(x_label_type: XLabelType) -> None:
    if x_label_type == XLabelType.PITCH:
        plt.figure(figsize=(16, 6))
        plt.subplots_adjust(left=0.05, right=0.95)


def __set_params(x_label_type: XLabelType) -> None:
    if x_label_type == XLabelType.NONE:
        plt.tick_params(labelbottom=False, bottom=False)
    elif x_label_type == XLabelType.PCP:
        plt.xlabel("Pitch Class")
        plt.ylabel("Power")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("values", type=float, nargs="+", help="List of values")
    parser.add_argument("--title", type=str, help="Title for the plot")
    parser.add_argument("--output", type=str, help="Output file path")
    parser.add_argument("--y_min", type=float, help="Minimum value for the Y-axis")
    parser.add_argument("--y_max", type=float, help="Maximum value for the Y-axis")
    parser.add_argument(
        "--x_label_type",
        type=XLabelType,
        choices=XLabelType,
        default=XLabelType.NORMAL,
        help="Specify the label type",
    )
    args = parser.parse_args()

    x_label_type = args.x_label_type

    __set_figure_size(x_label_type)

    plt.bar(__get_x_labels(x_label_type), args.values)

    __set_params(x_label_type)

    set_y_limit(args)

    output(args)
