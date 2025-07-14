--- helper functions
--- Check if a file or directory exists in this path
function exists(file)
	local ok, err, code = os.rename(file, file)
	if not ok then
		if code == 13 then
			-- Permission denied, but it exists
			return true
		end
	end
	return ok, err
end

--- Check if a directory exists in this path
function isdir(path)
	-- "/" works on both Unix and Windows
	return exists(path .. "/")
end

-- adaptive colorscheme
local function set_adaptive_colorscheme()
	local lightmode_file = os.getenv("HOME") .. "/.lightmode"
	if exists(lightmode_file) then
		vim.o.background = "light"
		vim.cmd("colorscheme solarized")
		vim.api.nvim_set_hl(0, "CursorLine", { bg = "#ffd8cb" })
	else
		vim.o.background = "dark"
		vim.cmd("colorscheme tokyonight")
	end
end

-- Initial setup when Neovim starts
set_adaptive_colorscheme()

vim.cmd("highlight TSFunction gui=bold")

-- Command to switch to light mode
vim.api.nvim_create_user_command("Light", function ()
	vim.o.background = "light"
	vim.cmd("colorscheme solarized")
	vim.api.nvim_set_hl(0, "CursorLine", { bg = "#ffd8cb" })
end, {
	desc = "Switch to light mode colorscheme",
})

-- Command to switch to light mode
vim.api.nvim_create_user_command("Dark", function ()
	vim.o.background = "dark"
	vim.cmd("colorscheme tokyonight")
end, {
	desc = "Switch to light mode colorscheme",
})
