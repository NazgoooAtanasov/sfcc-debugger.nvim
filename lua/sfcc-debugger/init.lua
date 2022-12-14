local path = require('plenary.path')
local curl = require('plenary.curl')
local utils = require('sfcc-debugger.utils')
local threads = require('sfcc-debugger.threads.threads_manip')

local M = {}

-- move this to constants file
local CLIENT_ID = 'sfcc-debugger.nvim'

local cwd = vim.loop.cwd()
local hostname = nil
local username = nil
local password = nil
local auth = nil

local breakpoints = {}
local extmarks = {}
local ns = vim.api.nvim_create_namespace('sfcc-debugger.nvim')

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
    local file_in_cloud = utils.get_file_in_cloud()

    print(file_in_cloud)

    table.insert(breakpoints, {
        line_number = row,
        script_path = file_in_cloud
    })

    local request_body = {}
    request_body['_v'] = '2.0'
    request_body['breakpoints'] = breakpoints

    local request = curl.post("https://"..hostname.."/s/-/dw/debugger/v2_0/breakpoints", {
        auth = auth,
        body = vim.fn.json_encode(request_body),
        headers = {
            x_dw_client_id = CLIENT_ID,
            content_type = "application/json",
        }
    })

    -- using the breakpoints array from the response because that is the onlh way we can take hold of the breakpoint ids.
    local response_breakpoints = vim.fn.json_decode(request.body).breakpoints
    breakpoints = response_breakpoints

    local breakpoint_id = -1
    for k, v in pairs(breakpoints) do
        if v.script_path == file_in_cloud and v.line_number == row then
            breakpoint_id = v.id
        end
    end

    -- here it is row - 1, because the row is calculated on 1 base indexing (ty lua) and the api function expects 0 based indexing.
    local extmark_id = vim.api.nvim_buf_set_extmark(0, ns, row - 1, 0, { virt_text = { { "B" } }, virt_text_pos = "right_align" })

    table.insert(extmarks, {
        breakpoint_id = breakpoint_id,
        extmark_id = extmark_id }
    )

    print(vim.inspect(request))
end

M.delete_breakpoint = function ()
    local breakpoint_id = -1
    local breakpoint_key = -1
    local cursor_pos = vim.api.nvim_win_get_cursor(0)

    local row = cursor_pos[1]
    local file_in_cloud = utils.get_file_in_cloud()

    for k, v in pairs(breakpoints) do
        if v.line_number == row and v.script_path == file_in_cloud then
            breakpoint_id = v.id
            breakpoint_key = k
        end
    end

    if breakpoint_key <= -1 and breakpoint_id <= -1 then
        return
    end

    local request = curl.delete("https://"..hostname.."/s/-/dw/debugger/v2_0/breakpoints/"..breakpoint_id, {
        auth = auth,
        headers = {
            x_dw_client_id = CLIENT_ID
        }
    })

    -- removint the extmark from the buffer when the breakpoint is deleted
    local extmark_key = -1
    local extmark_id = -1
    for k, v in pairs(extmarks) do
        if v.breakpoint_id == breakpoint_id then
            extmark_key = k
            extmark_id = v.extmark_id
        end
    end

    if extmark_id > -1 and extmark_key > -1 then
        table.remove(extmarks, extmark_key)
        vim.api.nvim_buf_del_extmark(0, ns, extmark_id)
    end

    -- removing the breakpoint from the local state
    table.remove(breakpoints, breakpoint_key)

    print(vim.inspect(request))
end

--[[
-- getting all the breakpoints in the program state.
--]]
M.get_breakpoints = function ()
    print(vim.inspect(breakpoints))
    return breakpoints
end

--[[
--  Debugging function wont be there at the end, or will it 
--]]
M.rocket_start = function ()
    M.init()
    M.attach()
    M.add_breakpoint()
end

M.threads = function ()
    threads.get_threads({
        hostname = hostname,
        username = username,
        password = password,
        auth = auth
    })
end

return M
