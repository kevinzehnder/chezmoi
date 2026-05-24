return {
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		config = function ()
			local languages = {
				"bash",
				"c",
				"go",
				"diff",
				"html",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"query",
				"vim",
				"vimdoc",
			}

			require("nvim-treesitter.configs").setup({
				ensure_installed = languages,
				auto_install = true,
				highlight = { enable = true },
				indent = { enable = true },
				parser_install_dir = vim.fn.stdpath("data") .. "/site",
			})
		end,
	},
}
