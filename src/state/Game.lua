local ac = require "/util/Ac"
local textUtil = require "/util/TextUtil"
local tf = require "/gui/TextField"
local server = require "/net/server/GameServer"
local client = require "/net/client/GameClient"
local playerPanel = require "/gui/PlayerPanel"
local button = require "/gui/Button"
local states = require "/data/States"

Game = {}
Game.__index = Game

setmetatable(Game, {
  __call = function (cls, ...)
    return cls.create(...)
  end,
})

local function sendMove(self, event)
  self.client:sendGuess(self.textfield:getText())
  self.textfield:clear()
end

local function createTiles(self)
  local window = {love.window.getMode()}
  local width = window[1] * (618 / 1280)
  local height = window[2] * (90 / 720)
  local yMargin = 5
  local xMargin = 5
  local x = (window[1] - (width * 2 + yMargin)) / 2
  local y = window[2] - window[2] * (20 / 720) - (height * (self.numOfTiles / 2) + 
    (yMargin * (self.numOfTiles / 2 - 1)))
  local _y = y
  local numFontSize = height * (40 / 90)
  self.numberFont = love.graphics.newFont(numFontSize)
  for i = 1, self.numOfTiles do
    local rect = {"fill", x, y, width, height}
    local num = {tostring(i), x, y + ((height - numFontSize) / 2), width, "center"}
    local text = {self.acData[2][i] or "", x, y + ((height - numFontSize) / 2), width, "center"}
    local textFont = textUtil:resizeFontForLine(text[1], width, self.numberFont, numFontSize)
    self.tiles[i] = {}
    self.tiles[i][1] = false
    self.tiles[i][2] = rect
    self.tiles[i][3] = num
    self.tiles[i][4] = {}
    self.tiles[i][4][1] = text
    self.tiles[i][4][2] = textFont
    y = y + height + yMargin
    if i == 5 then
      y = _y
      x = x + width + xMargin
    end
  end
end

local function setEmptyTilesActive(self)
  for k, v in pairs(self.tiles) do
    if v[4][1][1] == "" then
      self.tiles[k][1] = true
    end
  end
end

local function createTextField(self)
  local window = {love.window.getMode()}
  local x = self.prompt[1][2]
  local y = self.prompt[1][3] + self.prompt[2]:getHeight() + window[2] * 0.00694
  local width = self.prompt[1][4]
  local height = self.prompt[2]:getHeight()
  local text = ""
  self.textfield = tf.create(text, x, y, width, height)
  self.textfield:setBackgroundColor(255, 255, 255)
  self.textfield:setFont(self.prompt[2])
  self.textfield:addListener(self, sendMove)
end

local function createPrompt(self)
  local window = {love.window.getMode()}
  local width = window[1] * .3
  local height = window[2] * .075
  local x = window[1] / 2 - width / 2
  local y = window[2] * .025
  y = self.tiles[1][2][3] / 2 - height * 1.5
  local text = self.acData[1]
  local font = love.graphics.newFont(height)
  font = TextUtil:resizeFontForLine(text, width, font, height)
  self.prompt[1] = {text, x, y, width, "center"}
  self.prompt[2] = font
end

local function startServer(self)
  if not self.host then return end
  self.server = server.create()
  for k, v in pairs(self.playerData) do
    self.server:storePeer(k, v.peer)
    self.server:setPlayerData(k, v.name, v.hash)
  end
  self.server:start()
end

local function startClient(self)
  self.client = client.create(self, self.clientPort, self.ip)
  self.client:connect()
end

local function createPlayerPanels(self)
  local window = {love.window.getMode()}
  local x = 0
  local y = 0
  local width = window[1] * .25
  local height = window[2] * .15
  self.playerPanels[1] = playerPanel.create(x, y, width, height)
  x = window[1] - width
  self.playerPanels[2] = playerPanel.create(x, y, width, height)
end

local function createInfoMessage(self)
  local window = {love.window.getMode()}
  local x = 0
  local y = self.textfield:getY() + self.textfield:getHeight()
  local limit = window[1]
  self.infoMessage = {"", x, y, limit, "center"}
end

local function exitToMenu(self)
  self.state:enterState(states.MENU)
end

local function createExitButton(self)
  local window = {love.window.getMode()}
  local width = window[1] * 0.06
  local height = window[2] * 0.05
  self.exitButton = button.create(window[1] / 2 - width / 2, window[2] / 2 - height / 2, width, height)
  self.exitButton:setText("Exit")
  self.exitButton:setFont(height)
  self.exitButton:addListener(self, exitToMenu)
  self.exitButton:hide()
end

function Game:enter(state)
  self.state = state
  createTiles(self)
  setEmptyTilesActive(self)
  createPrompt(self)
  createTextField(self)
  createPlayerPanels(self)
  createInfoMessage(self)
  createExitButton(self)
  startServer(self)
  startClient(self)
end

function Game:leave()
  if self.host then self.server:stop() end
  self.client:stop()
  self.numOfTiles = 10
  self.drawPrompt = true
  self.drawTextfield = true
  self.exitButton:hide()
  self.acData = {"what is", {"the universe", "nothing"}}
end

local function drawTiles(self)
  for i = 1, self.numOfTiles do
    love.graphics.setColor(255, 255, 255)
    love.graphics.rectangle(unpack(self.tiles[i][2]))
    love.graphics.setColor(0, 0, 0)
    if self.tiles[i][1] then
      love.graphics.setFont(self.tiles[i][4][2])
      love.graphics.printf(unpack(self.tiles[i][4][1]))
    else
      love.graphics.setFont(self.numberFont)
      love.graphics.printf(unpack(self.tiles[i][3]))
    end
  end
end

local function drawTextField(self)
  if not self.drawTextfield then return end
  self.textfield:draw()
end

local function drawPrompt(self)
  if not self.drawPrompt then return end
  love.graphics.setColor(255, 255, 255)
  love.graphics.setFont(self.prompt[2])
  love.graphics.printf(unpack(self.prompt[1]))
end

local function drawPanels(self)
  for k, v in pairs(self.playerPanels) do
    v:draw()
  end
end

local function drawInfoMessage(self)
  love.graphics.setColor(255, 255, 255)
  love.graphics.setFont(self.prompt[2])
  love.graphics.printf(unpack(self.infoMessage))
end

local function drawExitButton(self)
  self.exitButton:draw()
end

function Game:draw()
  drawTiles(self)
  drawPrompt(self)
  drawTextField(self)
  drawPanels(self)
  drawInfoMessage(self)
  drawExitButton(self)
end

function Game:update()
  self.textfield:update()
  if self.server ~= nil and self.host then self.server:update() end
  self.client:update()
  self.exitButton:update()
end

function Game:textinput(text)
  self.textfield:textinput(text)
end

function Game:keypressed(key)
  self.textfield:keypressed(key)
end

function Game:storePeers(...)
  local peers = {...}
  for k, peer in pairs(peers) do
    self.playerData[k] = {}
    self.playerData[k].peer = peer
  end
end

function Game:setHost(bool)
  self.host = bool
end

function Game:storePlayerData(players)
  for k, panel in pairs(players) do
    self.playerData[k].name = panel:getName()
    self.playerData[k].hash = panel:getHash()
  end
end

function Game:setClientPort(port)
  self.clientPort = port
end

function Game:setPlayerData(index, name, hash, errors, points)
  index = tonumber(index)
  errors = tonumber(errors)
  points = tonumber(points)
  self.playerPanels[index]:setName(name)
  self.playerPanels[index]:setHash(hash)
  self.playerPanels[index]:setErrors(errors)
  self.playerPanels[index]:setPoints(points)
end

function Game:setAcData(s)
  self.acData = ac:toTable(s)
  createTiles(self)
  setEmptyTilesActive(self)
  createPrompt(self)
end

function Game:setGuessData(guess)
  for k, v in pairs(self.tiles) do
    v[1] = guess[k] == "true"
    print(v[1], guess[k])
  end
end

function Game:setPlayer(index)
  index = tonumber(index)
  self.whoami = index
end

function Game:setTurn(player)
  player = tonumber(player)
  if player == self.whoami then
    self.textfield:enableInput()
  else
    self.textfield:disableInput()
  end
end

function Game:setIntermission()
  self.infoMessage[1] = "Intermission"
end

function Game:setTurnInfo(turn)
  if tonumber(self.whoami) == 0 then return end
  local player = ""
  if self.textfield:isInputEnabled() then
    player = self.playerPanels[self.whoami]:getName()
  else
    player = self.playerPanels[self.whoami == 1 and 2 or 1]:getName()
  end
  self.infoMessage[1] = "Round " .. turn .. " - " .. player
end

function Game:doWin(text)
  self.infoMessage[1] = text
  self.numOfTiles = 0
  self.drawPrompt = false
  self.drawTextfield = false
  self.exitButton:show()
end

function Game:mousepressed(x, y, button)
  self.exitButton:mousepressed(x, y, button)
end

function Game:setIP(ip)
  self.ip = ip
end

function Game.create()
  local self = setmetatable({}, Game)
  self.states = {}
  self.activeState = 0
  self.numOfTiles = 10
  self.tiles = {}
  self.numberFont = nil
  self.acData = {"what is", {"the universe", "nothing"}}
  self.prompt = {}
  self.textfield = {}
  self.infoMessage = {}
  self.host = false
  self.ip = "localhost"
  self.playerPanels = {}
  self.playerData = {}
  self.clientPort = 0
  self.whoami = 0
  self.drawTextfield = true
  self.drawPrompt = true
  return self
end

return Game.create()