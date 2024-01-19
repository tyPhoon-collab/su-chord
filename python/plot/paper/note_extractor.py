import sys

from matplotlib import pyplot as plt

sys.path.append(".")

# import python.plot.ncsp_rcParams  # noqa

X_LABELS = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
RED_COLOR_X_LABELS = ["C", "E", "G"]
PCP_DATA_PATH = "assets/csv/osawa/pcp_C.csv"

with open(PCP_DATA_PATH, "r") as file:
    data = [float(value) for value in file.read().split(",")]

# plt.bar(X_LABELS, data)
plt.bar(X_LABELS, data, color=["tab:red" if note in RED_COLOR_X_LABELS else "tab:blue" for note in X_LABELS])


plt.xlabel("Pitch Class")
plt.ylabel("Power")


plt.ylim(0, 1)

# plt.axhline(data[0] * 0.65, color="tab:green", linestyle="--")

plt.show()
