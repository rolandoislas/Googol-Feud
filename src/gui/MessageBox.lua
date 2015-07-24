local button = require "/gui/Button"
local tf = require "/gui/TextField"
local textUtil = require "/util/TextUtil"

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
  -- Name change
  if self.showitems.nameChange then
    love.graphics.print(unpack(self.nameTextBoxTitile))
    love.graphics.print(unpack(self.emailTextBoxTitile))
    self.emailTextBox:draw()
    self.nameTextBox:draw()
  end
end

function MessageBox:update()
  if not self.visible then return end
  self.buttonConfirm:update()
  self.emailTextBox:update()
  self.nameTextBox:update()
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
  if not self.visible then return end
  self.buttonConfirm:mousepressed(x, y, button)
  self.emailTextBox:mousepressed(x, y, button)
  self.nameTextBox:mousepressed(x, y, button)
end

function MessageBox:keypressed(key)
  self.emailTextBox:keypressed(key)
  self.nameTextBox:keypressed(key)
end

local function confirmed(self)
  for k, v in pairs(self.listeners) do
    local s, e = pcall(v[2], v[1], self, "clicked", self.nameTextBox:getText(), self.emailTextBox:getText())
    if not s then print(e) end
  end
end

function MessageBox:showNameChange(bool)
  self.showitems.nameChange = bool
end

function MessageBox:textinput(text)
  self.emailTextBox:textinput(text)
  self.nameTextBox:textinput(text)
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
  self.showitems = {}
  -- ok button
  local bw = width * .1
  local bh = height * .2
  self.buttonConfirm = button.create(x + width - bw, y + height - bh, bw, bh)
  self.buttonConfirm:setBackgroundColor("focus", 75, 75, 75)
  self.buttonConfirm:setBackgroundColor("blur", 0, 0, 0)
  self.buttonConfirm:setText("Ok")
  self.buttonConfirm:setFont(bh > 1 and bh or 1)
  self.buttonConfirm:addListener(self, confirmed)
  -- name change
  self.showitems.nameChange = false
  self.nameTextBoxTitile = {"Name", x, y + self.titleBox[5]}
  self.nameTextBox = tf.create("", x, self.nameTextBoxTitile[3] + textUtil:getTextHeight(self.nameTextBoxTitile[1], self.font) * 2, width, height * .15)
  self.nameTextBox:setBorderColor(255, 255, 255)
  self.nameTextBox:setTextColor(255, 255, 255)
  local textBoxFont = height > 0 and love.graphics.newFont(height * .15) or love.graphics.newFont(1)
  self.nameTextBox:setFont(textBoxFont)
  self.emailTextBoxTitile = {"Email (for gravatar)", x, self.nameTextBox:getY() + self.nameTextBox:getHeight()}
  self.emailTextBox = tf.create("", x, self.emailTextBoxTitile[3] + textUtil:getTextHeight(self.emailTextBoxTitile[1], self.font) * 2, width, height * .15)
  self.emailTextBox:setBorderColor(255, 255, 255)
  self.emailTextBox:setTextColor(255, 255, 255)
  self.emailTextBox:setFont(textBoxFont)
  return self
end

return MessageBox.create(0, 0, 0, 0)