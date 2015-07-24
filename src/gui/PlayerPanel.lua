local gravatar  = require "/util/Gravatar"
local textUtil = require "/util/TextUtil"
local checkbox = require "/gui/Checkbox"
local button = require "/gui/Button"

PlayerPanel = {}
PlayerPanel.__index = PlayerPanel

setmetatable(PlayerPanel, {
  __call = function (cls, ...)
    return cls.create(...)
  end,
})

function PlayerPanel:draw()
  -- Background
  love.graphics.setColor(self.backgroundColor)
  love.graphics.rectangle(unpack(self.box))
  -- Border
  love.graphics.setColor(self.borderColor)
  love.graphics.rectangle(unpack(self.border))
  -- Name
  love.graphics.setColor(self.textColor)
  love.graphics.setFont(self.font)
  love.graphics.printf(unpack(self.nameRender))
  -- Icon
  love.graphics.draw(unpack(self.icon))
  -- Points
  if self.show.points then love.graphics.print(unpack(self.pointsText)) end
  -- Errors
  if self.show.errors then
    love.graphics.setColor(self.errorColor)
    love.graphics.print(unpack(self.errorText))
  end
  -- Indicator
  if self.show.ready then
    love.graphics.setColor(self.indicatorColor)
    love.graphics.rectangle(unpack(self.readyIndicator))
  end
  -- Checkbox
  if self.show.readyCheckbox then
    self.readyCheckbox:draw()
    love.graphics.setFont(self.readyFont)
    love.graphics.print(unpack(self.readyText))
  end
  -- Name change
  if self.show.nameChange then
    self.nameChange:draw()
  end
end

local function createIcon(self)
  local image = gravatar:getImage(self.hash)
  local width = self.height * .8
  local height = width
  local x = self.x + self.width * 0.005
  local y = self.y + self.height * 0.01
  local r = 0
  local sx = width / image:getWidth()
  local sy = height / image:getHeight()
  self.icon = {image, x, y, r, sx, sy}
end

local function createName(self)
  local xMargin = self.icon[1]:getWidth() * self.icon[5] + self.width * .02
  local x = self.x + xMargin
  local y = self.y + self.height * .0
  local limit = self.width - xMargin
  self.nameRender = {self.name, x, y, limit}
end

local function createFont(self)
  local window = {love.window.getMode()}
  local size = window[1] * window[2] * 0.00003
  self.font = love.graphics.newFont(size)
end

local function createErrorText(self)
  local text = ""
  for i = 1, self.errors do
    text = text .. "X"
  end
  text = text == ""  and "----" or text
  local margin = (self.icon[1]:getWidth() - textUtil:getTextWidth(text, self.font)) / 2
  local x = self.x + margin
  local y = self.y + self.icon[1]:getHeight()
  self.errorText = {text, x, y}
end

local function createPoints(self)
  local text = "Points: " .. tostring(self.points)
  local x = self.x + self.width - textUtil:getTextWidth(text, self.font) - self.width * 0.01
  local y = self.y + self.icon[1]:getHeight()
  self.pointsText = {text, x, y}
end

local function createShowTable(self)
  self.show.points = true
  self.show.errors = true
  self.show.nameChange = false
  self.show.ready = false
  self.show.readyCheckbox = false
end

local function createReadyIndicator(self)
  self.readyIndicator = {"fill", self.icon[2], self.y + self.icon[1]:getHeight() * self.icon[6], self.icon[1]:getWidth() * self.icon[5], self.height - self.icon[1]:getHeight() * self.icon[6]}
end

local function readyClicked(self, checkbox)
  for k, v in pairs(self.listeners) do
    local s, e = pcall(v[2], v[1], checkbox, "clicked")
    if not s then print(e) end
  end
end

local function createReadyCheckbox(self)
  local width = self.width * .02
  local height = width
  local x = self.x + self.width - width * 2
  local y = self.y + self.height / 2 - height / 2
  self.readyCheckbox = checkbox.create(x, y, width, height)
  self.readyCheckbox:addListener(self, readyClicked)
  self.readyCheckbox:setEnabled(false)
  local text = "Ready"
  self.readyFont = love.graphics.newFont(height > 0 and height or 1)
  local textWidth = textUtil:getTextWidth(text, self.readyFont)
  x = x - textWidth - width
  self.readyText = {text, x, y}
end

local function nameChangeRequested(self)
  for k, v in pairs(self.nameChangeListeners) do
    local s, e = pcall(v[2], v[1], "clicked")
    if not s then print(e) end
  end
end

function PlayerPanel:addNameChangeListener(parent, listener)
  table.insert(self.nameChangeListeners, {parent, listener})
end

local function createNameChange(self)
  local width = self.width * .16
  local height = self.height * .15
  local x = self.nameRender[2]
  local y = self.nameRender[3] + textUtil:getTextHeight(self.nameRender[1], self.font)
  self.nameChange = button.create(x, y, width, height)
  self.nameChange:setText("Change Name")
  self.nameChange:addListener(self, nameChangeRequested)
  self.nameChange:hide()
end

function PlayerPanel:showPoints(bool)
  self.show.points = bool
end

function PlayerPanel:showErrors(bool)
  self.show.errors = bool
end

function PlayerPanel:showNameChange(bool)
  self.show.nameChange = bool
  self.nameChange:show()
end

function PlayerPanel:showReady(bool)
  self.show.ready = bool
end

function PlayerPanel:showReadyCheckbox(bool)
  self.show.readyCheckbox = bool
  self.readyCheckbox:setEnabled(bool)
end

function PlayerPanel:mousepressed(x, y, button)
  self.readyCheckbox:mousepressed(x, y, button)
  self.nameChange:mousepressed(x, y, button)
end

function PlayerPanel:setName(name)
  self.name = name
  createName(self)
end

function PlayerPanel:setHash(hash)
  self.hash = hash
  createIcon(self)
end

function PlayerPanel:getName()
  return self.name
end

function PlayerPanel:getHash()
  return self.hash
end

function PlayerPanel:addListener(parent, listener)
  table.insert(self.listeners, {parent, listener})
end

function PlayerPanel:setReady(bool)
  self.indicatorColor = bool and self.indicatorReadyColor or self.indicatorNotReadyColor
end

function PlayerPanel:getWidth()
  return self.width
end

function PlayerPanel:getHeight()
  return self.height
end

function PlayerPanel:getX()
  return self.x
end

function PlayerPanel:getY()
  return self.y
end

function PlayerPanel:setErrors(errors)
  self.errors = errors
  createErrorText(self)
end

function PlayerPanel:setPoints(points)
  self.points = points
  createPoints(self)
end

function PlayerPanel.create(x, y, width, height)
  local self = setmetatable({}, PlayerPanel)
  self.x = x
  self.y = y
  self.width = width
  self.height = height
  self.name = "loading"
  self.hash = ""
  self.box = {"fill", x, y, width, height}
  self.border = {"line", x, y, width, height}
  self.readyIndicator = {"fill", 0, 0, 0, 0}
  self.backgroundColor = {0, 0, 0}
  self.textColor = {255, 255, 255}
  self.borderColor = {255, 255, 255}
  self.errorColor = {255, 0, 0}
  self.indicatorReadyColor = {0, 128, 0}
  self.indicatorNotReadyColor = {128, 128, 128}
  self.indicatorColor = self.indicatorNotReadyColor
  self.font = nil
  self.errors = 0
  self.errorText = {}
  self.points = 0
  self.pointsText = {}
  self.show = {}
  self.readyCheckbox = {}
  self.listeners = {}
  self.nameChangeListeners = {}
  createFont(self)
  createIcon(self)
  createName(self)
  createErrorText(self)
  createPoints(self)
  createShowTable(self)
  createReadyIndicator(self)
  createReadyCheckbox(self)
  createNameChange(self)
  return self
end

return PlayerPanel.create(0, 0, 0, 0)