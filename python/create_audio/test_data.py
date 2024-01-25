import numpy as np
from scipy.io.wavfile import write


def generate_tone(frequency: float, duration: float, sample_rate: int = 44100, amplitude: float = 0.5) -> np.ndarray:
    t = np.linspace(0, duration, int(sample_rate * duration), endpoint=False)
    return amplitude * np.sin(2 * np.pi * frequency * t)  # type: ignore


def save_wav(file_path: str, wave: np.ndarray, sample_rate: int = 44100) -> None:
    scaled_wave = np.int16(wave * 32767)
    write(file_path, sample_rate, scaled_wave)


if __name__ == "__main__":
    # 周波数と再生時間を設定
    target_frequency = 440.0  # 例: 440 Hz (A4音)
    duration = 5.0  # 例: 5秒

    # 音源を生成
    generated_wave = generate_tone(target_frequency, duration)

    # 音源を保存
    save_wav("assets/evals/test_audio/tone.wav", generated_wave)
