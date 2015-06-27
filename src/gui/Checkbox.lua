Checkbox = {}
Checkbox.__index = Checkbox

setmetatable(Checkbox, {
  __call = function (cls, ...)
    return cls.create(...)
  end,
})

function Checkbox:draw()
  if (self.checked) then
    love.graphics.setColor(self.fillColor)
    love.graphics.rectangle(unpack(self.fill))
  end
  love.graphics.setColor(self.borderColor)
  love.graphics.rectangle(unpack(self.border))
end

function Checkbox:addListener(parent, listener)
  table.insert(self.listeners, {parent, listener})
end

function Checkbox:mousepressed(x, y, button)
  if not self.enabled then return end
  if (button == "l" and x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height) then
    self.checked = not self.checked
    for k, v in pairs(self.listeners) do
      local s, e = pcall(v[2], v[1], self, "clicked")
      if not s then print(e) end
    end
  end
end

function Checkbox:isChecked()
  return self.checked
end

function Checkbox:setEnabled(bool)
  self.enabled = bool
end

function Checkbox.create(x, y, width, height)
  local self = setmetatable({}, Checkbox)
  self.x = x
  self.y = y
  self.width = width
  self.height = height
  self.border = {"line", x, y, width, height}
  self.fill = {"fill", x, y, width, height}
  self.borderColor = {255, 255, 255}
  self.fillColor = {128, 128, 128}
  self.checked = false
  self.listeners = {}
  self.enabled = true
  return self
end

return Checkbox.create(0, 0, 0, 0)