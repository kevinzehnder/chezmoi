return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
		"MunifTanjim/nui.nvim",
		-- {"3rd/image.nvim", opts = {}}, -- Optional image support in preview window: See `# Preview Mode` for more information
	},
	lazy = false, -- neo-tree will lazily load itself
	---@module "neo-tree"
	---@type neotree.Config?
	opts = {
		filesystem = {
			follow_current_file = {
				enabled = true,
				leave_dirs_open = true
			},
		},
		buffers = {
			follow_current_file = {
				enabled = true, -- This will find and focus the file in the active buffer every time
				leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
			},
		},
	},
}




-- return {
-- 	{
-- 		"nvim-tree/nvim-tree.lua",
-- 		opts = {
-- 			actions = {
-- 				open_file = {
-- 					resize_window = true,
-- 				}
-- 			},
-- 			filters = {
-- 				dotfiles = true,
-- 			},
-- 			diagnostics = {
-- 				enable = true,
-- 				show_on_dirs = false,
-- 				show_on_open_dirs = true,
-- 				debounce_delay = 50,
-- 				severity = {
-- 					min = vim.diagnostic.severity.HINT,
-- 					max = vim.diagnostic.severity.ERROR,
-- 				},
-- 				icons = {
-- 					hint = "",
-- 					info = "",
-- 					warning = "",
-- 					error = "",
-- 				},
-- 			},
-- 			modified = {
-- 				enable = false,
-- 				show_on_dirs = true,
-- 				show_on_open_dirs = true,
-- 			},
-- 			view = {
-- 				centralize_selection = false,
-- 				cursorline = true,
-- 				debounce_delay = 15,
-- 				side = "left",
-- 				preserve_window_proportions = false,
-- 				number = false,
-- 				relativenumber = false,
-- 				signcolumn = "yes",
-- 				width = 40,
-- 			},
--
-- 			update_focused_file = {
-- 				enable = true,
-- 				update_root = {
-- 					enable = false,
-- 					ignore_list = {},
-- 				},
-- 				exclude = false,
-- 			},
-- 		},
-- 	},
-- }
