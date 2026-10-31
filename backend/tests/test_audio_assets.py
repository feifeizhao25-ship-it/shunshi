"""Guided audio files must be real guided length.

The UI test found audio/en-us/audio_breathe_1.mp3 was 3.0 seconds (18 KB) while every other guided file is
50-87 seconds, and it is also the app's fallback audio. Files are 24 kHz mono mp3 at about 48 kbit/s,
so 30 seconds is roughly 180 KB.
"""

import pathlib

import pytest

AUDIO_DIR = pathlib.Path(__file__).resolve().parents[2] / "audio"
MIN_BYTES = 180_000  # about 30 seconds at 48 kbit/s


def _files():
    return sorted(AUDIO_DIR.glob("*/audio_*.mp3"))


def test_audio_files_exist():
    assert len(_files()) >= 26


@pytest.mark.parametrize("path", _files(), ids=lambda p: f"{p.parent.name}/{p.name}")
def test_guided_audio_is_not_a_stub(path):
    assert path.stat().st_size >= MIN_BYTES, f"{path} is only {path.stat().st_size} bytes (a stub, not guided audio)"


def test_english_breathing_fallback_is_a_real_guide():
    path = AUDIO_DIR / "en-us" / "audio_breathe_1.mp3"
    assert path.stat().st_size >= 400_000  # about 70 seconds
