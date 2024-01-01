import pandas as pd

MUSIC_PIECES_LENGTH = 13
SOUND_SOURCE_LENGTH = 4


def get_score(correct: pd.Series, predict: pd.Series) -> float:
    """
    単純に文字列を比較し、正解率を返す
    """
    progression_length = 20
    count = 0

    for i in range(1, progression_length + 1):
        if correct[i] == predict[i]:
            count += 1

    return count / progression_length


def get_scores(df: pd.DataFrame) -> list[float]:
    """
    音源ごとに分けて正解率をリストで返す
    """
    scores = [0.0] * SOUND_SOURCE_LENGTH

    for i in range(MUSIC_PIECES_LENGTH):
        start = i * (SOUND_SOURCE_LENGTH + 1)

        correct = df.iloc[start]

        for j in range(SOUND_SOURCE_LENGTH):
            predict = df.iloc[start + j + 1]
            scores[j] += get_score(correct, predict)

    return list(map(lambda x: x / MUSIC_PIECES_LENGTH, scores))


def get_scores_with_average(df: pd.DataFrame) -> list[float]:
    scores = get_scores(df)
    return [*scores, sum(scores) / SOUND_SOURCE_LENGTH]
