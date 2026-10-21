# claude-restore

Keep a working set of [Claude Code](https://claude.com/claude-code) sessions alive across reboots, and switch them between the Anthropic API and Amazon Bedrock without losing a conversation.

Two small scripts for people who run several named Claude Code sessions in one tmux session, one window each:

- **`claude-restore`** snapshots your live sessions every 10 minutes and rebuilds them after a reboot or a Claude Code update: same names, same working directories, same left-to-right window order, each resumed with `claude -r <sessionId>`.
- **`claude-provider`** moves running sessions between the Anthropic API and Bedrock (and optionally to a different model) by respawning each window on the same session id.

## Requirements

- Linux (both scripts read `/proc`)
- tmux, Python 3, bash, and Claude Code on your `PATH`
- curl, only for `claude-provider key --check`

## Install

```bash
git clone https://github.com/armodis/claude-restore.git ~/claude-restore
~/claude-restore/install.sh --cron
```

This symlinks both scripts into `~/.local/bin` and adds one crontab entry that saves a snapshot every 10 minutes. Re-running it is safe. Leave out `--cron` to skip the crontab. A `git pull` in the checkout updates the installed commands.

The installer prints a set of short aliases (`cr`, `crl`, `crs`, `crr`, `cpv`) you can add to your shell config.

## Restoring sessions

Run your Claude Code sessions as windows of a tmux session named `claude` (set `CLAUDE_RESTORE_SESSION` to use another name). Name each session with `/rename` so the windows come back labelled.

```bash
claude-restore --list        # what would be restored, in order
claude-restore               # rebuild the tmux session and attach
claude-restore --dry-run     # print the tmux commands instead
claude-restore --days 90     # include sessions idle longer than the default 30 days
claude-restore --restart     # tear down and rebuild, e.g. after a Claude Code update
claude-restore --save        # snapshot now (the cron entry does this every 10 minutes)
```

If the `claude` tmux session already exists, `claude-restore` just attaches to it.

### How it works

Claude Code records each running session in `~/.claude/sessions/<pid>.json` and deletes the record when the process exits, so after a reboot that directory is empty. `claude-restore --save` merges those records into `~/.claude/session-snapshot.tsv`, along with each session's tmux window index and the current boot id. Restore reads the snapshot, skips sessions whose directory or transcript is gone, and opens one window per session.

A session drops out of the snapshot only when it was seen running during the current boot and has since been closed while other sessions are still running. A reboot, or closing every window at once, never empties it.

## Switching between Anthropic and Bedrock

```bash
claude-provider status                       # backend for each window
claude-provider bedrock                      # the current window
claude-provider anthropic 3 7 notes          # by window index or name
claude-provider bedrock --all                # every Claude window
claude-provider anthropic --all --model opus # also change the model
claude-provider bedrock --all --force        # respawn even windows already on Bedrock
```

A running Claude Code process can't change backend, so each selected window is respawned with `claude -r <sessionId>`; the conversation carries on where it was. The window you run the command from is skipped. Use `/model` there instead.

`claude-restore --bedrock` and `claude-restore --anthropic` rebuild every window on one backend.

## Your Bedrock API key

Everyone uses their own key. Shared keys get revoked.

```bash
claude-provider key          # paste your key (hidden) and choose a region
claude-provider key --check  # one read-only Bedrock call to confirm the key works
```

The key is saved to `~/.config/claude-provider/bedrock.env` with mode 600, in a directory with mode 700. Switching a window to Bedrock sources that file inside the new shell, so the key never appears in a command line, `ps` output, or shell history. If no key is saved yet, `claude-provider bedrock` and `claude-restore --bedrock` ask for one first.

Run `claude-provider key` again whenever your key changes. Windows already on Bedrock keep using the old key until they are respawned with `claude-provider bedrock --all --force`.

[`bedrock.env.example`](https://github.com/armodis/claude-restore/blob/main/bedrock.env.example) shows the file format, including an optional model pin. This repo's `.gitignore` excludes `*.env` files so a real key can't be committed by accident.

## License

[MIT](https://github.com/armodis/claude-restore/blob/main/LICENSE)
