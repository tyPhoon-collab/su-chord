import glob
import os

import natsort

DIR_PATHS = [
    "assets/evals/Halion_CleanGuitarVX",
    "assets/evals/Halion_CleanStratGuitar",
    "assets/evals/HojoGuitar",
    "assets/evals/RealStrat",
]


def get_file_name(path: str) -> str:
    """
    拡張子を除いたファイル名を取得する関数
    """
    return os.path.splitext(os.path.basename(path))[0]


def get_source_name(path: str) -> str:
    """
    音声ファイルなどは音源名のフォルダ直下に配置されている。音源名を取得する関数
    """
    return path.split("/")[-2]


def get_sorted_audio_paths(dir_path: str) -> list[str]:
    """
    ディレクトリからwavファイルのリストを名前の順でソートして返す関数
    """
    paths = glob.glob(f"{dir_path}/*.wav")
    return natsort.natsorted(paths)


def get_sorted_csv_paths(dir_path: str) -> list[str]:
    """
    ディレクトリからcsvファイルのリストを名前の順でソートして返す関数
    """
    paths = glob.glob(f"{dir_path}/*.csv")
    return natsort.natsorted(paths)
