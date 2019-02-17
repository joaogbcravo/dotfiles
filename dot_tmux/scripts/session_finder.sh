
# exit the script if any statement returns a non-true return value
set -e

# tmux ls -F '#{session_attached} #{session_last_attached}#{?session_last_attached,,0} #{session_created} #{session_id} #{session_windows} #{session_name}' \

fs() {
  local session
  session=$(tmux list-sessions -F "#{session_name}" | \
  fzf --reverse --query="$1" --select-1 --exit-0) &&
  tmux switch-client -t "$session"
}

_toggle_mouse() {
  old=$(tmux show -gv mouse)
  new=""

  if [ "$old" = "on" ]; then
    new="off"
  else
    new="on"
  fi

  tmux set -g mouse $new \;\
       display "mouse: $new"
}


session_finder() {
  tmux set-hook pane-focus-out "set-hook -u pane-focus-out ; send-keys C-c"

  prompt="find/create session: "
	fzf_out=$(tmux ls -F '#{?session_attached,0,1} #{?session_last_attached,,0}#{session_last_attached} #{?session_attached,*, } #{session_name}' \
    | sort \
    | perl -pe 's/^[01] [0-9]+ //' \
    | fzf --reverse --print-query --prompt="$prompt" \
    || true)

	line_count=$(echo "$fzf_out" | wc -l)
  session_name="$(echo "$fzf_out" | tail -n1 | perl -pe 's/^[\* ] //')"
  tmux set-hook -u pane-focus-out

  if [ $line_count -eq 1 ]; then
		tmux new-session -d -s "$session_name"
	fi
  tmux switch-client -t "$session_name"
}

"$@"
