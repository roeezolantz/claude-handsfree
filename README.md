# claude-handsfree

A hands-free way to talk to Claude Code while driving. Claude speaks its
answer out loud, then reopens dictation automatically. We just talk. When we
go quiet for a few seconds, dictation stops and Enter gets pressed, so the
reply reaches Claude without anyone touching a keyboard.

## Why this exists

We review a lot of work — PR feedback, deploy status, "did that job finish"
— during the commute. Typing at a red light is a bad idea, and talking to
Claude shouldn't require looking at a screen at all. Wispr Flow already
turns speech into text well; this project just wires it to Claude Code so a
whole conversation can happen by voice, start to finish.

## What it looks like

We say "driving mode" into the terminal. Claude confirms, speaks its next
reply out loud through Say It (or `say` if that's not installed), and a
moment later the mic is listening again — Wispr's hands-free indicator comes
on. We talk. A few seconds after we stop, dictation closes and the text we
just said appears in the terminal and gets sent, like we typed it and hit
Enter ourselves. Repeat for as long as the conversation goes. Say "driving
mode off" and it's back to a normal typed session.

## Requirements

- macOS (this uses `CGEvent` for key simulation and Apple's TTS/Say It — it
  will not run anywhere else).
- [Wispr Flow](https://wisprflow.ai), with its **default** shortcuts: `Fn`
  to start/stop dictation, `Fn`+`Space` to toggle hands-free mode. If you've
  remapped either, see Troubleshooting.
- `sox` (for the `rec` command the VAD listener reads from). `install.sh`
  offers to `brew install sox` for you.
- Xcode Command Line Tools (for `swiftc`) and Python 3.
- Optional: [Say It](https://sayit.im) for nicer, local TTS. Without it,
  `drive-say` falls back to macOS's built-in `say`.

## Install

```bash
git clone <this-repo> ~/Development/claude-handsfree
cd ~/Development/claude-handsfree
./install.sh
```

This builds the Swift key-event helper, creates a small Python venv with the
VAD dependency, installs the bin scripts to `~/.local/bin` (make sure that's
on your `PATH`), and installs the `driving-mode` skill to
`~/.claude/skills/driving-mode`. It's safe to re-run any time.

### Permissions (one-time)

1. **Accessibility** — the terminal app that runs these scripts needs to be
   allowed to send key events. `install.sh` opens the System Settings pane
   for you; add your terminal (Terminal, iTerm, Ghostty, whatever you use)
   under *Privacy & Security → Accessibility* and toggle it on. No restart
   needed.
2. **Microphone** — macOS prompts the first time `rec` records audio. Allow
   it once.

### Turning it on

Say "driving mode" (or run `drive-mode on` yourself), and Claude starts
speaking replies and reopening the mic. Say "driving mode off" (or run
`drive-mode off`) to go back to typing. Check where it's currently set with
`drive-mode status`.

A one-line alias is handy if you flip it manually a lot:

```bash
alias dm='drive-mode'   # add to ~/.zshrc, then: dm on / dm off / dm status
```

## Tuning

All of these are environment variables, read at run time — set them in your
shell profile if you want them to stick.

| Variable | Default | What it does |
|---|---|---|
| `WISPR_SILENCE_SECONDS` | `3.0` | How long we have to be quiet after talking before the turn ends. |
| `WISPR_NO_SPEECH_SECONDS` | `45` | How long to wait for us to start talking at all before giving up. |
| `WISPR_MAX_SECONDS` | `180` | Hard cap on one listening turn, speech or not. |
| `WISPR_VAD_MODE` | `3` | WebRTC VAD aggressiveness, 0–3. `3` is most tolerant of road noise. |
| `WISPR_PASTE_WAIT` | `3` | Seconds to wait after stopping dictation before pressing Enter (gives Wispr time to finish typing). |
| `HANDSFREE_SAYIT_VOICE` / `_MODEL` / `_RATE` | `Russell` / `phonon-31m-en` / `0.9` | Say It voice settings. |

Run any script with `--help` for the full list it reads, including the
install-location overrides (`PREFIX`, `HANDSFREE_VENV`, `SKILLS_DIR`).

## Troubleshooting

- **Wispr won't stop listening.** There's no voice command for this — only a
  key press stops hands-free mode. That's exactly what `wispr-turn` and
  `drive-stop` do; if it's stuck, run `drive-stop` by hand.
- **The VAD never detects speech, or triggers on road noise.** Fixed volume
  thresholds don't work in a car — road noise alone can sit around 6% of
  full scale, and Wispr may even be listening on a different microphone than
  the one feeding the VAD. That's why this uses WebRTC VAD instead of a
  simple level check. Try `WISPR_VAD_MODE=3` (already the default) and make
  sure the right input device is selected system-wide.
- **Nothing happens when a script runs a key event.** Almost always a missing
  Accessibility grant — see Permissions above. No restart is required after
  granting it.
- **`osascript`/System Events keystrokes don't work.** Correct — macOS blocks
  those with error `-1743` in this kind of flow. That's why Enter is sent via
  `CGEvent` (`wispr-handsfree enter`) instead of AppleScript.
- **The Fn+Space toggle gets out of sync with what's actually happening.**
  Both `wispr-turn` and `drive-say --listen` send a `tap` (`Fn` alone) before
  starting, specifically to reset this. If you call the raw
  `wispr-handsfree` binary yourself and lose track of state, run
  `drive-stop` to resync.
- **Claude starts talking over something I said, or Wispr transcribes
  Claude's own voice.** `drive-say` stops any running listener before it
  speaks. If you're scripting around this yourself, always stop the listener
  before producing new audio.
- **The mic seems slow to open, or I forget what I wanted to say.** The
  listener needs to start in the *same* command as the speech (`drive-say
  --listen` does this via `nohup ... & disown` internally). If it's split
  into a separate step, the model's own thinking time delays the mic.

## Limitations

- Only works while the terminal running Claude Code has focus — this isn't
  a system-wide voice assistant.
- macOS only.
- Depends on Wispr Flow's default `Fn` / `Fn`+`Space` shortcuts. Remap them
  in Wispr and the key codes in `bin/wispr-handsfree.swift` will no longer
  match.

## Safety

This is voice-only by design, but it's not a substitute for attention. Keep
your eyes on the road and your hands on the wheel — glance at the screen
only when stopped, if at all.

## License

MIT. See [LICENSE](LICENSE).
