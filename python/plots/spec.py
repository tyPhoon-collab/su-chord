import argparse

import librosa
import librosa.display
import matplotlib.pyplot as plt
import pandas as pd

parser = argparse.ArgumentParser(description="Generate and display a spectrogram from a 2D array data file")
parser.add_argument("data_file", type=str, help="Path to the input data file (CSV format)")
parser.add_argument("sample_rate", type=int, help="Sample rate for the data")
parser.add_argument("win_length", type=int, help="Window size for stft")
parser.add_argument("hop_length", type=int, help="Stride length for stft")
parser.add_argument("--title", type=str, help="Title for the spectrogram")
parser.add_argument("--output", type=str, help="Output file path for the spectrogram image")
parser.add_argument("--y_axis", type=str, help="y_axis type", default="log")
parser.add_argument("--y_min", type=float, help="Minimum value for the Y-axis")
parser.add_argument("--y_max", type=float, help="Maximum value for the Y-axis")
args = parser.parse_args()

data: pd.DataFrame = pd.read_csv(args.data_file, header=None)

librosa.display.specshow(
    data.to_numpy().T,
    x_axis="time",
    y_axis=args.y_axis,
    sr=args.sample_rate,
    win_length=args.win_length,
    hop_length=args.hop_length if args.hop_length != 0 else args.win_length,
    cmap="magma",
)

if args.title:
    plt.title(args.title)

if args.y_axis == "log":
    plt.ylabel("Frequency")

if args.y_min is not None and args.y_max is not None:
    plt.ylim(args.y_min, args.y_max)
elif args.y_min is not None:
    plt.ylim(bottom=args.y_min)
elif args.y_max is not None:
    plt.ylim(top=args.y_max)

if args.output:
    plt.savefig(args.output)
else:
    plt.show()
