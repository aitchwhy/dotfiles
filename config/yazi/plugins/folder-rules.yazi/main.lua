-- Folder-specific rules plugin with git branch support
-- Provides folder-specific sorting rules and git branch display for status bar

local function setup()
	-- Subscribe to directory changes for folder-specific rules
	ps.sub("cd", function()
		local cwd = cx.active.current.cwd
		if cwd:ends_with("Downloads") then
			ya.mgr_emit("sort", { "mtime", reverse = true, dir_first = false })
		else
			ya.mgr_emit("sort", { "alphabetical", reverse = false, dir_first = true })
		end
	end)
end

-- Git branch for status bar display
-- Can be called from Header:children() in theme.lua
local function git_branch()
	local cwd = cx.active.current.cwd
	local child = Command("git")
		:cwd(tostring(cwd))
		:args({ "rev-parse", "--abbrev-ref", "HEAD" })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()

	if child and child.status and child.status.success then
		local branch = child.stdout:gsub("%s+$", "")
		if branch ~= "" then
			return ui.Line(" " .. branch)
		end
	end
	return ui.Line("")
end

return { setup = setup, git_branch = git_branch }
