import numpy as np
from scipy.io.wavfile import write


def generate_chirp_wave(
    start_freq: float, end_freq: float, duration: float, sample_rate: int = 44100, amplitude: float = 0.5
) -> np.ndarray:
    t = np.linspace(0, duration, int(sample_rate * duration), endpoint=False)
    freqs = np.linspace(start_freq, end_freq, len(t))
    return amplitude * np.sin(2 * np.pi * np.cumsum(freqs) / sample_rate)  # type: ignore


def save_wav(file_path: str, wave: np.ndarray, sample_rate: int = 44100) -> None:
    scaled_wave = np.int16(wave * 32767)
    write(file_path, sample_rate, scaled_wave)


if __name__ == "__main__":
    # チャープ波のパラメータ
    start_frequency = 100.0  # 開始周波数 (Hz)
    end_frequency = 1000.0  # 終了周波数 (Hz)
    duration = 5.0  # 波形の時間長さ (秒)

    # チャープ波を生成
    chirp_wave = generate_chirp_wave(start_frequency, end_frequency, duration)

    # wavファイルに保存
    save_wav("assets/evals/test_audio/chirp.wav", chirp_wave)
