---
name: driving-mode
description: Hands-free voice mode for talking to Claude Code while driving (or otherwise away from the keyboard). Triggers on "driving mode", "driving mode on", "talk to me", "stop talking", "driving mode off". Speaks replies aloud and reopens dictation automatically so the user can keep talking without touching the keyboard.
---

# Driving mode

A hands-free loop: Claude speaks its reply, then reopens Wispr Flow dictation.
The user just talks. When they go quiet for a few seconds, dictation stops and
Enter is pressed, so the reply reaches Claude.

## Turning it on and off

- "driving mode", "driving mode on", "talk to me", and similar phrases: run
  `drive-mode on`, then confirm briefly and continue in voice mode.
- "driving mode off", "stop talking", and similar phrases: run `drive-mode off`
  (this also stops any running listener and resets Wispr), then confirm in
  plain text — do not speak the confirmation.
- Before speaking any reply, run `drive-mode status`. If it prints `off`,
  reply in normal text only — no speech, no listener, even if driving mode
  was on earlier in the conversation.

## While driving mode is on

- Speak every reply with `drive-say --listen "<reply text>"`. Still print the
  text normally in the transcript.
- Keep the spoken text conversational and plain: no markdown, code, URLs, or
  long hex strings. Aim for about 20-30 seconds of speech, one point at a
  time — don't stack multiple questions or topics in one turn.
- `drive-say --listen` stops any previous listener before speaking, so never
  call it while another listener you started is still running. Never speak
  (via `say`, `sayit`, or anything else) while a listener is active — Wispr
  will transcribe Claude's own voice.
- After speaking, the listener runs in the background and waits for the user.
  Just wait for their next message — do not poll or sleep for it.
- Stay in driving mode across turns until the user says "driving mode off" or
  equivalent, even if they don't repeat the phrase every time.
