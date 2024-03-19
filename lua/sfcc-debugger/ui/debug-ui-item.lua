local M = {}

---@class DebuggerUIItem
---@field public name string
---@field public value string
---@field public inset number
---@field public expanded boolean
---@field public belongs_to DebuggerUIItem?
---@field public values table<DebuggerUIItem>
local DebuggerUIItem = {}
DebuggerUIItem.__index = DebuggerUIItem

---@param name string
---@param value string
---@param inset number
---@param expanded boolean?
---@param belongs_to DebuggerUIItem?
---@param values table<DebuggerUIItem>?
function DebuggerUIItem.new(name, value, inset, expanded, belongs_to, values)
  local self = setmetatable({}, DebuggerUIItem)
  self.name = name
  self.value = value
  self.inset = inset
  self.expanded = expanded or false
  self.belongs_to = belongs_to or nil
  self.values = values or {}
  return self
end

---@param item DebuggerUIItem
function DebuggerUIItem:set_parent(item)
  self.belongs_to = item
end

---@param item DebuggerUIItem
function DebuggerUIItem:add_child(item)
  item:set_parent(self)
  table.insert(self.values, item)
end

---@return string
function DebuggerUIItem:get_full_path()
  if self.belongs_to == nil then
    return self.name
  end
  return self.belongs_to:get_full_path() .. "." .. self.name
end

M.DebuggerUIItem = DebuggerUIItem
return M
