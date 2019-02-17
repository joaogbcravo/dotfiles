# exit the script if any statement returns a non-true return value
set -e

_is_enabled() {
  ( ([ x"$1" = x"enabled" ] || [ x"$1" = x"true" ] || [ x"$1" = x"yes" ] || [ x"$1" = x"1" ]) && return 0 ) || return 1
}

_override_bindings() {
  cfg=$(mktemp) && trap 'rm -f $cfg*' EXIT

  tmux list-keys | grep -vF 'tmux.conf.local' | grep -E '(new-window|split(-|_)window|new-session|copy-selection|copy-pipe)' > "$cfg"

  # tmux 3.0 doesn't include 02254d1e5c881be95fd2fc37b4c4209640b6b266 and the
  # output of list-keys can be truncated
  perl -p -i -e "s/'#\{\?window_zoomed_flag,Unzoom,Zoom\}' 'z' \{resize-pane -$/'#{?window_zoomed_flag,Unzoom,Zoom}' 'z' {resize-pane -Z}\"/g" "$cfg"

  tmux_conf_new_window_retain_current_path=${tmux_conf_new_window_retain_current_path:-false}
  if _is_enabled "$tmux_conf_new_window_retain_current_path"; then
    perl -p -i \
      -e "s/\b(new-window)\b(?!\s+-)/{$&}/g if /\bdisplay-menu\b/" \
      -e ';' \
      -e "s/\bnew-window\b(?!([^;}\n\"]*?)(?:\s+-c\s+(\\\?\"?|'?)#\{pane_current_path\}\2))/new-window -c '#{pane_current_path}'/g" \
      "$cfg"
  else
    perl -p -i -e "s/\bnew-window\b([^;}\n\"]*?)(?:\s+-c\s+(\\\?\"?|'?)#\{pane_current_path\}\2)/new-window\1/g" "$cfg"
  fi

  tmux_conf_new_pane_retain_current_path=${tmux_conf_new_pane_retain_current_path:-false}
  if _is_enabled "$tmux_conf_new_pane_retain_current_path"; then
    perl -p -i -e "s/\bsplit-window\b(?!([^;}\n\"]*?)(?:\s+-c\s+(\\\?\"?|'?)#\{pane_current_path\}\2))/split-window -c '#{pane_current_path}'/g" "$cfg"
  else
    perl -p -i -e "s/\bsplit-window\b([^;}\n\"]*?)(?:\s+-c\s+(\\\?\"?|'?)#\{pane_current_path\}\2)/split-window\1/g" "$cfg"
  fi
  
  tmux_conf_new_pane_reconnect_ssh=${tmux_conf_new_pane_reconnect_ssh:-false}
  if _is_enabled "$tmux_conf_new_pane_reconnect_ssh"; then
    if _is_enabled "$tmux_conf_new_pane_retain_current_path"; then
      perl -p -i \
        -e "s/\bsplit-window\b([^;}\n\"]*?)(?:\s+-c\s+(\\\?\"?|'?)#\{pane_current_path\}\2)([^;}\n\"]*)/run-shell 'cut -c3- ~\/\.tmux\.conf | sh -s _split_window #{pane_tty}\1\3 -c #\{pane_current_path\}'/g" \
        -e ';' \
        -e "s/\b_split_window\b\s+#\{pane_tty\}(.*?)\s+-c\s+\\\\\"#\{pane_current_path\}\\\\\"\"/_split_window #{pane_tty}\1 -c \\\\\"#{pane_current_path}\\\\\"\"/g" \
        "$cfg"
    else
      perl -p -i \
        -e "s/\bsplit-window\b([^;}\n]*)/run-shell 'cut -c3- ~\/\.tmux\.conf | sh -s _split_window #{pane_tty}\1'/g" \
        -e ';' \
        -e "s/\b_split_window\b\s+#\{pane_tty\}(.*?)\s+-c\s+\\\\\"#\{pane_current_path\}\\\\\"\"/_split_window #{pane_tty}\1\"/g" \
        "$cfg"
    fi
  else
    if _is_enabled "$tmux_conf_new_pane_retain_current_path"; then
      perl -p -i -e "s/\brun-shell\b(\s+(\"|')cut\s+-c3-\s+~\/\.tmux\.conf\s+\|\s+sh\s+-s\s+_split_window\s+#\{pane_tty\})(.*?)\s+-c\s+#\{pane_current_path\}\2/split-window\3 -c '#{pane_current_path}'/g" "$cfg"
    else
      perl -p -i -e "s/\brun-shell\b(\s+(\"|')cut\s+-c3-\s+~\/\.tmux\.conf\s+\|\s+sh\s+-s\s+_split_window\s+#\{pane_tty\})(.*)\2/split-window\3/g" "$cfg"
    fi
  fi

  # Ask for a name when a new session is created
  perl -p -i \
    -e "s/(?<!command-prompt -p )\b(new-session)\b(?!\s+-)/{$&}/g if /\bdisplay-menu\b/" \
    -e ';' \
    -e "s/(?<!\bcommand-prompt -p )\bnew-session\b(?! -s)/command-prompt -p new-session 'new-session -s \"%%\"'/g" \
    "$cfg"

  # Ask for a name when a new window is created
  perl -p -i \
    -e "s/(?<!command-prompt -p )\b(new-window)\b(?!\n+-)/{$&}/g if /\bdisplay-menu\b/" \
    -e ';' \
    -e "s/(?<!\bcommand-prompt -p )\bnew-window\b(?! -n)/command-prompt -p new-window 'new-window -n \"%%\"'/g" \
    "$cfg"

  #
  # tmux_conf_copy_to_os_clipboard=${tmux_conf_copy_to_os_clipboard:-false}
  # command -v pbcopy > /dev/null 2>&1 && command='pbcopy'
  # command -v reattach-to-user-namespace > /dev/null 2>&1 && command='reattach-to-user-namespace pbcopy'
  # command -v xsel > /dev/null 2>&1 && command='xsel -i -b'
  # ! command -v xsel > /dev/null 2>&1 && command -v xclip > /dev/null 2>&1 && command='xclip -i -selection clipboard > \/dev\/null 2>\&1'
  # command -v clip.exe > /dev/null 2>&1 && command='clip\.exe'
  # [ -c /dev/clipboard ] && command='cat > \/dev\/clipboard'
  #
  # if [ -n "$command" ]; then
  #   if _is_enabled "$tmux_conf_copy_to_os_clipboard"; then
  #     perl -p -i -e "s/\bcopy-selection(-and-cancel)?\b/copy-pipe\1 '$command'/g" "$cfg"
  #   else
  #     perl -p -i -e "s/\bcopy-pipe(-and-cancel)?\b\s+(\"|')?$command\2/copy-selection\1/g" "$cfg"
  #   fi
  # fi
  #
  # # until tmux >= 3.0, output of tmux list-keys can't be consumed back by tmux source-file without applying some escapings
  awk < "$cfg" \
    '{i = $2 == "-T" ? 4 : 5; gsub(/^[;]$/, "\\\\&", $i); gsub(/^[$"#~]$/, "'"'"'&'"'"'", $i); gsub(/^['"'"']$/, "\"&\"", $i); print}' > "$cfg.in"


  # ignore bindings with errors
  while ! out=$(tmux source-file "$cfg.in"); do
    line=$(printf "%s" "$out" | cut -d':' -f2)
    perl -n -i -e "if ($. != $line) { print }" "$cfg.in"
  done
}

"$@"
