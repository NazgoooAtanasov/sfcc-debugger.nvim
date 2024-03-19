local path = require('plenary.path')

local M = {}

M.hostname = nil
M.username = nil
M.password = nil
M.auth = nil
M.client_id = 'sfcc-debugger.nvim'

M.load_config = function()
  local cwd = vim.loop.cwd()
  local dw_json_path = cwd .. "/dw.json"
  local fd = path:new(dw_json_path)
  local content = fd:read()

  if content ~= nil then
    local dw_json = vim.fn.json_decode(content)
    M.hostname = dw_json['hostname']
    M.username = dw_json['username']
    M.password = dw_json['password']
    M.auth = M.username .. ":" .. M.password
  end
end

return M
