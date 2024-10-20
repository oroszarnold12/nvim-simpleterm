local mock = require("luassert.mock")
local stub = require("luassert.stub")
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

describe("win_util", function()
	local win_util = require("simpleterm.win_util")
	local type = "horizontal"
	local floating_type = "floating"
	local vertical_type = "vertical"
	local win_height = 900
	local win_width = 500

	after_each(function()
		win_util._wins = {}

		mock.revert(vim.api)
	end)

	describe("create_or_get_win", function()
		it("creates a new window if does not exist", function()
			local api_mock = mock(vim.api, true)

			local term_win = 1
			local list_win = 2
			local term_win_opts = { split = "below", height = 270 }
			local list_win_opts = { split = "right", width = 15 }
			local win = { term_win = term_win, list_win = list_win }

			api_mock.nvim_win_get_height.returns(win_height)
			api_mock.nvim_open_win.on_call_with(0, true, term_win_opts).returns(term_win)
			api_mock.nvim_open_win.on_call_with(0, false, list_win_opts).returns(list_win)

			local created_win = win_util.create_or_get_win(type, default_config)

			assert.stub(vim.api.nvim_open_win).was_called_with(0, true, term_win_opts)
			assert.stub(vim.api.nvim_open_win).was_called_with(0, false, list_win_opts)
			assert.stub(vim.api.nvim_win_get_height).was_called_with(0)
			assert.stub(vim.api.nvim_set_option_value).was_called_with("number", false, { win = list_win })
			assert.stub(vim.api.nvim_set_option_value).was_called_with("relativenumber", false, { win = list_win })
			assert.stub(vim.api.nvim_set_option_value).was_called_with("cursorline", false, { win = list_win })
			assert.are.same({ [type] = win }, win_util._wins)
			assert.are.same(win, created_win)
		end)

		it("returns existing window", function()
			mock(vim.api, true)

			local term_win = 1
			local list_win = 2
			local win = { term_win = term_win, list_win = list_win }

			win_util._wins[type] = win

			local returned_win = win_util.create_or_get_win(type, default_config)

			assert.stub(vim.api.nvim_open_win).was_not_called()
			assert.stub(vim.api.nvim_win_get_height).was_not_called()
			assert.stub(vim.api.nvim_set_option_value).was_not_called()
			assert.are.same({ [type] = win }, win_util._wins)
			assert.are.same(win, returned_win)
		end)

		it("creates new vertical window", function()
			local api_mock = mock(vim.api, true)

			local term_win = 1
			local list_win = 2
			local term_win_opts = { split = "right", width = 250 }
			local list_win_opts = { split = "right", width = 15 }
			local win = { term_win = term_win, list_win = list_win }

			api_mock.nvim_win_get_width.returns(win_width)
			api_mock.nvim_open_win.on_call_with(0, true, term_win_opts).returns(term_win)
			api_mock.nvim_open_win.on_call_with(0, false, list_win_opts).returns(list_win)

			local created_win = win_util.create_or_get_win(vertical_type, default_config)

			assert.stub(vim.api.nvim_open_win).was_called_with(0, true, term_win_opts)
			assert.stub(vim.api.nvim_open_win).was_called_with(0, false, list_win_opts)
			assert.stub(vim.api.nvim_win_get_width).was_called_with(0)
			assert.stub(vim.api.nvim_set_option_value).was_called_with("number", false, { win = list_win })
			assert.stub(vim.api.nvim_set_option_value).was_called_with("relativenumber", false, { win = list_win })
			assert.stub(vim.api.nvim_set_option_value).was_called_with("cursorline", false, { win = list_win })
			assert.are.same({ [vertical_type] = win }, win_util._wins)
			assert.are.same(win, created_win)
		end)

		it("creates new floating window", function()
			local api_mock = mock(vim.api)

			local term_win = 1001
			local list_win = 1002
			local term_win_opts = {
				border = "single",
				col = 20,
				height = 10,
				relative = "editor",
				row = 7,
				width = 40,
			}
			local list_win_opts = {
				border = "single",
				col = 60,
				height = 10,
				relative = "editor",
				row = 7,
				width = 15,
			}
			local win = { term_win = term_win, list_win = list_win }

			local created_win = win_util.create_or_get_win(floating_type, default_config)

			assert.stub(api_mock.nvim_open_win).was_called_with(0, true, term_win_opts)
			assert.stub(api_mock.nvim_open_win).was_called_with(0, false, list_win_opts)
			assert.stub(vim.api.nvim_set_option_value).was_called_with("number", false, { win = list_win })
			assert.stub(vim.api.nvim_set_option_value).was_called_with("relativenumber", false, { win = list_win })
			assert.stub(vim.api.nvim_set_option_value).was_called_with("cursorline", false, { win = list_win })
			assert.are.same({ [floating_type] = win }, win_util._wins)
			assert.are.same(created_win, win)
		end)
	end)

	describe("get_win", function()
		it("returns the window with the given type", function()
			local term_win = 1
			local list_win = 2
			local win = { term_win = term_win, list_win = list_win }

			win_util._wins[type] = win

			local returned_win = win_util.get_win(type)
			assert.are.same(win, returned_win)
		end)

		it("returns nil if there is no window", function()
			local win = win_util.get_win(type)
			assert.is_nil(win)
		end)
	end)

	describe("close_win", function()
		it("closes the given window if it is not the last (two) window open", function()
			local api_mock = mock(vim.api, true)
			local term_win = 1
			local list_win = 2
			local win = { term_win = term_win, list_win = list_win }

			win_util._wins[type] = win
			api_mock.nvim_list_wins.returns({ 1, 2, 3 })

			win_util.close_win(type)

			assert.stub(api_mock.nvim_win_close).was_called_with(win.term_win, false)
			assert.stub(api_mock.nvim_win_close).was_called_with(win.list_win, false)
			assert.is_nil(win_util._wins[type])
		end)

		it("does not close the given window if it is the last (two) window open, only closes list window", function()
			local api_mock = mock(vim.api, true)

			local term_win = 1
			local list_win = 2
			local win = { term_win = term_win, list_win = list_win }
			local empty_buf = 2

			api_mock.nvim_list_wins.returns({ 1, 2 })
			api_mock.nvim_create_buf.returns(empty_buf)

			win_util._wins[type] = win

			win_util.close_win(type)

			assert.stub(api_mock.nvim_win_close).was_called(1, false)
			assert.stub(api_mock.nvim_win_close).was_called_with(list_win, false)
			assert.stub(api_mock.nvim_create_buf).was_called_with(false, false)
			assert.stub(api_mock.nvim_win_set_buf).was_called_with(win.term_win, empty_buf)
			assert.is_nil(win_util._wins[type])
		end)

		it("dose not do anything if window does not exist with the given type", function()
			mock(vim.api, true)

			win_util.close_win(type)

			assert.stub(vim.api.nvim_win_close).was_not_called()
			assert.stub(vim.api.nvim_win_set_buf).was_not_called()
			assert.is_nil(win_util._wins[type])
		end)
	end)

	describe("get_wins", function()
		it("returns windows", function()
			local vertical_win = { term_win = 1, list_win = 2 }
			local horizontal_win = { term_win = 3, list_win = 4 }
			local floating_win = { term_win = 5, list_win = 6 }
			local expected_wins = { 1, 2, 3, 4, 5, 6 }

			win_util._wins = {
				[vertical_type] = vertical_win,
				[type] = horizontal_win,
				[floating_type] = floating_win,
			}

			local wins = win_util.get_wins()
			table.sort(wins)

			assert.are.same(expected_wins, wins)
			assert.are.same(
				{ [vertical_type] = vertical_win, [type] = horizontal_win, [floating_type] = floating_win },
				win_util._wins
			)
		end)
	end)

	describe("get_win_type", function()
		it("returns type of win", function()
			local vertical_win = { term_win = 1, list_win = 2 }
			local horizontal_win = { term_win = 3, list_win = 4 }
			local floating_win = { term_win = 5, list_win = 6 }

			win_util._wins = {
				[vertical_type] = vertical_win,
				[type] = horizontal_win,
				[floating_type] = floating_win,
			}

			assert.are.same(vertical_type, win_util.get_win_type(1))
			assert.are.same(type, win_util.get_win_type(3))
			assert.are.same(floating_type, win_util.get_win_type(5))
		end)

		it("returns nil if cannot find window", function()
			local vertical_win = { term_win = 1, list_win = 2 }
			local floating_win = { term_win = 5, list_win = 6 }

			win_util._wins = {
				[vertical_type] = vertical_win,
				[floating_type] = floating_win,
			}

			assert.is_nil(win_util.get_win_type(3))
		end)
	end)

	describe("verify_wins", function()
		it("removes invalid windows and closes list windows", function()
			local api_mock = mock(vim.api, true)

			local vertical_win = { term_win = 1, list_win = 2 }
			local horizontal_win = { term_win = 3, list_win = 4 }
			local floating_win = { term_win = 5, list_win = 6 }

			api_mock.nvim_win_is_valid.on_call_with(1).returns(false)
			api_mock.nvim_win_is_valid.on_call_with(2).returns(false)
			api_mock.nvim_win_is_valid.on_call_with(3).returns(true)
			api_mock.nvim_win_is_valid.on_call_with(5).returns(false)
			api_mock.nvim_win_is_valid.on_call_with(6).returns(true)

			win_util._wins = {
				[vertical_type] = vertical_win,
				[type] = horizontal_win,
				[floating_type] = floating_win,
			}

			win_util.verify_wins()

			assert.are.same({ [type] = horizontal_win }, win_util._wins)
			assert.stub(vim.api.nvim_win_is_valid).was_called(5)
			assert.stub(vim.api.nvim_win_is_valid).was_called_with(1)
			assert.stub(vim.api.nvim_win_is_valid).was_called_with(2)
			assert.stub(vim.api.nvim_win_is_valid).was_called_with(3)
			assert.stub(vim.api.nvim_win_is_valid).was_called_with(5)
			assert.stub(vim.api.nvim_win_is_valid).was_called_with(6)
			assert.stub(vim.api.nvim_win_close).was_called(1)
			assert.stub(vim.api.nvim_win_close).was_called_with(6, false)
		end)
	end)
end)
