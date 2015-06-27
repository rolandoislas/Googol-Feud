local button = require "/gui/Button"

MessageBox = {}
MessageBox.__index = MessageBox

setmetatable(MessageBox, {
  __call = function (cls, ...)
    return cls.create(...)
  end,
})

function MessageBox:draw()
  if not self.visible then return end
  love.graphics.setColor(self.color)
  love.graphics.setFont(self.font)
  love.graphics.rectangle(unpack(self.box))
  love.graphics.rectangle(unpack(self.titleBox))
  love.graphics.setColor(self.textColor)
  love.graphics.print(unpack(self.title))
  love.graphics.printf(unpack(self.message))
  self.buttonConfirm:draw()
end

function MessageBox:update()
  self.buttonConfirm:update()
end

function MessageBox:addListener(parent, listener)
  table.insert(self.listeners, {parent, listener})
end

function MessageBox:setTitle(title)
  self.title[1] = title
end

function MessageBox:setMessage(message)
  self.message[1] = message
end 

function MessageBox:show()
  self.visible = true
end

function MessageBox:hide()
  self.visible = false
end

function MessageBox:isVisible()
  return self.visible
end

function MessageBox:mousepressed(x, y, button)
  self.buttonConfirm:mousepressed(x, y, button)
end

local function confirmed(self)
  for k, v in pairs(self.listeners) do
    local s, e = pcall(v[2], v[1], self, "clicked")
    if not s then print(e) end
  end
end

function MessageBox.create(x, y, width, height)
  local self = setmetatable({}, MessageBox)
  self.x = x
  self.y = y
  self.width = width
  self.height = height
  self.color = {0, 0, 0}
  self.textColor = {255, 255, 255}
  self.box = {"fill", x, y, width, height}
  self.titleBox = {"fill", x, y, width, height * .1}
  self.font = love.graphics.newFont(self.titleBox[5] > 0 and self.titleBox[5] or 1)
  self.title = {"", x, y}
  self.message = {"", x, y + self.titleBox[5], self.box[4]}
  self.listeners = {}
  local bw = width * .1
  local bh = height * .2
  self.buttonConfirm = button.create(x + width - bw, y + height - bh, bw, bh)
  self.buttonConfirm:setBackgroundColor("focus", 75, 75, 75)
  self.buttonConfirm:setBackgroundColor("blur", 0, 0, 0)
  self.buttonConfirm:setText("Ok")
  self.buttonConfirm:setFont(bh > 1 and bh or 1)
  self.buttonConfirm:addListener(self, confirmed)
  return self
end

return MessageBox.create(0, 0, 0, 0)