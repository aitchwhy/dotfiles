-- Setup the visual border with rounded corners
require("full-border"):setup({
	type = ui.Border.ROUNDED,
	-- Adjust the border style to match Tokyo Night theme
	style = {
		fg = "#7aa2f7", -- Blue accent from Tokyo Night
		bg = "#1a1b26", -- Background from Tokyo Night
	},
})

-- Setup macOS tags with Tokyo Night-inspired colors
require("mactag"):setup({
	keys = {
		r = "Red",
		o = "Orange",
		y = "Yellow",
		g = "Green",
		b = "Blue",
		p = "Purple",
		w = "White",
	},
	colors = {
		-- Tokyo Night-inspired color palette
		Red = "#f7768e", -- Red from Tokyo Night
		Orange = "#ff9e64", -- Orange from Tokyo Night
		Yellow = "#e0af68", -- Yellow from Tokyo Night
		Green = "#9ece6a", -- Green from Tokyo Night
		Blue = "#7aa2f7", -- Blue from Tokyo Night
		Purple = "#bb9af7", -- Purple from Tokyo Night
		White = "#c0caf5", -- Foreground from Tokyo Night
	},
	-- Display tag indicators in status line
	show_in_status = true,
})
-- Enhanced Starship integration with Tokyo Night theme
require("starship"):setup({
	hide_flags = false,
	flags_after_prompt = true,
	config_file = "~/.config/starship/starship.toml",
	-- Enable Tokyo Night theme
	theme = "tokyo-night",
})

-- Enhanced mime type detection
require("mime-ext"):setup({
	-- Expand the existing filename database (lowercase)
	with_files = {
		makefile = "text/makefile",
		dockerfile = "text/dockerfile",
		justfile = "text/justfile",
		["package.json"] = "application/json",
		[".gitignore"] = "text/plain",
		[".env"] = "text/plain",
	},

	-- Expand the existing extension database (lowercase)
	with_exts = {
		mk = "text/makefile",
		ts = "text/typescript",
		tsx = "text/typescript-jsx",
		jsx = "text/jsx",
		vue = "text/vue",
		svelte = "text/svelte",
		md = "text/markdown",
		toml = "text/toml",
		conf = "text/config",
	},

	-- If the mime-type is not in both filename and extension databases,
	-- then fallback to Yazi's preset `mime` plugin, which uses `file(1)`
	fallback_file1 = false,
})

-- Enhanced folder rules setup with symlink display in status bar
require("folder-rules"):setup({
	-- Better display of symlinks in status bar
	show_symlinks = true,

	-- Special rules for specific folders
	rules = {
		["~/dotfiles"] = {
			-- Special layout for dotfiles repository
			layout = { 1, 3, 4 }, -- More space for the file listing (fixed array syntax)
			show_hidden = true, -- Always show hidden files
		},
		["~/Downloads"] = {
			-- Sort by modification time in Downloads folder
			sort_by = "mtime",
			sort_reverse = true, -- Most recent first
		},
		["~/.config"] = {
			-- For configuration directories
			show_hidden = true, -- Always show hidden files
		},
	},

	-- Add custom status bar elements
	status_elements = {
		-- Show arrow to symlink target when hovering a symlink
		{
			fn = function(self)
				local h = self._current.hovered
				if h and h.link_to then
					return " → " .. tostring(h.link_to)
				else
					return ""
				end
			end,
			priority = 3300,
			position = Status.LEFT,
		},
		-- Show git branch/status when in git repository
		{
			fn = function()
				local result = ya.syscall("git", { "rev-parse", "--abbrev-ref", "HEAD" }, { cwd = ya.cwd })
				if result.success then
					return " " .. result.stdout:gsub("%s+$", "")
				else
					return ""
				end
			end,
			priority = 3400,
			position = Status.RIGHT,
		},
	},
})
--
-- Enhanced bunny setup for quick jumps to common directories
require("bunny"):setup({
	hops = {
		-- Root directories
		{ key = "r", path = "/", desc = "Root" },
		{ key = "v", path = "/var", desc = "Var" },
		{ key = "t", path = "/tmp", desc = "Temp" },

		-- Nix store (if applicable)
		{ key = "n", path = "/nix/store", desc = "Nix store" },

		-- Home directory and subdirectories
		{ key = { "h", "h" }, path = "~", desc = "Home" },
		{ key = { "h", "d" }, path = "~/Documents", desc = "Documents" },
		{ key = { "h", "D" }, path = "~/Downloads", desc = "Downloads" },
		{ key = { "h", "m" }, path = "~/Music", desc = "Music" },
		{ key = { "h", "p" }, path = "~/Pictures", desc = "Pictures" },
		{ key = { "h", "v" }, path = "~/Videos", desc = "Videos" },
		{ key = { "h", "k" }, path = "~/Desktop", desc = "Desktop" },

		-- Configuration and local directories
		{ key = "c", path = "~/.config", desc = "Config files" },
		{ key = "d", path = "~/dotfiles", desc = "Dotfiles repo" },
		{ key = { "l", "s" }, path = "~/.local/share", desc = "Local share" },
		{ key = { "l", "b" }, path = "~/.local/bin", desc = "Local bin" },
		{ key = { "l", "t" }, path = "~/.local/state", desc = "Local state" },

		-- Development directories
		{ key = { "g", "h" }, path = "~/src", desc = "Source code" },
		{ key = { "g", "r" }, path = "~/repos", desc = "Git repositories" },
		{ key = { "g", "p" }, path = "~/projects", desc = "Projects" },
	},
	desc_strategy = "desc", -- Use the description field when available
	notify = true, -- Show notification after hopping
	fuzzy_cmd = "fzf", -- Use fzf for fuzzy searching
	fuzzy_opts = "--reverse --border --height 40%", -- FZF options
})

-- Enhanced copy file contents with improved notification
require("copy-file-contents"):setup({
	append_char = "\n",
	notification = true,
	-- Copy formatting based on file type
	format_by_extension = {
		md = "markdown",
		js = "javascript",
		ts = "typescript",
		py = "python",
		lua = "lua",
	},
})

-- -- Smart paste implementation for better paste behavior
-- require("smart-paste"):setup({
-- 	-- Paste files into directories, create parent directories if needed
-- 	create_parent_dirs = true,
-- 	-- Ask for confirmation before overwriting
-- 	confirm_overwrite = true,
-- 	-- Show success notification
-- 	show_notification = true,
-- })

-- -- Smart jump-to-char for faster navigation
-- require("jump-to-char"):setup({
-- 	-- Highlight options
-- 	highlight = true,
-- 	highlight_color = "#7aa2f7", -- Tokyo Night blue
-- 	-- Character display options
-- 	char_case_sensitive = false,
-- 	char_display_time = 1000,
-- })

-- Projects plugin for better project management
require("projects"):setup({
	-- Auto-save current project on exit
	auto_save = true,
	-- Path where projects are stored
	projects_dir = "~/.config/yazi/projects",
	-- Max number of projects to store
	max_projects = 20,
	-- Include tabs in projects
	include_tabs = true,
})

-- -- Set up rich preview for better file previews
-- require("rich-preview"):setup({
-- 	-- Maximum file size for rich preview
-- 	max_file_size = "2MB",
-- 	-- Default width
-- 	width = 80,
-- 	-- Tokyo Night theme
-- 	-- theme = "tokyo-night",
-- })

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
