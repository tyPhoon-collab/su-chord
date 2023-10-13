import argparse

import matplotlib.pyplot as plt
import pandas as pd

# Command-line argument parsing
parser = argparse.ArgumentParser()
parser.add_argument("path", type=str, help="Path to the CSV file")
parser.add_argument("--title", type=str, help="Title for the plot")
parser.add_argument("--output", type=str, help="Output file path")
args = parser.parse_args()

# Read the data from the CSV file using pandas
df = pd.read_csv(args.path)

# Check if the data is valid
if len(df.columns) != 3:
    raise ValueError("The CSV file must contain 3 columns: x, y, and c")

# Get the x and y data
x_data = df["x"].to_numpy()
y_data = df["y"].to_numpy()
c_data = df["c"].to_numpy()

# Create the scatter plot
plt.scatter(x_data, y_data, c=c_data)

# Set the graph title
if args.title:
    plt.title(args.title)


# Save the graph to a file if specified
if args.output:
    plt.savefig(args.output)
else:
    # Show the graph
    plt.show()
