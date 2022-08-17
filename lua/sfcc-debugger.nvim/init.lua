local path = require('plenary.path')
local curl = require('plenary.curl')

local M = {}

local CLIENT_ID = 'sfcc-debugger.nvim'

local cwd = vim.loop.cwd()
local hostname = nil
local username = nil
local password = nil
local auth = nil


M.init = function ()
    local dw_json_path = cwd.."/dw.json"
    local fd = path:new(dw_json_path)
    local content = fd:read()

    if content ~= nil then
        local dw_json = vim.fn.json_decode(content)
        hostname = dw_json['hostname']
        username = dw_json['username']
        password = dw_json['password']
        auth = username..":"..password
        -- add error hanlding for missing auth creds
    end
end

--[[
-- attach to sdapi
--]]
M.attach = function ()
    local request = curl.post("https://"..hostname.."/s/-/dw/debugger/v2_0/client", {
        auth = auth,
        headers = {
            x_dw_client_id = CLIENT_ID
        }
    })

    print(vim.inspect(request))
end

--[[
-- detach from sdapi
--]]
M.detach  = function ()
    local request = curl.delete("https://"..hostname.."/s/-/dw/debugger/v2_0/client", {
        auth = auth,
        headers = {
            x_dw_client_id = CLIENT_ID
        }
    })

    print(vim.inspect(request))
end

--[[
-- adding a breakpoint
--]]
-- M.add_breakpoint = function ()
--     local cursor_pos = vim.api.nvim_win_get_cursor(0)
--     local row = cursor_pos[1]
--     local current_file_path = vim.api.nvim_buf_get_name(0)
--     local file_path_in_cloud = ''
-- end

return M
