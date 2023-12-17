import argparse

import pandas as pd

GENRES = ["BN", "Funk", "Jazz", "Rock", "SS"]


def __drop_name_column(df: pd.DataFrame) -> pd.DataFrame:
    return df.drop("name", axis=1)


def __calculate_mean_by_genre(path: str) -> pd.DataFrame:
    df = pd.read_csv(path)

    objs = [__drop_name_column(df.query("name.str.contains(@genre)")).mean() for genre in GENRES]
    concat_df = pd.concat(objs + [__drop_name_column(df).mean()], axis=1)
    concat_df.columns = GENRES + ["Average"]

    return concat_df.T.round(3)


def main() -> None:
    parser = argparse.ArgumentParser(description="Convert F-score CSV to PowerPoint or LaTeX output")
    parser.add_argument(
        "path",
        type=str,
        help="Path to the CSV file",
    )
    parser.add_argument(
        "choice",
        type=str,
        choices=["csv", "cb", "ltx"],
        help="Choose csv, cb(clipboard), or ltx(LaTeX)",
    )

    args = parser.parse_args()

    df = __calculate_mean_by_genre(args.path)

    if args.choice == "csv":
        print(df.to_csv())
    elif args.choice == "cb":
        df.to_clipboard(excel=True)
        print("Data copied to clipboard.")
    elif args.choice == "ltx":
        print(df.to_latex())
    else:
        raise NotImplementedError("Not implemented")


if __name__ == "__main__":
    main()
