# exit the script if any statement returns a non-true return value
set -e

unset GREP_OPTIONS
export LC_NUMERIC=C

if ! printf '' | sed -E 's///' 2>/dev/null; then
  if printf '' | sed -r 's///' 2>/dev/null; then
    sed () {
      n=$#; while [ "$n" -gt 0 ]; do arg=$1; shift; case $arg in -E*) arg=-r${arg#-E};; esac; set -- "$@" "$arg"; n=$(( n - 1 )); done
      command sed "$@"
    }
  fi
fi

__newline='
'

_is_enabled() {
  ( ([ x"$1" = x"enabled" ] || [ x"$1" = x"true" ] || [ x"$1" = x"yes" ] || [ x"$1" = x"1" ]) && return 0 ) || return 1
}

if command -v perl > /dev/null 2>&1; then
  _decode_unicode_escapes() {
    printf '%s' "$*" | perl -CS -pe 's/(\\u([0-9A-Fa-f]{1,4})|\\U([0-9A-Fa-f]{1,8}))/chr(hex($2.$3))/eg' 2>/dev/null
  }
elif bash --norc --noprofile -c '[[ ! $BASH_VERSION < 4.2. ]]' > /dev/null 2>&1; then
  _decode_unicode_escapes() {
    bash --norc --noprofile -c "printf '%b' '$*'"
  }
elif command -v python > /dev/null 2>&1; then
  _decode_unicode_escapes() {
    python -c "import re; import sys; sys.stdout.write(re.sub(r'\\\U([0-9A-Fa-f]{1,8})', lambda match: r'\U%s' % match.group(1).zfill(8), r'$*').encode().decode('unicode-escape', 'ignore'))"
  }
else
  _decode_unicode_escapes() {
    printf '%b' "$*"
  }
fi


_battery() {
  count=0
  charge=0
  uname_s=$(uname -s)

  case "$uname_s" in
    *Darwin*)
      while IFS= read -r line; do
        if [ x"$discharging" != x"true" ]; then
          discharging=$(printf '%s' "$line" | grep -qi "discharging" && echo "true" || echo "false")
        fi
        percentage=$(printf '%s' "$line" | grep -E -o '[0-9]+%')
        charge=$(awk -v charge="$charge" -v percentage="${percentage%%%}" 'BEGIN { print charge + percentage / 100 }')
        count=$((count + 1))
      done  << EOF
$(pmset -g batt | grep 'InternalBattery')
EOF
      ;;
    *Linux*)
      while IFS= read -r batpath; do
        grep -i -q device "$batpath/scope" 2> /dev/null && continue

        if [ x"$discharging" != x"true" ]; then
          discharging=$(grep -qi "discharging" "$batpath/status" && echo "true" || echo "false")
        fi
        bat_capacity="$batpath/capacity"
        if [ -r "$bat_capacity" ]; then
          charge=$(awk -v charge="$charge" -v capacity="$(cat "$bat_capacity")" 'BEGIN { print charge + capacity / 100 }')
        else
          bat_energy_full="$batpath/energy_full"
          bat_energy_now="$batpath/energy_now"
          if [ -r "$bat_energy_full" ] && [ -r "$bat_energy_now" ]; then
            charge=$(awk -v charge="$charge" -v energy_now="$(cat "$bat_energy_now")" -v energy_full="$(cat "$bat_energy_full")" 'BEGIN { print charge + energy_now / energy_full }')
          fi
        fi
        count=$((count + 1))
      done  << EOF
$(find /sys/class/power_supply -maxdepth 1 -iname '*bat*')
EOF
      ;;
  esac
  [ "$count" -ne 0 ] && charge=$(awk -v charge="$charge" -v count="$count" 'BEGIN { print charge / count }')
  if [ "$charge" -eq 0 ]; then
    tmux  set -ug '@battery_status'  \;\
          set -ug '@battery_vbar'    \;\
          set -ug '@battery_percentage'
    return
  fi

  variables=$(tmux  show -gqv '@battery_bar_symbol_full' \;\
                    show -gqv '@battery_bar_symbol_empty' \;\
                    show -gqv '@battery_bar_length' \;\
                    show -gqv '@battery_hbar_palette' \;\
                    show -gqv '@battery_vbar_palette' \;\
                    show -gqv '@battery_status_charging' \;\
                    show -gqv '@battery_status_discharging')
  # shellcheck disable=SC2086
  { set -f; IFS="$__newline"; set -- $variables; unset IFS; set +f; }

  battery_bar_symbol_full=$1
  battery_bar_symbol_empty=$2
  battery_bar_length=$3
  battery_hbar_palette=$4
  battery_vbar_palette=$5
  battery_status_charging=$6
  battery_status_discharging=$7

  if [ x"$battery_bar_length" = x"auto" ]; then
    columns=$(tmux -q display -p '#{client_width}' 2> /dev/null || echo 80)
    if [ "$columns" -ge 80 ]; then
      battery_bar_length=10
    else
      battery_bar_length=5
    fi
  fi

  if [ x"$discharging" = x"true" ]; then
    battery_status="$battery_status_discharging"
  else
    battery_status="$battery_status_charging"
  fi

  # shellcheck disable=SC2086
  { set -f; IFS=,; set -- $battery_vbar_palette; unset IFS; set +f; }
  palette_style=$1
  [ x"$palette_style" = x"gradient" ] && palette="196 202 208 214 220 226 190 154 118 8"

  palette=$(echo "$palette" | awk -v n="$battery_bar_length" '{ for (i = 0; i < n; ++i) printf $(1 + (i * NF / n))" " }')
  eval set -- "$palette"

  full=$(awk "BEGIN { printf \"%.0f\", ($charge) * $battery_bar_length }")
  eval battery_vbar_fg="colour\${$((full == 0 ? 1 : full))}"

  eval set -- "▁ ▂ ▃ ▄ ▅ ▆ ▇ █"
  # shellcheck disable=SC2046

  eval $(awk "BEGIN { printf \"battery_vbar_symbol=$%d\", ($charge) * ($# - 1) + 1 }")
  battery_vbar="#[fg=${battery_vbar_fg?}]${battery_vbar_symbol?}"

  battery_percentage="$(awk "BEGIN { printf \"%.0f%%\", ($charge) * 100 }")"

  tmux  set -g '@battery_status' "$battery_status" \;\
        set -g '@battery_vbar' "$battery_vbar" \;\
        set -g '@battery_percentage' "$battery_percentage"
}

_tty_info() {
  tty="${1##/dev/}"

  ps -t "$tty" -o user=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX -o pid= -o ppid= -o command= | awk '
    NR > 1 && ((/ssh/ && !/-W/) || !/ssh/) {
      user[$2] = $1; parent[$2] = $3; child[$3] = $2; for (i = 4 ; i <= NF; ++i) command[$2] = i > 4 ? command[$2] FS $i : $i
    }
    END {
      for (i in parent)
      {
        if (!(i in child) && parent[i] != 1)
        {
          print i, user[i], command[i]
          exit
        }
      }
    }
    '
}

_ssh_or_mosh_args() {
  args=$(printf '%s' "$1" | awk '/ssh/ && !/vagrant ssh/ && !/autossh/ && !/-W/ { $1=""; print $0; exit }')
  if [ -z "$args" ]; then
    args=$(printf '%s' "$1" | grep 'mosh-client' | sed -E -e 's/.*mosh-client -# (.*)\|.*$/\1/' -e 's/-[^ ]*//g' -e 's/\d:\d//g')
  fi

 printf '%s' "$args"
}

_username() {
  tty=${1:-$(tmux display -p '#{pane_tty}')}
  ssh_only=$2

  tty_info=$(_tty_info "$tty")
  command=$(printf '%s' "$tty_info" | cut -d' ' -f3-)

  ssh_or_mosh_args=$(_ssh_or_mosh_args "$command")
  if [ -n "$ssh_or_mosh_args" ]; then
    # shellcheck disable=SC2086
    username=$(ssh -G $ssh_or_mosh_args 2>/dev/null | awk 'NR > 2 { exit } ; /^user / { print $2 }')
    # shellcheck disable=SC2086
    [ -z "$username" ] && username=$(ssh -T -o ControlPath=none -o ProxyCommand="sh -c 'echo %%username%% %r >&2'" $ssh_or_mosh_args 2>&1 | awk '/^%username% / { print $2; exit }')
  else
    if ! _is_enabled "$ssh_only"; then
      username=$(printf '%s' "$tty_info" | cut -d' ' -f2)
    fi
  fi

  printf '%s' "$username"
}

_hostname() {
  tty=${1:-$(tmux display -p '#{pane_tty}')}
  ssh_only=$2

  tty_info=$(_tty_info "$tty")
  command=$(printf '%s' "$tty_info" | cut -d' ' -f3-)

  ssh_or_mosh_args=$(_ssh_or_mosh_args "$command")
  if [ -n "$ssh_or_mosh_args" ]; then
    # shellcheck disable=SC2086
    hostname=$(ssh -G $ssh_or_mosh_args 2>/dev/null | awk 'NR > 2 { exit } ; /^hostname / { print $2 }')
    # shellcheck disable=SC2086
    [ -z "$hostname" ] && hostname=$(ssh -T -o ControlPath=none -o ProxyCommand="sh -c 'echo %%hostname%% %h >&2'" $ssh_or_mosh_args 2>&1 | awk '/^%hostname% / { print $2; exit }')
    #shellcheck disable=SC1004
    hostname=$(echo "$hostname" | awk '\
    { \
      if ($1~/^[0-9.:]+$/) \
        print $1; \
      else \
        split($1, a, ".") ; print a[1] \
    }')
  else
    if ! _is_enabled "$ssh_only"; then
      hostname=$(command hostname -s)
    fi
  fi

  printf '%s' "$hostname"
}

_root() {
  tty=${1:-$(tmux display -p '#{pane_tty}')}
  username=$(_username "$tty" false)

  if [ x"$username" = x"root" ]; then
    tmux show -gqv '@root'
  else
    echo ""
  fi
}

_apply_theme() {

  # -- panes -------------------------------------------------------------

  tmux_conf_theme_window_fg=${tmux_conf_theme_window_fg:-default}
  tmux_conf_theme_window_bg=${tmux_conf_theme_window_bg:-default}
  tmux_conf_theme_focused_pane_fg=${tmux_conf_theme_focused_pane_fg:-'default'} # default
  tmux_conf_theme_focused_pane_bg=${tmux_conf_theme_focused_pane_bg:-'#0087d7'} # light blue

  # tmux 1.9 doesn't really like set -q
  if tmux show -g -w | grep -q window-style; then
    tmux setw -g window-style "fg=$tmux_conf_theme_window_fg,bg=$tmux_conf_theme_window_bg"
    tmux setw -g window-active-style "fg=$tmux_conf_theme_focused_pane_fg,bg=$tmux_conf_theme_focused_pane_bg"
  fi

  #tmux_conf_theme_pane_border_style=${tmux_conf_theme_pane_border_style:-thin}
  tmux_conf_theme_pane_border=${tmux_conf_theme_pane_border:-'#444444'}               # light gray
  tmux_conf_theme_pane_active_border=${tmux_conf_theme_pane_active_border:-'#00afff'} # light blue
  tmux_conf_theme_pane_border_fg=${tmux_conf_theme_pane_border_fg:-$tmux_conf_theme_pane_border}
  tmux_conf_theme_pane_active_border_fg=${tmux_conf_theme_pane_active_border_fg:-$tmux_conf_theme_pane_active_border}

  tmux_conf_theme_pane_border_bg=${tmux_conf_theme_pane_border_bg:-'default'}
  tmux_conf_theme_pane_active_border_bg=${tmux_conf_theme_pane_active_border_bg:-'default'}

  tmux setw -g pane-border-style "fg=$tmux_conf_theme_pane_border_fg,bg=$tmux_conf_theme_pane_border_bg" \; set -g pane-active-border-style "fg=$tmux_conf_theme_pane_active_border_fg,bg=$tmux_conf_theme_pane_active_border_bg"

  tmux_conf_theme_pane_indicator=${tmux_conf_theme_pane_indicator:-'#00afff'}               # light blue
  tmux_conf_theme_pane_active_indicator=${tmux_conf_theme_pane_active_indicator:-'#00afff'} # light blue

  tmux set -g display-panes-colour "$tmux_conf_theme_pane_indicator" \; set -g display-panes-active-colour "$tmux_conf_theme_pane_active_indicator"

  # -- status line -------------------------------------------------------

  tmux_conf_theme_left_separator_main=$(_decode_unicode_escapes "${tmux_conf_theme_left_separator_main-''}")
  tmux_conf_theme_left_separator_sub=$(_decode_unicode_escapes "${tmux_conf_theme_left_separator_sub-'|'}")
  tmux_conf_theme_right_separator_main=$(_decode_unicode_escapes "${tmux_conf_theme_right_separator_main-''}")
  tmux_conf_theme_right_separator_sub=$(_decode_unicode_escapes "${tmux_conf_theme_right_separator_sub-'|'}")

  tmux_conf_theme_message_fg=${tmux_conf_theme_message_fg:-'#000000'}   # black
  tmux_conf_theme_message_bg=${tmux_conf_theme_message_bg:-'#ffff00'}   # yellow
  tmux_conf_theme_message_attr=${tmux_conf_theme_message_attr:-'bold'}
  tmux set -g message-style "fg=$tmux_conf_theme_message_fg,bg=$tmux_conf_theme_message_bg,$tmux_conf_theme_message_attr"

  tmux_conf_theme_message_command_fg=${tmux_conf_theme_message_command_fg:-'#ffff00'} # yellow
  tmux_conf_theme_message_command_bg=${tmux_conf_theme_message_command_bg:-'#000000'} # black
  tmux_conf_theme_message_command_attr=${tmux_conf_theme_message_command_attr:-'bold'}
  tmux set -g message-command-style "fg=$tmux_conf_theme_message_command_fg,bg=$tmux_conf_theme_message_command_bg,$tmux_conf_theme_message_command_attr"

  tmux_conf_theme_mode_fg=${tmux_conf_theme_mode_fg:-'#000000'} # black
  tmux_conf_theme_mode_bg=${tmux_conf_theme_mode_bg:-'#ffff00'} # yellow
  tmux_conf_theme_mode_attr=${tmux_conf_theme_mode_attr:-'bold'}
  tmux setw -g mode-style "fg=$tmux_conf_theme_mode_fg,bg=$tmux_conf_theme_mode_bg,$tmux_conf_theme_mode_attr"

  tmux_conf_theme_status_fg=${tmux_conf_theme_status_fg:-'#8a8a8a'} # white
  tmux_conf_theme_status_bg=${tmux_conf_theme_status_bg:-'#080808'} # dark gray
  tmux_conf_theme_status_attr=${tmux_conf_theme_status_attr:-'none'}
  tmux  set -g status-style "fg=$tmux_conf_theme_status_fg,bg=$tmux_conf_theme_status_bg,$tmux_conf_theme_status_attr"        \;\
        set -g status-left-style "fg=$tmux_conf_theme_status_fg,bg=$tmux_conf_theme_status_bg,$tmux_conf_theme_status_attr"   \;\
        set -g status-right-style "fg=$tmux_conf_theme_status_fg,bg=$tmux_conf_theme_status_bg,$tmux_conf_theme_status_attr"

  tmux_conf_theme_terminal_title=${tmux_conf_theme_terminal_title:-'#h ❐ #S ● #I #W'}

  tmux_conf_theme_terminal_title=$(echo "$tmux_conf_theme_terminal_title" | sed \
    -e 's%#{username}%#(cat ~/.tmux/scripts/scripts.sh | sh -s _username #{pane_tty} false #D)%g' \
    -e 's%#{hostname}%#(cat ~/.tmux/scripts/scripts.sh | sh -s _hostname #{pane_tty} false #D)%g' \
    -e 's%#{username_ssh}%#(cat ~/.tmux/scripts/scripts.sh | sh -s _username #{pane_tty} true #D)%g' \
    -e 's%#{hostname_ssh}%#(cat ~/.tmux/scripts/scripts.sh | sh -s _hostname #{pane_tty} true #D)%g')
  tmux set -g set-titles-string "$(_decode_unicode_escapes "$tmux_conf_theme_terminal_title")"

  tmux_conf_theme_window_status_fg=${tmux_conf_theme_window_status_fg:-'#8a8a8a'} # white
  tmux_conf_theme_window_status_bg=${tmux_conf_theme_window_status_bg:-'#080808'} # dark gray
  tmux_conf_theme_window_status_attr=${tmux_conf_theme_window_status_attr:-'none'}
  tmux_conf_theme_window_status_format=${tmux_conf_theme_window_status_format:-'#I #W'}

  tmux_conf_theme_window_status_current_fg=${tmux_conf_theme_window_status_current_fg:-'#000000'} # black
  tmux_conf_theme_window_status_current_bg=${tmux_conf_theme_window_status_current_bg:-'#00afff'} # light blue
  tmux_conf_theme_window_status_current_attr=${tmux_conf_theme_window_status_current_attr:-'bold'}
  tmux_conf_theme_window_status_current_format=${tmux_conf_theme_window_status_current_format:-'#I #W'}
  if [ x"$(tmux show -g -v status-justify)" = x"right" ]; then
    tmux_conf_theme_window_status_current_format="#[fg=$tmux_conf_theme_window_status_current_bg,bg=$tmux_conf_theme_window_status_bg]$tmux_conf_theme_right_separator_main#[fg=$tmux_conf_theme_window_status_current_fg,bg=$tmux_conf_theme_window_status_current_bg,$tmux_conf_theme_window_status_current_attr] $tmux_conf_theme_window_status_current_format #[fg=$tmux_conf_theme_window_status_bg,bg=$tmux_conf_theme_window_status_current_bg,none]$tmux_conf_theme_right_separator_main"
  else
    tmux_conf_theme_window_status_current_format="#[fg=$tmux_conf_theme_window_status_bg,bg=$tmux_conf_theme_window_status_current_bg]$tmux_conf_theme_left_separator_main#[fg=$tmux_conf_theme_window_status_current_fg,bg=$tmux_conf_theme_window_status_current_bg,$tmux_conf_theme_window_status_current_attr] $tmux_conf_theme_window_status_current_format #[fg=$tmux_conf_theme_window_status_current_bg,bg=$tmux_conf_theme_status_bg,none]$tmux_conf_theme_left_separator_main"
  fi

  tmux_conf_theme_window_status_format=$(echo "$tmux_conf_theme_window_status_format" | sed \
    -e 's%#{username}%#(cat ~/.tmux/scripts/scripts.sh | sh -s _username #{pane_tty} false #D)%g' \
    -e 's%#{hostname}%#(cat ~/.tmux/scripts/scripts.sh | sh -s _hostname #{pane_tty} false #D)%g' \
    -e 's%#{username_ssh}%#(cat ~/.tmux/scripts/scripts.sh | sh -s _username #{pane_tty} true #D)%g' \
    -e 's%#{hostname_ssh}%#(cat ~/.tmux/scripts/scripts.sh | sh -s _hostname #{pane_tty} true #D)%g')
  tmux_conf_theme_window_status_current_format=$(echo "$tmux_conf_theme_window_status_current_format" | sed \
    -e 's%#{username}%#(cat ~/.tmux/scripts/scripts.sh | sh -s _username #{pane_tty} false #D)%g' \
    -e 's%#{hostname}%#(cat ~/.tmux/scripts/scripts.sh | sh -s _hostname #{pane_tty} false #D)%g' \
    -e 's%#{username_ssh}%#(cat ~/.tmux/scripts/scripts.sh | sh -s _username #{pane_tty} true #D)%g' \
    -e 's%#{hostname_ssh}%#(cat ~/.tmux/scripts/scripts.sh | sh -s _hostname #{pane_tty} true #D)%g')

  tmux  setw -g window-status-style "fg=$tmux_conf_theme_window_status_fg,bg=$tmux_conf_theme_window_status_bg,$tmux_conf_theme_window_status_attr" \;\
        setw -g window-status-format "$(_decode_unicode_escapes "$tmux_conf_theme_window_status_format")" \;\
        setw -g window-status-current-style "fg=$tmux_conf_theme_window_status_current_fg,bg=$tmux_conf_theme_window_status_current_bg,$tmux_conf_theme_window_status_current_attr" \;\
        setw -g window-status-current-format "$(_decode_unicode_escapes "$tmux_conf_theme_window_status_current_format")"

  tmux_conf_theme_window_status_activity_fg=${tmux_conf_theme_window_status_activity_fg:-'default'}
  tmux_conf_theme_window_status_activity_bg=${tmux_conf_theme_window_status_activity_bg:-'default'}
  tmux_conf_theme_window_status_activity_attr=${tmux_conf_theme_window_status_activity_attr:-'underscore'}
  tmux setw -g window-status-activity-style "fg=$tmux_conf_theme_window_status_activity_fg,bg=$tmux_conf_theme_window_status_activity_bg,$tmux_conf_theme_window_status_activity_attr"

  tmux_conf_theme_window_status_bell_fg=${tmux_conf_theme_window_status_bell_fg:-'#ffff00'} # yellow
  tmux_conf_theme_window_status_bell_bg=${tmux_conf_theme_window_status_bell_bg:-'default'}
  tmux_conf_theme_window_status_bell_attr=${tmux_conf_theme_window_status_bell_attr:-'blink,bold'}
  tmux setw -g window-status-bell-style "fg=$tmux_conf_theme_window_status_bell_fg,bg=$tmux_conf_theme_window_status_bell_bg,$tmux_conf_theme_window_status_bell_attr"

  tmux_conf_theme_window_status_last_fg=${tmux_conf_theme_window_status_last_fg:-'#00afff'} # light blue
  tmux_conf_theme_window_status_last_bg=${tmux_conf_theme_window_status_last_bg:-'default'}
  tmux_conf_theme_window_status_last_attr=${tmux_conf_theme_window_status_last_attr:-'none'}
  tmux setw -g window-status-last-style "fg=$tmux_conf_theme_window_status_last_fg,bg=$tmux_conf_theme_window_status_last_bg,$tmux_conf_theme_window_status_last_attr"

  # -- indicators

  tmux_conf_theme_attr='bold,blink'
  tmux_conf_theme_pairing='👓 '
  tmux_conf_theme_root='❗ '
  tmux_conf_theme_prefix='⌨ '
  tmux_conf_theme_synchronized='🔗 '

  # -- status left style

  tmux_conf_theme_status_left=${tmux_conf_theme_status_left-' ❐ #S '}
  tmux_conf_theme_status_left_fg=${tmux_conf_theme_status_left_fg:-'#000000,#e4e4e4,#e4e4e4'}  # black, white , white
  tmux_conf_theme_status_left_bg=${tmux_conf_theme_status_left_bg:-'#ffff00,#ff00af,#00afff'}  # yellow, pink, white blue
  tmux_conf_theme_status_left_attr=${tmux_conf_theme_status_left_attr:-'bold,none,none'}

  if [ -n "$tmux_conf_theme_status_left" ]; then
    status_left=$(awk \
                      -v fg_="$tmux_conf_theme_status_left_fg" \
                      -v bg_="$tmux_conf_theme_status_left_bg" \
                      -v attr_="$tmux_conf_theme_status_left_attr" \
                      -v mainsep="$tmux_conf_theme_left_separator_main" \
                      -v subsep="$tmux_conf_theme_left_separator_sub" '
      function subsplit(s,   l, i, a, r)
      {
        l = split(s, a, ",")
        for (i = 1; i <= l; ++i)
        {
          o = split(a[i], _, "(") - 1
          c = split(a[i], _, ")") - 1
          open += o - c
          o_ = split(a[i], _, "{") - 1
          c_ = split(a[i], _, "}") - 1
          open_ += o_ - c_
          o__ = split(a[i], _, "[") - 1
          c__ = split(a[i], _, "]") - 1
          open__ += o__ - c__

          if (i == l)
            r = sprintf("%s%s", r, a[i])
          else if (open || open_ || open__)
            r = sprintf("%s%s,", r, a[i])
          else
            r = sprintf("%s%s#[fg=%s,bg=%s,%s]%s", r, a[i], fg[j], bg[j], attr[j], subsep)
        }

        gsub(/#\[inherit\]/, sprintf("#[default]#[fg=%s,bg=%s,%s]", fg[j], bg[j], attr[j]), r)
        return r
      }
      BEGIN {
        FS = "|"
        l1 = split(fg_, fg, ",")
        l2 = split(bg_, bg, ",")
        l3 = split(attr_, attr, ",")
        l = l1 < l2 ? (l1 < l3 ? l1 : l3) : (l2 < l3 ? l2 : l3)
      }
      {
        for (i = j = 1; i <= NF; ++i)
        {
          if (open || open_ || open__)
            printf "|%s", subsplit($i)
          else
          {
            if (i > 1)
              printf "#[fg=%s,bg=%s,none]%s#[fg=%s,bg=%s,%s]%s", bg[j_], bg[j], mainsep, fg[j], bg[j], attr[j], subsplit($i)
            else
              printf "#[fg=%s,bg=%s,%s]%s", fg[j], bg[j], attr[j], subsplit($i)
          }

          if (!open && !open_ && !open__)
          {
            j_ = j
            j = j % l + 1
          }
        }
        printf "#[fg=%s,bg=%s,none]%s", bg[j_], "default", mainsep
      }' << EOF
$tmux_conf_theme_status_left
EOF
    )
  fi

  status_left="$status_left "

  # -- status right style

  tmux_conf_theme_status_right=${tmux_conf_theme_status_right-'#{pairing}#{prefix} #{battery_status} #{battery_bar} #{battery_percentage} , %R , %d %b | #{username} | #{hostname} '}
  tmux_conf_theme_status_right_fg=${tmux_conf_theme_status_right_fg:-'#8a8a8a,#e4e4e4,#000000'} # light gray, white, black
  tmux_conf_theme_status_right_bg=${tmux_conf_theme_status_right_bg:-'#080808,#d70000,#e4e4e4'} # dark gray, red, white
  tmux_conf_theme_status_right_attr=${tmux_conf_theme_status_right_attr:-'none,none,bold'}

  tmux_conf_theme_status_right=$(echo "$tmux_conf_theme_status_right" | sed \
    -e "s/#{pairing}/#[$tmux_conf_theme_attr]#{?session_many_attached,$tmux_conf_theme_pairing,}/g")

  tmux_conf_theme_status_right=$(echo "$tmux_conf_theme_status_right" | sed \
    -e "s/#{prefix}/#[$tmux_conf_theme_attr]#{?client_prefix,$tmux_conf_theme_prefix,}/g")

  # tmux_conf_theme_status_right=$(echo "$tmux_conf_theme_status_right" | sed \
  #   -e "s%#{root}%#[$tmux_conf_theme_attr]#(cat ~/.tmux/scripts/scripts.sh | sh -s _root #{pane_tty} #D)#[inherit]%g")
  tmux_conf_theme_status_right=$(echo "$tmux_conf_theme_status_right" | sed \
    -e "s%#{root}%#[$tmux_conf_theme_attr]#(cat ~/.tmux/scripts/scripts.sh | sh -s _root #{pane_tty} #D)#[inherit]%g")


  tmux_conf_theme_status_right=$(echo "$tmux_conf_theme_status_right" | sed \
    -e "s%#{synchronized}%#[$tmux_conf_theme_attr]#{?pane_synchronized,$tmux_conf_theme_synchronized,}%g")

  if [ -n "$tmux_conf_theme_status_right" ]; then
    status_right=$(awk \
                      -v fg_="$tmux_conf_theme_status_right_fg" \
                      -v bg_="$tmux_conf_theme_status_right_bg" \
                      -v attr_="$tmux_conf_theme_status_right_attr" \
                      -v mainsep="$tmux_conf_theme_right_separator_main" \
                      -v subsep="$tmux_conf_theme_right_separator_sub" '
      function subsplit(s,   l, i, a, r)
      {
        l = split(s, a, ",")
        for (i = 1; i <= l; ++i)
        {
          o = split(a[i], _, "(") - 1
          c = split(a[i], _, ")") - 1
          open += o - c
          o_ = split(a[i], _, "{") - 1
          c_ = split(a[i], _, "}") - 1
          open_ += o_ - c_
          o__ = split(a[i], _, "[") - 1
          c__ = split(a[i], _, "]") - 1
          open__ += o__ - c__

          if (i == l)
            r = sprintf("%s%s", r, a[i])
          else if (open || open_ || open__)
            r = sprintf("%s%s,", r, a[i])
          else
            r = sprintf("%s%s#[fg=%s,bg=%s,%s]%s", r, a[i], fg[j], bg[j], attr[j], subsep)
        }

        gsub(/#\[inherit\]/, sprintf("#[default]#[fg=%s,bg=%s,%s]", fg[j], bg[j], attr[j]), r)
        return r
      }
      BEGIN {
        FS = "|"
        l1 = split(fg_, fg, ",")
        l2 = split(bg_, bg, ",")
        l3 = split(attr_, attr, ",")
        l = l1 < l2 ? (l1 < l3 ? l1 : l3) : (l2 < l3 ? l2 : l3)
      }
      {
        for (i = j = 1; i <= NF; ++i)
        {
          if (open_ || open || open__)
            printf "|%s", subsplit($i)
          else
            printf "#[fg=%s,bg=%s,none]%s#[fg=%s,bg=%s,%s]%s", bg[j], (i == 1) ? "default" : bg[j_], mainsep, fg[j], bg[j], attr[j], subsplit($i)

          if (!open && !open_ && !open__)
          {
            j_ = j
            j = j % l + 1
          }
        }
      }' << EOF
$tmux_conf_theme_status_right
EOF
    )
  fi

  # -- variables

  tmux set -g '@root' "$tmux_conf_theme_root"

  tmux_conf_battery_bar_symbol_full='◼'
  tmux_conf_battery_bar_symbol_empty='◻'
  tmux_conf_battery_bar_length='auto'
  tmux_conf_battery_hbar_palette='gradient'
  tmux_conf_battery_vbar_palette='gradient'
  tmux_conf_battery_status_charging='↑'
  tmux_conf_battery_status_discharging='↓'


  status_right=$(echo "$status_right" | sed -E \
    -e 's/#\{(\?)?battery_vbar/#\{\1@battery_vbar/g' \
    -e 's/#\{(\?)?battery_status/#\{\1@battery_status/g' \
    -e 's/#\{(\?)?battery_percentage/#\{\1@battery_percentage/g')

  tmux  set -g '@battery_bar_symbol_full' "$(_decode_unicode_escapes "$tmux_conf_battery_bar_symbol_full")" \;\
        set -g '@battery_bar_symbol_empty' "$(_decode_unicode_escapes "$tmux_conf_battery_bar_symbol_empty")" \;\
        set -g '@battery_bar_length' "$tmux_conf_battery_bar_length" \;\
        set -g '@battery_hbar_palette' "$tmux_conf_battery_hbar_palette" \;\
        set -g '@battery_vbar_palette' "$tmux_conf_battery_vbar_palette" \;\
        set -g '@battery_status_charging' "$(_decode_unicode_escapes "$tmux_conf_battery_status_charging")" \;\
        set -g '@battery_status_discharging' "$(_decode_unicode_escapes "$tmux_conf_battery_status_discharging")"
  status_right="#(cat ~/.tmux/scripts/scripts.sh | sh -s _battery)$status_right"

  status_right=$(echo "$status_right" | sed \
    -e 's%#{username}%#(cat ~/.tmux/scripts/scripts.sh | sh -s _username #{pane_tty} false #D)%g' \
    -e 's%#{hostname}%#(cat ~/.tmux/scripts/scripts.sh | sh -s _hostname #{pane_tty} false #D)%g' \
    -e 's%#{username_ssh}%#(cat ~/.tmux/scripts/scripts.sh | sh -s _username #{pane_tty} true #D)%g' \
    -e 's%#{hostname_ssh}%#(cat ~/.tmux/scripts/scripts.sh | sh -s _hostname #{pane_tty} true #D)%g')

  tmux set -g status-left-length 1000 \; set -g status-left "$(_decode_unicode_escapes "$status_left")" \;\
       set -g status-right-length 1000 \; set -g status-right "$(_decode_unicode_escapes "$status_right")"
}

_apply_configuration() {

  # see https://github.com/ChrisJohnsen/tmux-MacOSX-pasteboard
  if command -v reattach-to-user-namespace > /dev/null 2>&1; then
    default_shell="$(tmux show -gv default-shell)"
    tmux set -g default-command "exec $default_shell... 2> /dev/null & reattach-to-user-namespace -l $default_shell"
  fi

  _apply_theme
  for name in $(printenv | grep -E -o '^tmux_conf_[^=]+'); do tmux setenv -gu "$name"; done;
}


"$@"
