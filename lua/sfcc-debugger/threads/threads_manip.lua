local curl = require('plenary.curl')

-- move this to constants file
local CLIENT_ID = 'sfcc-debugger.nvim'

local M = {}

--[[
-- getting all the running debugger threads.
--]]
M.get_threads = function (sandbox_cnf)
    local request = curl.get("https://"..sandbox_cnf.hostname.."/s/-/dw/debugger/v2_0/threads", {
        auth = sandbox_cnf.auth,
        headers = {
            x_dw_client_id = CLIENT_ID
        }
    })

    -- print(vim.inspect(request))

    return vim.fn.json_decode(request.body)
end

--[[
-- getting info for a thread.
--]]
M.get_thread_info = function (sandbox_cnf, thread_id)
    local request = curl.get("https://"..sandbox_cnf.hostname.."/s/-/dw/debugger/v2_0/threads/"..thread_id, {
        auth = sandbox_cnf.auth,
        headers = {
            x_dw_client_id = CLIENT_ID
        }
    })

    print(vim.inspect(request))

    return vim.fn.json_decode(request.body)
end

--[[
-- reseting all running and halted threads
--]]
M.reset_thread = function (sandbox_cnf)
    local request = curl.post("https://"..sandbox_cnf.hostname.."/s/-/dw/debugger/v2_0/threads/reset", {
        auth = sandbox_cnf.auth,
        headers = {
            x_dw_client_id = CLIENT_ID
        }
    })

    print(vim.inspect(request))
end

M.get_variables = function (sandbox_cnf, thrd_idx, frm_idx)
    local request = curl.get("https://"..sandbox_cnf.hostname.."/s/-/dw/debugger/v2_0/threads/"..thrd_idx.."/frames/"..frm_idx.."/variables", {
        auth = sandbox_cnf.auth,
        headers = {
            x_dw_client_id = CLIENT_ID
        }
    })

    print(vim.inspect(vim.fn.json_decode(request.body)))
end

return M
