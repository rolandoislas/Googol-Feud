local button = require "/gui/Button"
local states = require "/data/States"
local server = require "/net/server/LobbyServer"
local client = require "/net/client/LobbyClient"
local panel = require "/gui/PlayerPanel"
local mb = require "/gui/MessageBox"
local sattes = require "/data/States"
local textUtil = require "/util/TextUtil"
local json = require "/util/Json"

Lobby = {}
Lobby.__index = Lobby

setmetatable(Lobby, {
  __call = function (cls, ...)
    return cls.create(...)
  end,
})

local function returnToMenu(self, event)
  self.state:enterState(states.MENU)
end

local function createBackButton(self)
  local window = {love.window.getMode()}
  local width = window[1] * .055
  local height = window[2] * .05
  local x = self.players[#self.players]:getX()
  local y = self.players[#self.players]:getY() + self.players[#self.players]:getHeight()
  self.backButton = button.create(x, y, width, height)
  self.backButton:addListener(self, returnToMenu)
  self.backButton:setText("Exit")
  self.backButton:setFont(height)
end

local function startServer(self)
  if not self.host then return end
  self.server = server.create()
  self.server:start()
end

local function saveNameAndEmail(self, name, email)
  local data = {}
  data.name = name
  data.email = email
  love.filesystem.write("gravatar/profile.json", json:encode(data))
end

local function loadNameAndEmail(self)
  if not love.filesystem.exists("gravatar/profile.json") then saveNameAndEmail(self, "", "") end
  local profile = love.filesystem.read("gravatar/profile.json")
  local data = json:decode(profile)
  self.client:sendNameChange(data.name, data.email)
end

local function startClient(self)
  self.client = client.create(self, self.ip)
  self.client:connect()
end

local function readyClicked(self, checkbox)
  if checkbox:isChecked() then
    self.client:sendReady(true)
  else
    self.client:sendReady(false)
  end
end

local function nameChangeRequested(self)
  self.nameChangeWindow:show()
end

local function createPlayerPanels(self)
  self.players = {}
  local window = {love.window.getMode()}
  local x = 0
  local y = 0
  local width = window[1] * .45
  local height = window[2] * .15
  for i = 1, 2 do
    local pp = panel.create(x, y, width, height)
    pp:showPoints(false)
    pp:showErrors(false)
    pp:showReady(true)
    pp:addListener(self, readyClicked)
    pp:addNameChangeListener(self, nameChangeRequested)
    table.insert(self.players, pp)
    y = y + height
  end
end

local function createErrorMessage(self)
  local window = {love.window.getMode()}
  local width = window[1] * .4
  local height = window[2] * .2
  local x = window[1] / 2 - width / 2
  local y = window[2] / 2 - height / 2
  self.errorMessage = mb.create(x, y, width, height)
  self.errorMessage:setTitle("Error")
  self.errorMessage:addListener(self, returnToMenu)
end

local function sendStart(self)
  self.client:sendStart()
end

local function createStartButton(self)
  self.buttonStart = button.create(self.backButton:getX() + self.backButton:getWidth() + self.backButton:getWidth() * .1, self.backButton:getY(), self.backButton:getWidth() * 3, self.backButton:getHeight())
  self.buttonStart:setText("Start Game")
  self.buttonStart:setFont(self.buttonStart:getHeight())
  self.buttonStart:addListener(self, sendStart)
  self.buttonStart:hide()
end

local function changeName(self, window, event, name, email)
  self.nameChangeWindow:hide()
  self.client:sendNameChange(name, email)
  saveNameAndEmail(self, name, email)
end

local function createNameChangeWindow(self)
  local window = {love.window.getMode()}
  local width = window[1] * .4
  local height = window[2] * .2
  local x = window[1] / 2 - width / 2
  local y = window[2] / 2 - height / 2
  self.nameChangeWindow = mb.create(x, y, width, height)
  self.nameChangeWindow:setTitle("Change Name")
  self.nameChangeWindow:showNameChange(true)
  self.nameChangeWindow:addListener(self, changeName)
end

function Lobby:enter(state)
  self.state = state
  createPlayerPanels(self)
  createBackButton(self)
  createErrorMessage(self)
  createStartButton(self)
  createNameChangeWindow(self)
  startServer(self)
  startClient(self)
end

function Lobby:leave()
  if self.host then self.server:stop() end
  self.client:stop()
end

function Lobby:update()
  -- Button
  self.backButton:update()
  self.buttonStart:update()
  -- Net
  self.client:update()
  if self.server ~= nil and self.host then self.server:update() end
  -- Error
  self.errorMessage:update()
  -- Name change window
  self.nameChangeWindow:update()
end

function Lobby:draw()
  -- Button
  self.backButton:draw()
  self.buttonStart:draw()
  -- Players
  for k, panel in pairs(self.players) do
    panel:draw()
  end
  -- Error
  self.errorMessage:draw()
  -- Name change
  self.nameChangeWindow:draw()
end

function Lobby:mousepressed(x, y, button)
  self.backButton:mousepressed(x, y, button)
  for k, panel in pairs(self.players) do
    panel:mousepressed(x, y, button)
  end
  self.errorMessage:mousepressed(x, y, button)
  self.buttonStart:mousepressed(x, y, button)
  self.nameChangeWindow:mousepressed(x, y, button)
end

function Lobby:setIP(ip)
  self.ip = ip
end

function Lobby:setHost(host)
  self.host = host
end

function Lobby:setPlayer(id, name, hash)
  id = tonumber(id)
  hash = hash or ""
  self.players[id]:setName(name)
  self.players[id]:setHash(hash)
end

function Lobby:setPID(id)
  id = tonumber(id)
  self.id = id
  self.players[id]:showReadyCheckbox(true)
  self.players[id]:showNameChange(true)
  loadNameAndEmail(self)
end

function Lobby:setPlayerReady(id, bool)
  id = tonumber(id)
  bool = bool == "true"
  self.players[id]:setReady(bool)
end

function Lobby:error(message)
  message = message or "Unknown error"
  self.errorMessage:setMessage(message)
  self.errorMessage:show()
end

function Lobby:canStart(bool)
  bool = bool == "true"
  if not self.host then return end
  if bool then
    self.buttonStart:show()
  else
    self.buttonStart:hide()
  end
end

function Lobby:storePeers(...)
  local game = self.state:getState(states.GAME)
  local peers = {...}
  game:setClientPort(textUtil:split(peers[self.id], ":")[2])
  print(self.client:getServerPeer())
  game:setIP(textUtil:split(tostring(self.client:getServerPeer()), ":")[1])
  if not self.host then return end
  game:storePeers(...)
  game:setHost(true)
  game:storePlayerData(self.players)
end

function Lobby:start()
  self.state:enterState(states.GAME)
end

function Lobby:textinput(text)
  self.nameChangeWindow:textinput(text)
end

function Lobby:keypressed(key)
  self.nameChangeWindow:keypressed(key)
end

function Lobby.create()
  local self = setmetatable({}, Lobby)
  self.backbutton = {}
  self.ip = "localhost"
  self.host = false
  self.players = {}
  self.id = nil
  return self
end

return Lobby.create()