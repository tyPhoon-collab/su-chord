import argparse
import matplotlib.pyplot as plt

# コマンドライン引数のパース
parser = argparse.ArgumentParser()
parser.add_argument("values", type=float, nargs="+", help="List of values")
parser.add_argument("--title", type=str, help="Title for the plot")
parser.add_argument("--output", type=str, help="Output file path")
parser.add_argument("--ymin", type=float, help="Minimum value for the Y-axis")
parser.add_argument("--ymax", type=float, help="Maximum value for the Y-axis")
args = parser.parse_args()

# 棒グラフの作成
values = args.values

# グラフのタイトルを設定
if args.title:
    plt.title(args.title)

# 棒グラフを作成
plt.bar(list(map(str, range(len(values)))), values)

# Y軸の範囲を指定
if args.ymin is not None and args.ymax is not None:
    plt.ylim(args.ymin, args.ymax)
elif args.ymin is not None:
    plt.ylim(bottom=args.ymin)
elif args.ymax is not None:
    plt.ylim(top=args.ymax)

# グラフをファイルに保存する場合
if args.output:
    plt.savefig(args.output)
else:
    # グラフを表示
    plt.show()
