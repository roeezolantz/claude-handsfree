#!/usr/bin/env python3
"""Exit 0 once the speaker has talked and then been silent; exit 1 if nobody speaks. Uses WebRTC VAD, so road noise is not speech."""
import os, subprocess, sys, time

HELP = """wispr-wait-quiet.py

Blocks until the speaker has talked and then gone quiet for WISPR_SILENCE_SECONDS,
reading raw audio from `rec` (sox) and classifying speech with WebRTC VAD (so steady
road noise does not count as talking). Exit 0 if the speaker talked and went quiet,
or if nobody ever speaks before WISPR_MAX_SECONDS elapses with no speech detected
after WISPR_NO_SPEECH_SECONDS. Exit 1 if nobody ever speaks before the no-speech
timeout.

Env vars (all optional):
  WISPR_SILENCE_SECONDS    Seconds of quiet after speech that ends the turn (default: 3.0)
  WISPR_NO_SPEECH_SECONDS  Seconds to wait for speech to start at all (default: 45)
  WISPR_MAX_SECONDS        Hard cap on the whole turn (default: 180)
  WISPR_VAD_MODE           WebRTC VAD aggressiveness 0-3, 3 = most noise-tolerant (default: 3)

Requires: sox (`rec` on PATH), the `webrtcvad-wheels` Python package.
"""

if len(sys.argv) > 1 and sys.argv[1] in ("--help", "-h"):
    print(HELP)
    sys.exit(0)

import webrtcvad

RATE, FRAME_MS = 16000, 30
QUIET_SECONDS = float(os.environ.get("WISPR_SILENCE_SECONDS", "3.0"))
NO_SPEECH_TIMEOUT = float(os.environ.get("WISPR_NO_SPEECH_SECONDS", "45"))
MAX_SECONDS = float(os.environ.get("WISPR_MAX_SECONDS", "180"))
AGGRESSIVENESS = int(os.environ.get("WISPR_VAD_MODE", "3"))  # 3 = most noise-tolerant
SPEECH_RATIO = 0.6   # share of voiced frames in the last 300 ms that counts as talking
WINDOW_FRAMES = 10

vad = webrtcvad.Vad(AGGRESSIVENESS)
frame_bytes = RATE * FRAME_MS // 1000 * 2
rec = subprocess.Popen(["rec", "-q", "-t", "raw", "-b", "16", "-e", "signed", "-c", "1", "-r", str(RATE), "-"],
                       stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
recent, spoke, quiet, start = [], False, 0.0, time.time()
try:
    while True:
        frame = rec.stdout.read(frame_bytes)
        if len(frame) < frame_bytes:
            sys.exit(1)
        recent = (recent + [vad.is_speech(frame, RATE)])[-WINDOW_FRAMES:]
        talking = len(recent) == WINDOW_FRAMES and sum(recent) / WINDOW_FRAMES >= SPEECH_RATIO
        if talking:
            spoke, quiet = True, 0.0
        else:
            quiet += FRAME_MS / 1000
        elapsed = time.time() - start
        if spoke and quiet >= QUIET_SECONDS:
            sys.exit(0)
        if (not spoke and elapsed >= NO_SPEECH_TIMEOUT) or elapsed >= MAX_SECONDS:
            sys.exit(0 if spoke else 1)
finally:
    rec.kill()
