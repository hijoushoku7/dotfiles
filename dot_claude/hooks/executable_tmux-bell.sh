#!/bin/sh
# Claude Code hooks -> tmux window bell / status marker
[ -n "$TMUX_PANE" ] || exit 0

case "$1" in
  clear)
    tmux set -uw -t "$TMUX_PANE" @claude_state 2>/dev/null
    ;;
  *)
    tmux set -w -t "$TMUX_PANE" @claude_state "$1" 2>/dev/null
    tmux display -p -t "$TMUX_PANE" '#{pane_tty}' 2>/dev/null |
      { read -r tty; [ -n "$tty" ] && printf '\a' > "$tty"; }
    ;;
esac

exit 0
