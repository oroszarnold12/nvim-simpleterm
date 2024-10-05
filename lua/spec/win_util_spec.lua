local mock = require("luassert.mock")
local assert = require("luassert")

local default_config = {
	type_opts = {
		horizontal = { location = "rightbelow", split_ratio = 0.3 },
		vertical = { location = "rightbelow", split_ratio = 0.5 },
		floating = {
			relative = "editor",
			row = 0.3,
			col = 0.25,
			width = 0.5,
			height = 0.4,
			border = "single",
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
	local win_height = 900
	local win_width = 500

	after_each(function()
		win_util._wins = {}
	end)

	describe("create_or_get_win", function()
		it("creates a new window if does not exist", function()
			local api_mock = mock(vim.api, true)
			local created_win = 1

			api_mock.nvim_win_is_valid.returns(true)
			api_mock.nvim_get_current_win.returns(created_win)
			api_mock.nvim_win_get_height.returns(win_height)

			local win = win_util.create_or_get_win(type, default_config)

			assert.stub(api_mock.nvim_open_win).was_called_with(0, true, { split = "below", height = 270 })
			assert.stub(api_mock.nvim_get_current_win).was_called()
			assert.stub(api_mock.nvim_win_get_height).was_called_with(0)
			assert.are.same({ [type] = created_win }, win_util._wins)
			assert.are.same(created_win, win)

			mock.revert(api_mock)
		end)

		it("returns existing window", function()
			local api_mock = mock(vim.api, true)
			local existing_win = 1

			win_util._wins[type] = existing_win

			api_mock.nvim_win_is_valid.returns(true)
			api_mock.nvim_get_current_win.returns(existing_win)
			api_mock.nvim_win_get_height.returns(win_height)

			local win = win_util.create_or_get_win(type, default_config)

			assert.stub(api_mock.nvim_open_win).was_not_called()
			assert.stub(api_mock.nvim_get_current_win).was_not_called()
			assert.stub(api_mock.nvim_win_get_height).was_not_called()
			assert.are.same({ [type] = existing_win }, win_util._wins)
			assert.are.same(existing_win, win)

			mock.revert(api_mock)
		end)

		it("creates new window if existing window is invalid", function()
			local api_mock = mock(vim.api, true)
			local existing_win = 1
			local created_win = 2

			win_util._wins[type] = existing_win

			api_mock.nvim_win_is_valid.returns(false)
			api_mock.nvim_get_current_win.returns(created_win)
			api_mock.nvim_win_get_height.returns(win_height)

			local win = win_util.create_or_get_win(type, default_config)

			assert.stub(api_mock.nvim_open_win).was_called_with(0, true, { split = "below", height = 270 })
			assert.stub(api_mock.nvim_get_current_win).was_called()
			assert.stub(api_mock.nvim_win_get_height).was_called_with(0)
			assert.are.same({ [type] = created_win }, win_util._wins)
			assert.are.same(created_win, win)

			mock.revert(api_mock)
		end)

		it("creates new vertical window", function()
			local api_mock = mock(vim.api, true)
			local created_win = 1
			local vertical_type = "vertical"

			api_mock.nvim_win_is_valid.returns(true)
			api_mock.nvim_get_current_win.returns(created_win)
			api_mock.nvim_win_get_width.returns(win_width)

			local win = win_util.create_or_get_win(vertical_type, default_config)

			assert.stub(api_mock.nvim_open_win).was_called_with(0, true, { split = "right", width = 250 })
			assert.stub(api_mock.nvim_get_current_win).was_called()
			assert.stub(api_mock.nvim_win_get_width).was_called_with(0)
			assert.are.same({ [vertical_type] = created_win }, win_util._wins)
			assert.are.same(created_win, win)

			mock.revert(api_mock)
		end)

		it("creates new vertical window", function()
			local api_mock = mock(vim.api, true)
			local created_win = 1
			local vertical_type = "vertical"

			api_mock.nvim_win_is_valid.returns(true)
			api_mock.nvim_get_current_win.returns(created_win)
			api_mock.nvim_win_get_width.returns(win_width)

			local win = win_util.create_or_get_win(vertical_type, default_config)

			assert.stub(api_mock.nvim_open_win).was_called_with(0, true, { split = "right", width = 250 })
			assert.stub(api_mock.nvim_get_current_win).was_called()
			assert.stub(api_mock.nvim_win_get_width).was_called_with(0)
			assert.are.same({ [vertical_type] = created_win }, win_util._wins)
			assert.are.same(created_win, win)

			mock.revert(api_mock)
		end)

		it("creates new floating window", function()
			local api_mock = mock(vim.api)
			local floating_type = "floating"

			local win = win_util.create_or_get_win(floating_type, default_config)
			local current_win = vim.api.nvim_get_current_win()

			assert.stub(api_mock.nvim_open_win).was_called_with(0, true, {
				border = "single",
				col = 20,
				height = 10,
				relative = "editor",
				row = 7,
				width = 40,
			})
			assert.stub(api_mock.nvim_get_current_win).was_called()
			assert.are.same({ [floating_type] = current_win }, win_util._wins)
			assert.are.same(current_win, win)

			mock.revert(api_mock)
		end)
	end)

	describe("get_win", function()
		it("returns the window with the given type", function()
			local api_mock = mock(vim.api, true)
			local existing_win = 1

			win_util._wins[type] = existing_win
			api_mock.nvim_win_is_valid.returns(true)

			local win = win_util.get_win(type)
			assert.are.same(win, existing_win)

			mock.revert(api_mock)
		end)

		it("returns nil if window is invalid", function()
			local api_mock = mock(vim.api, true)
			local existing_win = 1

			win_util._wins[type] = existing_win
			api_mock.nvim_win_is_valid.returns(false)

			local win = win_util.get_win(type)
			assert.is_nil(win)

			mock.revert(api_mock)
		end)

		it("returns nil if there is no window", function()
			local win = win_util.get_win(type)
			assert.is_nil(win)
		end)
	end)

	describe("close_win", function()
		it("closes the given window if it is not the last window open", function()
			local api_mock = mock(vim.api, true)
			local win = 1

			win_util._wins[type] = win
			api_mock.nvim_list_wins.returns({ 1, 2 })

			win_util.close_win(type)
			assert.stub(api_mock.nvim_win_close).was_called_with(win, false)
			assert.is_nil(win_util._wins[type])

			mock.revert(api_mock)
		end)

		it("does not close the given window if it is the last window open", function()
			local api_mock = mock(vim.api, true)
			local win = 1
			local empty_buf = 2

			win_util._wins[type] = win
			api_mock.nvim_list_wins.returns({ 1 })
			api_mock.nvim_create_buf.returns(empty_buf)

			win_util.close_win(type)
			assert.stub(api_mock.nvim_win_close).was_not_called()
			assert.stub(api_mock.nvim_create_buf).was_called_with(false, false)
			assert.stub(api_mock.nvim_win_set_buf).was_called_with(win, empty_buf)
			assert.is_nil(win_util._wins[type])

			mock.revert(api_mock)
		end)

		it("dose not do anything if window does not exist with the given type", function()
			local api_mock = mock(vim.api, true)

			win_util.close_win(type)
			assert.stub(api_mock.nvim_win_close).was_not_called()
			assert.is_nil(win_util._wins[type])

			mock.revert(api_mock)
		end)
	end)

	describe("get_wins", function()
		it("returns valid windows", function()
			local api_mock = mock(vim.api, true)

			win_util._wins = {
				["vertical"] = 1,
				["horizontal"] = 2,
				["floating"] = 3,
			}

			api_mock.nvim_win_is_valid.on_call_with(1).returns(true)
			api_mock.nvim_win_is_valid.on_call_with(2).returns(false)
			api_mock.nvim_win_is_valid.on_call_with(3).returns(true)

			local wins = win_util.get_wins()

			assert.stub(api_mock.nvim_win_is_valid).was_called_with(1)
			assert.stub(api_mock.nvim_win_is_valid).was_called_with(2)
			assert.stub(api_mock.nvim_win_is_valid).was_called_with(2)
			assert.are.same({ ["vertical"] = 1, ["floating"] = 3 }, wins)
			assert.are.same({ ["vertical"] = 1, ["floating"] = 3 }, win_util._wins)

			mock.revert(api_mock)
		end)
	end)

	describe("get_win_type", function()
		it("returns type of win", function()
			win_util._wins = {
				["vertical"] = 1,
				["horizontal"] = 2,
				["floating"] = 3,
			}

			assert.are.same(win_util.get_win_type(1), "vertical")
			assert.are.same(win_util.get_win_type(2), "horizontal")
			assert.are.same(win_util.get_win_type(3), "floating")
		end)

		it("returns nil if cannot find window", function()
			win_util._wins = {
				["vertical"] = 1,
				["floating"] = 3,
			}

			assert.is_nil(win_util.get_win_type(2))
		end)
	end)
end)
