#!/bin/bash
# Start pi inside a tmux session for stable container terminal behavior.
#
# If pi args are passed, they're forwarded to the pi command.
# The tmux session is named "pis" for easy identification.

exec tmux new-session -s pis "pi $*"
