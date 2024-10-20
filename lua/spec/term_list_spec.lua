local mock = require("luassert.mock")
local assert = require("luassert")

local default_config = {
	type_opts = {
		horizontal = { location = "rightbelow", split_ratio = 0.3, list_width = 15 },
		vertical = { location = "rightbelow", split_ratio = 0.5, list_width = 15 },
		floating = {
			relative = "editor",
			row = 0.3,
			col = 0.25,
			width = 0.5,
			height = 0.4,
			border = "single",
			list_width = 15,
		},
	},
	behavior = {
		autoclose_on_quit = {
			enabled = false,
			confirm = true,
		},
		close_on_exit = true,
		auto_insert = true,
	},
	shell = "/bin/bash",
}

describe("term_list", function()
	local term_list = require("simpleterm.term_list")
	local icon = "icon"
	package.loaded["nvim-web-devicons"] = {
		get_icon = function()
			return icon
		end,
	}

	after_each(function()
		mock.revert(vim.api)
	end)

	describe("render_term_names", function()
		it("renders terminal names and highlights the selected one", function()
			local api_mock = mock(vim.api, true)

			local win = 1
			local buf = 1
			local term1 = { id = 1, buf = 1, open = false, type = type, shell = default_config.shell }
			local term2 = { id = 2, buf = 2, open = false, type = type, shell = default_config.shell }
			local term3 = { id = 3, buf = 3, open = true, type = type, shell = default_config.shell }
			local term4 = { id = 4, buf = 4, open = false, type = type, shell = default_config.shell }
			local terms = { [1] = term1, [2] = term2, [3] = term3, [4] = term4 }
			local lines = {
				"  " .. icon .. "  bash",
				"  " .. icon .. "  bash",
				"> " .. icon .. "  bash",
				"  " .. icon .. "  bash",
			}

			api_mock.nvim_create_buf.returns(buf)
			api_mock.nvim_buf_line_count.returns(4)

			term_list.render_term_names(win, terms)

			assert.stub(vim.api.nvim_buf_set_lines).was_called_with(buf, 0, -1, false, lines)
			assert.stub(vim.api.nvim_buf_line_count).was_called_with(buf)
			assert.stub(vim.api.nvim_buf_add_highlight).was_called(4)
			assert.stub(vim.api.nvim_buf_add_highlight).was_called_with(buf, -1, "LineNr", 0, 0, -1)
			assert.stub(vim.api.nvim_buf_add_highlight).was_called_with(buf, -1, "LineNr", 1, 0, -1)
			assert.stub(vim.api.nvim_buf_add_highlight).was_called_with(buf, -1, "CursorLineNr", 2, 0, -1)
			assert.stub(vim.api.nvim_buf_add_highlight).was_called_with(buf, -1, "LineNr", 3, 0, -1)
			assert.stub(vim.api.nvim_set_option_value).was_called_with("modifiable", false, { buf = buf })
			assert.stub(vim.api.nvim_win_set_buf).was_called_with(win, buf)
		end)
	end)
end)
