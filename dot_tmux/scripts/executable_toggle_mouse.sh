
# exit the script if any statement returns a non-true return value
set -e

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

"$@"
