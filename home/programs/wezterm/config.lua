local wezterm = require 'wezterm'
local config = wezterm.config_builder() -- This line is crucial!

config.automatically_reload_config = true
config.scrollback_lines = 100000
config.switch_to_last_active_tab_when_closing_tab = true

-- Leader is the same as my old tmux prefix
config.leader = { key = 'F19', mods = "NONE", timeout_milliseconds = 2000 }

wezterm.on('update-right-status', function(window, pane)
  window:set_right_status(window:active_workspace())
end)

config.debug_key_events = true
config.keys = {
  -- Goto beginning of the line
  {
    key = "LeftArrow",
    mods = "CMD",
    action = wezterm.action.SendKey{key="a", mods="CTRL"},
  },
  -- Goto ending of the line
  {
    key = "RightArrow",
    mods = "CMD",
    action = wezterm.action.SendKey{key="e", mods="CTRL"},
  },

  -- Alt + Left → send ESC then 'b' (back one word)
  {
    key = "LeftArrow",
    mods = "ALT",
    action = wezterm.action.SendString("\x1bb"),
  },
  -- Alt + Right → send ESC then 'f' (forward one word)
  {
    key = "RightArrow",
    mods = "ALT",
    action = wezterm.action.SendString("\x1bf"),
  },

  -- splitting
  {
    mods   = "LEADER",
    key    = "-",
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' }
  },
  {
    mods   = "LEADER",
    key    = "_",
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' }
  },

  -- Move between panes using Alt + Arrow
  {
    key = "LeftArrow",
    mods = "LEADER",
    action = wezterm.action.ActivatePaneDirection("Left"),
  },
  {
    key = "RightArrow",
    mods = "LEADER",
    action = wezterm.action.ActivatePaneDirection("Right"),
  },
  {
    key = "UpArrow",
    mods = "LEADER",
    action = wezterm.action.ActivatePaneDirection("Up"),
  },
  {
    key = "DownArrow",
    mods = "LEADER",
    action = wezterm.action.ActivatePaneDirection("Down"),
  },

  -- zoom active pane
  {
    mods = 'LEADER',
    key = 'z',
    action = wezterm.action.TogglePaneZoomState
  },
  -- rotate panes
  {
    mods = "LEADER",
    key = "Space",
    action = wezterm.action.RotatePanes "Clockwise"
  },

  -- Tab naming
  {
    key = 'n',
    mods = 'LEADER',
    action = wezterm.action.PromptInputLine {
      description = 'Enter new name for tab',
      action = wezterm.action_callback(
        function(window, pane, line)
          if line then
            window:active_tab():set_title(line)
          end
        end
      ),
    },
  },
  -- Tab navigation
  {
    mods = 'LEADER',
    key = 'w',
    action = wezterm.action.ShowTabNavigator,
  },
  -- Close pane
  {
    key = 'd',
    mods = 'LEADER',
    action = wezterm.action.CloseCurrentPane{ confirm = true },
  },

  -- ----------------------------------------------------------------
  -- Workspaces
  --
  -- These are roughly equivalent to tmux sessions.
  -- ----------------------------------------------------------------

  -- Attach to muxer
  {
      key = 'a',
      mods = 'LEADER',
      action = wezterm.action.AttachDomain 'unix',
  },

  -- Rename current session; analagous to command in tmux
  {
      key = '$',
      mods = 'LEADER|SHIFT',
      action = wezterm.action.PromptInputLine {
          description = 'Enter new name for session',
          action = wezterm.action_callback(
              function(window, pane, line)
                  if line then
                      mux.rename_workspace(
                          window:mux_window():get_workspace(),
                          line
                      )
                  end
              end
          ),
      },
  },

  -- Session (workspaces) manager bindings

  -- Show workspaces and pick one
  {
    key = 's',
    mods = 'LEADER',
    action = wezterm.action.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' },

  },

  -- Prompt for a name to use for a new workspace and switch to it.
  {
    key = 'C',
    mods = 'LEADER|SHIFT',
    action = wezterm.action.PromptInputLine {
      description = wezterm.format {
        { Attribute = { Intensity = 'Bold' } },
        { Foreground = { AnsiColor = 'Fuchsia' } },
        { Text = 'Enter name for new workspace' },
      },
      action = wezterm.action_callback(function(window, pane, line)
        -- line will be `nil` if they hit escape without entering anything
        -- An empty string if they just hit enter
        -- Or the actual line of text they wrote
        if line then
          window:perform_action(
            wezterm.action.SwitchToWorkspace {
              name = line,
            },
            pane
          )
        end
      end),
    },
  },
}


config.inactive_pane_hsb = {
  brightness = 0.6,
}


-- Make it look like tabs, with better GUI controls
config.use_fancy_tab_bar = true
-- Don't let any individual tab name take too much room
config.tab_max_width = 32
config.colors = {
  split = "#0000FF",
  tab_bar = {
    active_tab = {
      -- I use a solarized dark theme; this gives a teal background to the active tab
      fg_color = '#073642',
      bg_color = '#2aa198'
    }
  }
}

-- Setup muxing by default
config.unix_domains = {
  {
    name = 'unix',
  },
}


config.default_gui_startup_args = { 'connect', 'unix' }


return config;
