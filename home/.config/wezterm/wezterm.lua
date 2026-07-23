local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.color_scheme = "rose-pine-moon"
config.font = wezterm.font("Hack Nerd Font")
config.font_size = 15.0
config.window_background_opacity = 0.8
config.macos_window_background_blur = 50
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"

-- Cmd+C copies only when WezTerm itself has a selection. Inside a
-- mouse-capturing TUI (Claude Code, herdr) the visible highlight belongs to
-- the app, which has already copied it; default Cmd+C would copy WezTerm's
-- empty selection and wipe the clipboard.
config.keys = {
	{
		key = "c",
		mods = "CMD",
		action = wezterm.action_callback(function(window, pane)
			if window:get_selection_text_for_pane(pane) ~= "" then
				window:perform_action(wezterm.action.CopyTo("Clipboard"), pane)
			end
		end),
	},
}

return config
