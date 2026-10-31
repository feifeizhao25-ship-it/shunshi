#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""顺时国内版冥想音频生成工具（离线运行，不在服务端请求路径里）。

输入：backend/app/data/meditation_cn/tracks.json 里的原创脚本（text，含停顿标记 <#秒#>）。
人声：MiniMax 开放平台（国内）语音合成 t2a_v2，系统音色，密钥只从环境变量读取
      （MINIMAX_API_KEY 或 MINIMAX_CN_API_KEY），脚本不打印、不保存密钥。
配乐：本脚本用 numpy 现场合成（正弦/泛音叠加 + 混响 + 噪声），没有使用任何第三方音乐、采样或素材。
输出：backend/app/static/audio/meditation/<id>.mp3（单声道、32kHz、约 40kbps），并回写 tracks.json 的
      duration_seconds / size_bytes / sha256 / voice 信息。

用法：python3 backend/scripts/build_meditation_audio.py [--only med_cn_breath_01] [--music-only]
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
from pathlib import Path

import numpy as np
from scipy import signal
from scipy.io import wavfile

ROOT = Path(__file__).resolve().parents[1]
TRACKS_JSON = ROOT / "app" / "data" / "meditation_cn" / "tracks.json"
OUT_DIR = ROOT / "app" / "static" / "audio" / "meditation"
SR = 32000
TTS_URL = "https://api.minimaxi.com/v1/t2a_v2"
TTS_MODEL = "speech-2.6-hd"
VOICE_ID = "Chinese (Mandarin)_Gentle_Senior"  # 温柔学姐（系统音色）
VOICE_SPEED = 0.82


# ---------- 配乐合成 ----------
def _hz(note: str) -> float:
    names = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
    n = names[note[0]]
    octave = int(note[-1])
    return 440.0 * 2 ** ((n - 9 + 12 * (octave - 4)) / 12)


def _reverb(x: np.ndarray, seconds: float = 2.8, wet: float = 0.45, seed: int = 7) -> np.ndarray:
    rng = np.random.default_rng(seed)
    n = int(SR * seconds)
    ir = rng.standard_normal(n) * np.exp(-np.linspace(0, 6.5, n))
    ir[0] = 0
    ir = signal.sosfilt(signal.butter(2, 3500, "low", fs=SR, output="sos"), ir)
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
    wet_sig = signal.fftconvolve(x, ir)[: len(x)]
    return (1 - wet) * x + wet * wet_sig


def _pad(duration: float, chords: list[list[str]], seed: int, change: float = 18.0, level: float = 1.0) -> np.ndarray:
    rng = np.random.default_rng(seed)
    t = np.arange(int(duration * SR)) / SR
    out = np.zeros_like(t)
    n_seg = int(np.ceil(duration / change)) + 1
    for si in range(n_seg):
        chord = chords[si % len(chords)]
        env = np.clip(1 - np.abs((t - si * change - change / 2) / (change * 0.75)), 0, 1) ** 1.5
        for note in chord:
            f = _hz(note)
            ph = rng.uniform(0, 6.28)
            lfo = 0.75 + 0.25 * np.sin(2 * np.pi * rng.uniform(0.04, 0.11) * t + rng.uniform(0, 6.28))
            tone = (np.sin(2 * np.pi * f * t + ph) + 0.35 * np.sin(2 * np.pi * (f * 1.003) * t + ph * 0.7)
                    + 0.12 * np.sin(2 * np.pi * 2 * f * t + ph))
            out += env * lfo * tone
    out = signal.sosfilt(signal.butter(2, 1800, "low", fs=SR, output="sos"), out)
    return level * out / (np.max(np.abs(out)) + 1e-9)


def _bells(duration: float, scale: list[str], seed: int, every=(4.0, 8.0), level: float = 1.0, decay: float = 3.5) -> np.ndarray:
    rng = np.random.default_rng(seed)
    out = np.zeros(int(duration * SR))
    pos = rng.uniform(1.5, 3.0)
    while pos < duration - 2:
        f = _hz(rng.choice(scale))
        length = int(SR * (decay + 2))
        tt = np.arange(length) / SR
        env = np.exp(-tt / (decay / 3)) * (1 - np.exp(-tt * 60))
        tone = np.sin(2 * np.pi * f * tt) + 0.25 * np.sin(2 * np.pi * 2.01 * f * tt) + 0.08 * np.sin(2 * np.pi * 3.97 * f * tt)
        i = int(pos * SR)
        seg = (env * tone)[: max(0, len(out) - i)]
        out[i: i + len(seg)] += seg * rng.uniform(0.5, 1.0)
        pos += rng.uniform(*every)
    return level * out / (np.max(np.abs(out)) + 1e-9)


def _soft_noise(duration: float, seed: int, cutoff: float = 900, level: float = 1.0) -> np.ndarray:
    rng = np.random.default_rng(seed)
    n = int(duration * SR)
    x = signal.sosfilt(signal.butter(2, cutoff, "low", fs=SR, output="sos"), rng.standard_normal(n))
    x *= 0.7 + 0.3 * np.sin(2 * np.pi * 0.07 * np.arange(n) / SR + rng.uniform(0, 6.28))
    return level * x / (np.max(np.abs(x)) + 1e-9)


PENTA = {  # 宫商角徵羽（C D E G A）
    "bright": ["C5", "D5", "E5", "G5", "A5", "C6"],
    "mid": ["C4", "D4", "E4", "G4", "A4", "C5"],
    "low": ["C3", "D3", "E3", "G3", "A3", "C4"],
}
CHORDS = {
    "calm": [["C3", "G3", "E4", "B4"], ["A2", "E3", "C4", "G4"], ["F2", "C3", "A3", "E4"], ["G2", "D3", "B3", "G4"]],
    "deep": [["C2", "G2", "E3", "G3"], ["A1", "E2", "C3", "E3"], ["F2", "C3", "F3", "A3"], ["G2", "D3", "G3", "B3"]],
    "warm": [["F2", "C3", "A3", "E4"], ["C3", "G3", "E4", "G4"], ["D3", "A3", "F4", "A4"], ["G2", "D3", "B3", "D4"]],
}


def make_music(track: dict, duration: float) -> np.ndarray:
    cat, term = track["category"], track.get("term")
    seed = int(hashlib.sha256(track["id"].encode()).hexdigest()[:8], 16)
    if cat == "sleep":
        x = 1.0 * _pad(duration, CHORDS["deep"], seed, 22) + 0.35 * _soft_noise(duration, seed + 1, 700)
    elif cat == "solar_term":
        if term == "立春":
            x = 0.8 * _pad(duration, CHORDS["calm"], seed) + 0.7 * _bells(duration, PENTA["bright"], seed + 2, (3.5, 6.5))
        elif term == "夏至":
            x = 0.7 * _pad(duration, CHORDS["warm"], seed) + 0.5 * _bells(duration, PENTA["mid"], seed + 2, (5, 9)) + 0.25 * _soft_noise(duration, seed + 3, 2400)
        elif term == "霜降":
            x = 0.9 * _pad(duration, CHORDS["warm"], seed, 20) + 0.55 * _bells(duration, PENTA["mid"], seed + 2, (6, 11), decay=4.5)
        else:  # 冬至
            x = 1.0 * _pad(duration, CHORDS["deep"], seed, 24) + 0.5 * _bells(duration, PENTA["low"], seed + 2, (8, 14), decay=5.5)
    elif cat == "quick":
        x = 0.9 * _pad(duration, CHORDS["calm"], seed, 14) + 0.3 * _bells(duration, PENTA["bright"], seed + 2, (6, 10))
    else:  # breathing
        x = 1.0 * _pad(duration, CHORDS["calm"], seed, 16)
    x = _reverb(x, seed=seed)
    x = x / (np.max(np.abs(x)) + 1e-9)
    n_fade = int(SR * 3)
    x[:n_fade] *= np.linspace(0, 1, n_fade)
    x[-n_fade:] *= np.linspace(1, 0, n_fade)
    return x.astype(np.float32)


# ---------- 人声 ----------
def tts(text: str, key: str) -> bytes:
    body = {
        "model": TTS_MODEL, "text": text, "stream": False,
        "voice_setting": {"voice_id": VOICE_ID, "speed": VOICE_SPEED, "vol": 1.0, "pitch": 0},
        "audio_setting": {"sample_rate": SR, "bitrate": 128000, "format": "mp3", "channel": 1},
    }
    req = urllib.request.Request(TTS_URL, data=json.dumps(body).encode(), headers={
        "Content-Type": "application/json", "Authorization": "Bearer " + key})
    try:
        resp = json.load(urllib.request.urlopen(req, timeout=180))
    except urllib.error.HTTPError as e:  # 不回显请求头，避免泄露密钥
        raise SystemExit(f"语音合成请求失败：HTTP {e.code}") from None
    base = resp.get("base_resp", {})
    if base.get("status_code") != 0:
        raise SystemExit(f"语音合成失败：{base.get('status_code')} {base.get('status_msg')}")
    return bytes.fromhex(resp["data"]["audio"])


def build(track: dict, key: str | None, music_only: bool) -> dict:
    text = "".join(track["text"])
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        voice_mp3 = tmp / "voice.mp3"
        if music_only:
            raise SystemExit("--music-only 暂未实现独立输出")
        voice_mp3.write_bytes(tts(text, key))
        voice_wav = tmp / "voice.wav"
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(voice_mp3), "-ac", "1", "-ar", str(SR),
                        "-af", "loudnorm=I=-19:TP=-2:LRA=7", str(voice_wav)], check=True)
        sr, v = wavfile.read(voice_wav)
        assert sr == SR
        v = v.astype(np.float32) / 32768.0
        tail = 6.0
        total = len(v) / SR + tail
        m = make_music(track, total)
        mix = np.zeros(len(m), dtype=np.float32)
        mix[: len(v)] += v
        mix += 0.16 * m  # 配乐比人声低约 16 dB
        mix = np.tanh(mix * 1.1) * 0.9
        mix_wav = tmp / "mix.wav"
        wavfile.write(mix_wav, SR, (mix * 32767).astype(np.int16))
        OUT_DIR.mkdir(parents=True, exist_ok=True)
        out = OUT_DIR / f"{track['id']}.mp3"
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(mix_wav), "-ac", "1", "-ar", str(SR), "-c:a", "libmp3lame",
                        "-b:a", "40k", "-metadata", f"title={track['title']}",
                        "-metadata", "comment=AI合成语音 + 程序合成配乐，顺时原创", str(out)], check=True)
    data = out.read_bytes()
    dur = float(subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "default=nw=1:nk=1", str(out)]).decode().strip())
    return {"duration_seconds": int(round(dur)), "size_bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--only")
    ap.add_argument("--music-only", action="store_true")
    args = ap.parse_args()
    key = os.environ.get("MINIMAX_API_KEY") or os.environ.get("MINIMAX_CN_API_KEY")
    if not key:
        sys.exit("未设置 MINIMAX_API_KEY / MINIMAX_CN_API_KEY")
    doc = json.loads(TRACKS_JSON.read_text(encoding="utf-8"))
    for track in doc["tracks"]:
        if args.only and track["id"] != args.only:
            continue
        info = build(track, key, args.music_only)
        track.update(info)
        print(track["id"], info["duration_seconds"], "秒", round(info["size_bytes"] / 1024), "KB")
    doc["voice"] = {"provider": "MiniMax 开放平台（国内）", "model": TTS_MODEL, "voice": VOICE_ID, "speed": VOICE_SPEED}
    TRACKS_JSON.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
