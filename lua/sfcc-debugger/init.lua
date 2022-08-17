local path = require('plenary.path')
local curl = require('plenary.curl')

local M = {}

local CLIENT_ID = 'sfcc-debugger.nvim'

local cwd = vim.loop.cwd()
local hostname = nil
local username = nil
local password = nil
local auth = nil
local breakpoints = {}

function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

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
M.add_breakpoint = function ()
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local row = cursor_pos[1]
    local current_file_path = '/home/ng/_Forkpoint/acne/app-project/app_acne_sfra/cartridge/controllers/ProductPersonalisation.js' -- vim.api.nvim_buf_get_name(0)
    local curr_file_split = split(current_file_path, "/")

    local idx = nil
    local file_path_in_cloud_table = {}

    for i, v in ipairs(curr_file_split) do
        if v == "cartridge" then
            idx = i - 1 -- returning always -1 because we want to know the path including the cartridge name.
        end

        if idx then
            table.insert(file_path_in_cloud_table, v)
        end
    end

    table.insert(file_path_in_cloud_table, 1, curr_file_split[idx])

    local file_in_cloud = ''

    for i, v in ipairs(file_path_in_cloud_table) do
        file_in_cloud = file_in_cloud.."/"..v
    end

    table.insert(breakpoints, {
        line_number = row,
        script_path = file_in_cloud
    })

    local request = curl.post("https://"..hostname.."/s/-/dw/debugger/v2_0/breakpoints", {
        auth = auth,
        body = vim.fn.json_encode(breakpoints),
        headers = {
            x_dw_client_id = CLIENT_ID
        }
    })

    print(vim.inspect(request))
end

return M
