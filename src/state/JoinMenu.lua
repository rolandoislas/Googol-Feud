local tf = require "/gui/TextField"
local button = require "/gui/Button"
local states = require "/data/States"
local textUtil = require "/util/TextUtil"

JoinMenu = {}
JoinMenu.__index = JoinMenu

function JoinMenu:draw(state)
  self.connectButton:draw()
  self.backButton:draw()
  self.textField:draw()
end

function JoinMenu:update(state)
  self.connectButton:update()
  self.backButton:update()
  self.textField:update()
end

local function returnToMenu(self)
  self.state:enterState(states.MENU)
end

local function connect(self)
  local lobby = self.state:getState(states.LOBBY)
  lobby:setIP(self.textField:getText() ~= "" and self.textField:getText() or "localhost" )
  lobby:setHost(false)
  self.state:enterState(states.LOBBY)
end

local function createConnectButton(self)
  local text = "Connect"
  local window = {love.window.getMode()}
  local height = window[2] * .04
  local width = textUtil:getTextWidth(text, love.graphics.newFont(height))
  local x = self.textField:getX() + self.textField:getWidth() - self.backButton:getWidth() - width - width * .05
  local y = self.textField:getY() + self.textField:getHeight()
  self.connectButton = button.create(x, y, width, height)
  self.connectButton:setFont(height)
  self.connectButton:setText(text)
  self.connectButton:addListener(self, connect)
  self.connectButton:setBackgroundColor("blur", 0, 0, 0)
  
end

local function createBackButton(self)
  local window = {love.window.getMode()}
  local width = window[1] * .05
  local height = window[2] * .04
  local x = self.textField:getX() + self.textField:getWidth() - width
  local y= self.textField:getY() + self.textField:getHeight()
  self.backButton = button.create(x, y, width, height)
  self.backButton:setText("Back")
  self.backButton:setFont(height)
  self.backButton:addListener(self, returnToMenu)
  self.backButton:setBackgroundColor("blur", 0, 0, 0, 128)
end

local function createTextField(self)
  local window = {love.window.getMode()}
  local width = window[1] * .6
  local height = window[2] * .05
  local x = window[1] / 2 - width / 2
  local y= window[2] / 2 - height
  self.textField = tf.create("", x, y, width, height)
  self.textField:setTextColor(255, 255, 255)
  self.textField:setBackgroundColor(0, 0, 0, 128)
  self.textField:setBorderColor(255, 255, 255)
  self.textField:setFont(love.graphics.newFont(height))
end

function JoinMenu:enter(state)
  self.state = state
  createTextField(self)
  createBackButton(self)
  createConnectButton(self)
end

function JoinMenu:leave(state)
  
end

function JoinMenu:textinput(text)
  self.textField:textinput(text)
end

function JoinMenu:keypressed(key)
  self.textField:keypressed(key)
end

function JoinMenu:mousepressed(x, y, button)
  self.backButton:mousepressed(x, y, button)
  self.connectButton:mousepressed(x, y, button)
end

function JoinMenu.create()
  local self = setmetatable({}, JoinMenu)
  self.textField = {}
  self.connectButton = {}
  self.backButton = {}
  return self
end

setmetatable(JoinMenu, {
  __call = function (cls, ...)
    return cls.create(...)
  end,
})

return JoinMenu.create()