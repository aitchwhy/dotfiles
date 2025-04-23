-- require("full-border"):setup()
require("full-border"):setup({
	-- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
	type = ui.Border.ROUNDED,
})

require("mactag"):setup({
	-- Keys used to add or remove tags
	keys = {
		r = "Red",
		o = "Orange",
		y = "Yellow",
		g = "Green",
		b = "Blue",
		p = "Purple",
	},
	-- Colors used to display tags
	colors = {
		Red = "#ee7b70",
		Orange = "#f5bd5c",
		Yellow = "#fbe764",
		Green = "#91fc87",
		Blue = "#5fa3f8",
		Purple = "#cb88f8",
	},
})
-- require("starship"):setup()

require("mime-ext"):setup({
	-- Expand the existing filename database (lowercase), for example:
	with_files = {
		makefile = "text/makefile",
	},

	-- Expand the existing extension database (lowercase), for example:
	with_exts = {
		mk = "text/makefile",
	},

	-- If the mime-type is not in both filename and extension databases,
	-- then fallback to Yazi's preset `mime` plugin, which uses `file(1)`
	fallback_file1 = false,
})

-- require("folder-rules"):setup(Status:children_add(function(self)
-- 	local h = self._current.hovered
-- 	if h and h.link_to then
-- 		return " -> " .. tostring(h.link_to)
-- 	else
-- 		return ""
-- 	end
-- end, 3300, Status.LEFT))

require("folder-rules"):setup()

require("bunny"):setup({
	hops = {
		{ key = "r", path = "/" },
		{ key = "v", path = "/var" },
		{ key = "t", path = "/tmp" },
		{ key = "n", path = "/nix/store", desc = "Nix store" },
		{ key = { "h", "h" }, path = "~", desc = "Home" },
		{ key = { "h", "m" }, path = "~/Music", desc = "Music" },
		{ key = { "h", "d" }, path = "~/Documents", desc = "Documents" },
		{ key = { "h", "k" }, path = "~/Desktop", desc = "Desktop" },
		{ key = "c", path = "~/.config", desc = "Config files" },
		{ key = { "l", "s" }, path = "~/.local/share", desc = "Local share" },
		{ key = { "l", "b" }, path = "~/.local/bin", desc = "Local bin" },
		{ key = { "l", "t" }, path = "~/.local/state", desc = "Local state" },
		-- key and path attributes are required, desc is optional
	},
	desc_strategy = "path", -- If desc isn't present, use "path" or "filename", default is "path"
	notify = false, -- Notify after hopping, default is false
	fuzzy_cmd = "fzf", -- Fuzzy searching command, default is "fzf"
})

require("copy-file-contents"):setup({
	append_char = "\n",
	notification = true,
})

-- ~/.config/yazi/init.lua for Linux and macOS
-- %AppData%\yazi\config\init.lua for Windows

require("starship"):setup({
	-- Hide flags (such as filter, find and search). This is recommended for starship themes which
	-- are intended to go across the entire width of the terminal.
	hide_flags = false, -- Default: false
	-- Whether to place flags after the starship prompt. False means the flags will be placed before the prompt.
	flags_after_prompt = true, -- Default: true
	-- Custom starship configuration file to use
	config_file = "~/.config/starship_full.toml", -- Default: nil
})

-- -- Using the default configuration
-- require("augment-command"):setup({
-- 	prompt = false,
-- 	default_item_group_for_prompt = "hovered",
-- 	smart_enter = true,
-- 	smart_paste = false,
-- 	smart_tab_create = false,
-- 	smart_tab_switch = false,
-- 	confirm_on_quit = true,
-- 	open_file_after_creation = false,
-- 	enter_directory_after_creation = false,
-- 	use_default_create_behaviour = false,
-- 	enter_archives = true,
-- 	extract_retries = 3,
-- 	recursively_extract_archives = true,
-- 	preserve_file_permissions = false,
-- 	must_have_hovered_item = true,
-- 	skip_single_subdirectory_on_enter = true,
-- 	skip_single_subdirectory_on_leave = true,
-- 	smooth_scrolling = false,
-- 	scroll_delay = 0.02,
-- 	wraparound_file_navigation = false,
-- })
