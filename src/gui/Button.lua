Button = {}
Button.__index = Button

setmetatable(Button, {
  __call = function (cls, ...)
    return cls.create(...)
  end,
})

local function contains(self, x, y)
  return x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height
end

function Button:draw()
  if not self.visible then return end
  -- Box
  love.graphics.setColor(self.boxColor)
  love.graphics.rectangle(unpack(self.box))
  -- Text
  love.graphics.setColor(self.textColor)
  love.graphics.setFont(self.font)
  love.graphics.print(unpack(self.text))
end

function Button:update()
  if not self.visible then return end
  local x, y = love.mouse.getPosition()
  if contains(self, x, y)  then
    if self.boxColor == self.blurColor then
      self.boxColor = self.focusColor
    end
  elseif self.boxColor == self.focusColor then
    self.boxColor = self.blurColor
  else
    self.boxColor = self.blurColor
  end
end

function Button:setText(text)
  self.text = {text, self.x, self.y}
end

function Button:setFont(size)
  self.font = love.graphics.newFont(size)
end

function Button:setBackgroundColor(t, r, g, b, a)
  local color = {r, g, b, a or 255}
  if t == "blur" then
    self.blurColor = color
  elseif t == "focus" then
    self.focusColor = color
  end
end

function Button:addListener(parent, listener)
  table.insert(self.listeners, {parent, listener})
end

function Button:mousepressed(x, y, button)
  if not self.visible then return end
  if not contains(self, x, y)  then return end
  for k, v in pairs(self.listeners) do
    local s, e = pcall(v[2], v[1], "clicked")
    if not s then print(e) end
  end
end

function Button:getWidth()
  return self.width
end

function Button:getHeight()
  return self.height
end

function Button:getX()
  return self.x
end

function Button:getY()
  return self.y
end

function Button:getFont()
  return self.font
end

function Button:show()
  self.visible = true
end

function Button:hide()
  self.visible = false
end

function Button.create(x, y, width, height)
  local self = setmetatable({}, Button)
  self.x = x
  self.y = y
  self.width = width
  self.height = height
  self.box = {"fill", x, y, width, height}
  self.focusColor = {100, 100, 100}
  self.blurColor = {128, 128, 128}
  self.textColor = {255, 255, 255}
  self.boxColor = self.blurColor
  self.listeners = {}
  self.text = {"", x, y}
  self.font = love.graphics.newFont(12)
  self.visible = true
  return self
end

return Button.create(0, 0, 0, 0)