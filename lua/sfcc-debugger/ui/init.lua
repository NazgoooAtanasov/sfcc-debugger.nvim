local reload = require("plenary.reload")
local iterator = require("plenary.iterators")
local threads = require('sfcc-debugger.sfcc-threads')
local DebuggerUIItem = require('sfcc-debugger.ui.debug-ui-item').DebuggerUIItem

local M = {}

---@class World
---@field public variables table<DebuggerUIItem>
local World = {}
World.__index = World
function World.new()
  local self = setmetatable({}, World)
  self.variables = {}
  return self
end

--- adds the variables from the parameter into the scoped variables.
--- created DebuggerUIItem for each variables
--- sets the proper parent to the variables, if parent provided
---@param variables table
---@param parent DebuggerUIItem?
---@param expanded boolean?
function World:add_variables(variables, parent, expanded)
  if type(variables) ~= 'table' then return end

  --- @TODO: add filtration for SFCC types that should not be displayed.
  --- e.g. Function
  iterator.iter(variables):for_each(function (x)
    local debug_item = DebuggerUIItem.new(x.name, x.value, 0)
    if parent ~= nil then
      parent:add_child(debug_item)
    end
    if expanded ~= nil then
      debug_item.expanded = expanded
    end
    table.insert(self.variables, debug_item)
  end)
end

--- gets the variable at the provided index
---@param idx number
---@return DebuggerUIItem
function World:get_variable(idx)
  return self.variables[idx]
end

---@type World?
M.world = nil
M.init = function ()
  M.world = World.new()
end

-- FOR DEVELOPMENT PURPOSES ONLY
M.reaload = function()
  reload.reload_module("ng.ui-explore")
end

local function render(table, buf)
  -- saving the state of the curosr before cleaning so we can restore it 
  -- instead of having it always on top after render.
  local cursor = vim.api.nvim_win_get_cursor(0)

  -- clearing the buffer, even if it is already empty
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})

  local iter = iterator.iter(table)
  local lines = iter
      :map(function(x)
        return string.rep("\t", x.inset) .. x.name .. " - " .. x.value
      end)
      :tolist()

  vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
  vim.api.nvim_win_set_cursor(0, cursor)
end

-- recursivelly close item and its children
local function close_item(item, items)
  local children = iterator.iter(items)
      :filter(function(x)
        -- if the item has no item to belong to, this means it is the root and
        -- it should never be a part of the children
        if x.belongs_to == nil then
          return false
        end
        return x.belongs_to.name == item.name
      end):tolist()

  if #children > 0 then
    for _, v in ipairs(children) do
      v.expanded = false
      items = close_item(v, items)
    end
  end

  return iterator.iter(items):filter(function(x)
    -- if the item has no item to belong to, this means it is the root and we always show it
    if x.belongs_to == nil then
      return true
    end
    return x.belongs_to.name ~= item.name
  end):tolist()
end

local function open_item(item, items, cursor)
  iterator.iter(item.values)
      :for_each(function(x) table.insert(items, cursor[1] + 1, x) end)
end

M.show = function()
  vim.api.nvim_command("vs items")
  local items_buf = vim.api.nvim_get_current_buf()
  local window_columns = vim.o.columns
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.api.nvim_win_set_width(0, math.floor(window_columns * .25))

  render(M.world.variables, items_buf)

  vim.api.nvim_buf_set_keymap(items_buf, "n", "<CR>", "", {
    callback = function()
      local cursor = vim.api.nvim_win_get_cursor(0)

      local clicked_item = M.world:get_variable(cursor[1])
      clicked_item.expanded = not clicked_item.expanded

      if clicked_item.expanded then
        if #clicked_item.values <= 0 then
          local vars_obj = threads.get_variables(clicked_item:get_full_path())['object_members']
          M.world:add_variables(vars_obj, clicked_item, true)
        else
          for _, v in ipairs(clicked_item.values) do
            v.expanded = true
          end
        end

        open_item(clicked_item, M.world.variables, cursor)
      else
        M.world.variables = close_item(clicked_item, M.world.variables)
      end

      render(M.world.variables, items_buf)
    end
  })
end

return M
