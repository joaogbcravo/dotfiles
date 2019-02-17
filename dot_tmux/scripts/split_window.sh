
# exit the script if any statement returns a non-true return value
set -e

_split_window() {
  tty=${1:-$(tmux display -p '#{pane_tty}')}
  shift

  tty_info=$(_tty_info "$tty")
  command=$(printf '%s' "$tty_info" | cut -d' ' -f3-)

  case "$command" in
    *mosh-client*)
      # shellcheck disable=SC2046
       tmux split-window "$@" mosh $(echo "$command" | sed -E -e 's/.*mosh-client -# (.*)\|.*$/\1/')
     ;;
    *ssh*)
      # shellcheck disable=SC2046
      tmux split-window "$@" $(echo "$command" | sed -e 's/;/\\;/g')
      ;;
    *)
      tmux split-window "$@"
  esac
}
