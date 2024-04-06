local util = {}
local a = vim.api

util.get_split_dimensions= function(type, ratio)
  local get_dimension = type == "horizontal" and a.nvim_win_get_height or a.nvim_win_get_width
  return math.floor(get_dimension(0) * ratio)
end

util.split = function(type, config)
  local opts = config.type_opts[type]
  local dimensions = util.get_split_dimensions(type, opts.split_ratio)
  local create_split = {
    horizontal = function()
      vim.cmd(opts.location .. dimensions .. " split")
    end,
    vertical = function()
      vim.cmd(opts.location .. dimensions .. " vsplit")
    end,
  }

  create_split[type]()
end

util.verify_windows = function(windows)
  local valid = {}
  for key, value in pairs(windows) do
    if vim.api.nvim_win_is_valid(value) then
      valid[key] = value
    end
  end
  return valid
end

util.verify_terminals = function(terminals)
  local valid = vim.tbl_filter(function(term)
    return vim.api.nvim_buf_is_valid(term.buf)
  end, terminals)

  for index, term in pairs(valid) do
    term.id = index
  end

  return valid
end

return util
