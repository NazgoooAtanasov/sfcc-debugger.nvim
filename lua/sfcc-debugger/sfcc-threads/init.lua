local curl = require('plenary.curl')
local configuration = require('sfcc-debugger.configuration')

local M = {}

M.get_threads = function()
  local request = curl.get("https://" .. configuration.hostname .. "/s/-/dw/debugger/v2_0/threads", {
    auth = configuration.auth,
    headers = {
      x_dw_client_id = configuration.client_id
    }
  })
  return vim.fn.json_decode(request.body)
end

--[[
-- DELETE?
-- getting info for a thread.
--]]
M.get_thread_info = function(thread_id)
  local request = curl.get("https://" .. configuration.hostname .. "/s/-/dw/debugger/v2_0/threads/" .. thread_id, {
    auth = configuration.auth,
    headers = {
      x_dw_client_id = configuration.client_id
    }
  })
  return vim.fn.json_decode(request.body)
end

M.reset_thread = function()
  curl.post("https://" .. configuration.hostname .. "/s/-/dw/debugger/v2_0/threads/reset", {
    auth = configuration.auth,
    headers = {
      x_dw_client_id = configuration.client_id
    }
  })
end

M.get_variables = function(member)
  local threads_response = M.get_threads()

  local script_threads = threads_response['script_threads']
  if threads_response ~= nil and script_threads ~= nil then
    local thrd_idx = script_threads[1].id
    -- hardcoded for now
    local frm_idx = 0

    if member ~= nil then member = '?object_path=' .. member else member = '' end

    local request = curl.get(
      "https://" .. configuration.hostname .. "/s/-/dw/debugger/v2_0/threads/" .. thrd_idx .. "/frames/" ..
      frm_idx .. "/members" .. member, {
        auth = configuration.auth,
        headers = {
          x_dw_client_id = configuration.client_id
        }
      })
    return vim.fn.json_decode(request.body)
  else
    vim.print("No threads running currently")
  end
end

return M
