local seen = {}
for lnum = 1, vim.fn.line("$") do
	local line = vim.fn.getline(lnum)
	if line:match("^brew ") then
		if seen[line] then
			vim.cmd(string.format("%dd", lnum))
		else
			seen[line] = true
		end
	end
end
