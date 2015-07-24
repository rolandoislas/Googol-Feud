local textUtil = require "/util/TextUtil"

TextField = {}
TextField.__index = TextField

setmetatable(TextField, {
  __call = function (cls, ...)
    return cls.create(...)
  end,
})

local function calculateTextRenderLimit(self)
  local size = textUtil:getTextWidth("N", self.font)
  local limit = 0
  while limit * size + size < self.width do
    limit = limit + 1
  end
  self.textRenderLimit = limit
end

--[[local function calculateTextRenderLimit(self)
  local forwardText = string.sub(self.text, self.viewPos + 1)
  local size = 0
  while textUtil:getTextWidth(string.sub(forwardText, 0, size), self.font) < self.width do
    if size > self.width or textUtil:getTextWidth(string.sub(forwardText, 0, size + 1), self.font) > self.width then break end
    size = size + 1
  end
  self.textRenderLimit = size
end]]

local function truncateRenderText(self)
  self.renderText[1] = string.sub(self.text, self.viewPos + 1, self.viewPos + self.textRenderLimit)
end

local function setText(self, text)
  self.text = text
  truncateRenderText(self)
end

local function positionCursor(self)
  --print("view: "..self.viewPos)
  --print("cursor: "..self.cursorPos)
  --print("limit: "..self.textRenderLimit)
  local upperLimit = self.viewPos + self.cursorPos <= self.textRenderLimit and self.viewPos + self.cursorPos or self.viewPos + self.cursorPos
  --print(string.sub(self.text, self.viewPos + 1, upperLimit))
  local x1 = self.x + (self.cursorPos > 0 and textUtil:getTextWidth(string.sub(self.text, self.viewPos + 1, upperLimit), self.font) or 0)
  local y1 = self.y + self.height * .05
  local x2 = x1
  local y2 = self.y + self.height - self.height * .05
  self.cursor = {x1, y1, x2, y2}
end

local function createSelectionBox(self)
  local height = self.cursor[4] - self.cursor[2]
  local pre = textUtil:getTextWidth(string.sub(self.text, 0, self.selectedText[1]), self.font)
  local width = textUtil:getTextWidth(string.sub(self.text, self.selectedText[1], self.selectedText[2]), self.font)
  local x = self.x + pre
  local y = self.cursor[2]
  self.selection = {"fill", x, y, width, height}
end

function TextField:setBackgroundColor(r, g, b, a)
  self.backgroundColor = {r, g, b, a or 255}
end

function TextField:setTextColor(r, g, b, a)
  self.textColor = {r, g, b, a or 255}
end

function TextField:setBorderColor(r, g, b, a)
  self.borderColor = {r, g, b, a or 255}
end

function TextField:setFont(font)
  self.font = font
  calculateTextRenderLimit(self)
  positionCursor(self)
end

function TextField:draw()
  -- Background
  love.graphics.setColor(unpack(self.backgroundColor))
  love.graphics.rectangle(unpack(self.rect))
  -- Border
  love.graphics.setColor(unpack(self.borderColor))
  love.graphics.rectangle("line", self.rect[2], self.rect[3], self.rect[4], self.rect[5])
  -- Selection
  love.graphics.setColor(unpack(self.selectionColor))
  if self.selectedText[2] > 0 then
    love.graphics.rectangle(unpack(self.selection))
  end
  -- Text
  love.graphics.setColor(unpack(self.textColor))
  love.graphics.setFont(self.font)
  love.graphics.printf(unpack(self.renderText))
  -- Cursor
  if self.cursorVisible then
    love.graphics.setLineWidth(self.cursorSize)
    love.graphics.line(unpack(self.cursor))
    love.graphics.setLineWidth(1)
  end
end

local function updateCursor(self)
  if self.tick >= 40 then -- 1 second
    self.cursorVisible = not self.cursorVisible
    self.tick = 0
  else
    self.tick = self.tick + 1
  end
end

function TextField:update()
  if not self.acceptInput then return end
  updateCursor(self)
end

local function resetSelection(self)
  self.selectedText = {0, 0}
  createSelectionBox(self)
end

local function deleteSelection(self)
  setText(self, string.sub(self.text, 0, self.selectedText[1]) .. string.sub(self.text, self.selectedText[2] + 1))
  self.cursorPos = self.selectedText[1]
  self.viewPos = 0
  positionCursor(self)
  resetSelection(self)
end

function TextField:textinput(text)
  if not self.acceptInput then return end
  if self.selectedText[2] > 0 then deleteSelection(self) end
  setText(self, string.sub(self.text, 0, self.cursorPos + self.viewPos) .. text .. string.sub(self.text, self.cursorPos + self.viewPos + 1))
  if string.len(self.text) > self.textRenderLimit then
    self.viewPos = self.viewPos + ((self.cursorPos < self.textRenderLimit) and 0 or 1)
    truncateRenderText(self)
  end
  self.cursorPos = self.cursorPos < self.textRenderLimit and self.cursorPos + 1 or self.cursorPos
  positionCursor(self)
  resetSelection(self)
end

function TextField:mousepressed(x, y, button)
  if x >= self.x and y >= self.y and x <= self.x + self.width and y <= self.y + self.height then
    self:enableInput()
  else
    self:disableInput()
  end
end

function TextField:keypressed(key)
  if not self.acceptInput then return end
  --print("key: "..key)
  if key == "backspace" then
    if self.selectedText[2] > 0 then
      deleteSelection(self)
    else
      setText(self, string.sub(string.sub(self.text, 0, self.cursorPos + self.viewPos), 0, -2) .. string.sub(self.text, self.cursorPos + self.viewPos + 1))
      self.cursorPos = (self.cursorPos > 0 and self.viewPos == 0) and self.cursorPos - 1 or self.cursorPos
      self.viewPos = self.viewPos > 0 and self.viewPos - 1 or self.viewPos
      truncateRenderText(self)
      positionCursor(self)
      resetSelection(self)
    end
  elseif key == "a" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
    self.selectedText = {0, string.len(self.text)}
    createSelectionBox(self)
    self.cursorPos = 0
    positionCursor(self)
  elseif key == "c" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
    love.system.setClipboardText(string.sub(self.text, self.selectedText[1], self.selectedText[2]))
  elseif key == "left" then
    self.cursorPos = self.cursorPos > 0 and self.cursorPos - 1 or self.cursorPos
    self.viewPos = (self.viewPos > 0 and self.cursorPos == 0) and self.viewPos - 1 or self.viewPos
    positionCursor(self)
    resetSelection(self)
    truncateRenderText(self)
  elseif key == "right" then
    self.cursorPos = (string.len(self.text) > self.cursorPos and self.cursorPos < self.textRenderLimit) and self.cursorPos + 1 or self.cursorPos
    self.viewPos = (self.viewPos < string.len(self.text) - self.textRenderLimit and self.cursorPos == self.textRenderLimit) and self.viewPos + 1 or self.viewPos
    positionCursor(self)
    resetSelection(self)
    truncateRenderText(self)
  elseif key == "x" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
    deleteSelection(self)
  elseif key == "v" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
    if self.selectedText[2] > 0 then
      deleteSelection(self)
    end
    self:textinput(love.system.getClipboardText())
  elseif key == "return" then
    for k, v in pairs(self.listeners) do
      v[2](v[1], "submit")
    end
  end
end

function TextField:addListener(parent, listener)
  table.insert(self.listeners, {parent, listener})
end

function TextField:getX()
  return self.x
end

function TextField:getY()
  return self.y
end

function TextField:getWidth()
  return self.width
end

function TextField:getHeight()
  return self.height
end

function TextField:getText()
  return self.text
end

function TextField:disableInput()
  self.acceptInput = false
  self.cursorVisible = false
end

function TextField:enableInput()
  self.acceptInput = true
  self.cursorVisible = true
end

function TextField:clear()
  self.selectedText = {0, string.len(self.text)}
  deleteSelection(self)
end

function TextField:isInputEnabled()
  return self.acceptInput
end

function TextField.create(text, x, y, width, height, align)
  local self = setmetatable({}, TextField)
  self.x = x
  self.y = y
  self.width = width
  self.height = height
  self.align = align
  self.text = text
  self.renderText = {text, x, y, width, align or "left"}
  self.rect = {"fill", x, y, width, height}
  self.backgroundColor = {0, 0, 0, 0}
  self.borderColor = {0, 0, 0, 0}
  self.textColor = {0, 0, 0}
  self.cursor = {0, 0, 0, 0}
  self.cursorSize = width * .005
  self.cursorPos = 0
  self.cursorVisible = true
  self.font = love.graphics.newFont(12)
  self.tick = 0
  self.selectedText = {0, 0}
  self.selection = {"fill", 0, 0, 0, 0}
  self.selectionColor = {128, 128, 128}
  self.viewPos = 0
  self.textRenderLimit = 8
  self.listeners = {}
  self.acceptInput = true
  calculateTextRenderLimit(self)
  positionCursor(self)
  truncateRenderText(self)
  return self
end

return TextField.create("", 0, 0, 0, 0)