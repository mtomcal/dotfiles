#!/bin/bash
panes=($(tmux list-panes -F "#{pane_id}"))
n=${#panes[@]}
for ((i=0; i<n/2; i++)); do
  tmux swap-pane -s "${panes[$i]}" -t "${panes[$((n-1-i))]}"
done
