#!/bin/bash
# Start pi inside a tmux session so the tmux orchestration skill
# can spawn additional Pi agents in separate panes/windows.
#
# If pi args are passed, they're forwarded to the pi command.
# The tmux session is named "pis" for easy identification.

exec tmux new-session -s pis "pi $*"
