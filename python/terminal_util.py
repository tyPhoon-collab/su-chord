import shutil


def print_divider() -> None:
    # ターミナルの横幅を取得
    terminal_width, _ = shutil.get_terminal_size()

    # 横線を横幅いっぱいに出力
    print("-" * terminal_width)
