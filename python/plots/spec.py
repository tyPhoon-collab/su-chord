import argparse
import librosa
import librosa.display
import matplotlib.pyplot as plt
import pandas as pd

# コマンドライン引数のパース
parser = argparse.ArgumentParser(description="Generate and display a spectrogram from a 2D array data file")
parser.add_argument("data_file", type=str, help="Path to the input data file (CSV format)")
parser.add_argument("sample_rate", type=int, help="Sample rate for the data")
parser.add_argument("--title", type=str, help="Title for the spectrogram")
parser.add_argument("--output", type=str, help="Output file path for the spectrogram image")
parser.add_argument("--y_axis", type=str, help="y_axis type", default="log")
args = parser.parse_args()

# CSVファイルからデータを読み込み
data: pd.DataFrame = pd.read_csv(args.data_file, header=None)

# スペクトログラムを表示
plt.figure(figsize=(10, 4))
librosa.display.specshow(
    data.to_numpy().T,
    x_axis="time",
    y_axis=args.y_axis,
    sr=args.sample_rate,
)
# plt.colorbar(format="%+2.0f dB")
if args.title:
    plt.title(args.title)

# スペクトログラムをファイルに保存する場合
if args.output:
    plt.savefig(args.output)
else:
    # スペクトログラムを表示
    plt.show()
