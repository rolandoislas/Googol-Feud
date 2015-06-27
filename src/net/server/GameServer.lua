local enet = require "enet"
local codec = require "/net/common/Codec"
local ac = require "/util/Ac"

GameServer = {}
GameServer.__index = GameServer

setmetatable(GameServer, {
  __call = function (cls, ...)
    return cls.create(...)
  end,
})

local function getPlayer(self, id)
  return self.players[id]
end

local function sendGamestate(self)
  for k, player in pairs(self.players) do
    self.host:broadcast(codec:encode(codec.G_CLIENT_CODE.player, k, player.name, player.hash, player.errors, player.points))
  end
  self.host:broadcast(codec:encode(codec.G_CLIENT_CODE.acData, ac:toString(self.acData)))
  self.host:broadcast(codec:encode(codec.G_CLIENT_CODE.guess, unpack(self.guess)))
end

local function allItemsGuessed(self)
  for k, v in pairs(self.guess) do
    if not v then return false end
  end
  return true
end

local function getOtherPlayer(self)
  return self.activePlayer == 1 and 2 or 1
end

local function getCurrentPoints(self)
  local points = 0
  for k, v in pairs(self.guess) do
    if v then
      points = points + (#self.guess - k + 1)
    end
  end
  return points
end

local function enableAllTiles(self)
  for k, v in pairs(self.guess) do
    self.guess[k] = true
  end
end

local function disableAllTiles(self)
  for k, v in pairs(self.guess) do
    self.guess[k] = false
  end
end

local function getWinner(self)
  local winner = 0
  if self.players[1].points > self.players[2].points then
    winner = 1
  elseif self.players[2].points > self.players[1].points then
    winner = 2
  end
  return winner
end

local function startNewRound(self)
  self.host:broadcast(codec:encode(codec.G_CLIENT_CODE.turn, 0))
  self.hasPassed = false
  self.players[self.activePlayer].errors = 0
  self.players[getOtherPlayer(self)].errors = 0
  enableAllTiles(self)
  if self.turn == 4 then
    local winner = getWinner(self)
    if winner > 0 then
      self.host:broadcast(codec:encode(codec.G_CLIENT_CODE.win, self.players[winner].name .. " is victorious."))
      return
    else
      self.turn = self.turn - 1
    end
  end
  self.newTurnTime = love.timer.getTime()
  self.host:broadcast(codec:encode(codec.G_CLIENT_CODE.intermission))
end

local function checkEnd(self)
  if self.players[self.activePlayer].errors == 3 and self.players[getOtherPlayer(self)].errors == 0 then -- Pass
    self.activePlayer = getOtherPlayer(self)
    self.hasPassed = true
    self.host:broadcast(codec:encode(codec.G_CLIENT_CODE.turn, self.activePlayer))
    self.host:broadcast(codec:encode(codec.G_CLIENT_CODE.turnInfo, self.turn))
  elseif self.hasPassed and self.players[self.activePlayer].errors == 1 then -- Give points to initial round player
    self.players[getOtherPlayer(self)].points = self.players[getOtherPlayer(self)].points + getCurrentPoints(self)
    startNewRound(self)
  elseif self.hasPassed and self.players[self.activePlayer].errors == 0 then -- Give points to stealing player
    self.players[self.activePlayer].points = self.players[self.activePlayer].points + getCurrentPoints(self)
    startNewRound(self)
  elseif allItemsGuessed(self) then -- Give points to initial round player
    self.players[self.activePlayer].points = self.players[self.activePlayer].points + getCurrentPoints(self)
    self.activePlayer = getOtherPlayer(self)
    self.host:broadcast(codec:encode(codec.G_CLIENT_CODE.turnInfo, self.turn))
    startNewRound(self)
  end
  sendGamestate(self)
end

local function handleGuess(self, guess)
  guess = guess or ""
  local correct = false
  local index = 0
  for i = 1, self.numOfTiles do
    if (not self.guess[i]) and self.acData[2][i]:lower() == self.acData[1]:lower() .. guess:lower() then
      self.guess[i] = true
      correct = true
      self.index = i
    end
  end
  if not correct then
    self.players[self.activePlayer].errors = self.players[self.activePlayer].errors + 1
  end
  checkEnd(self)
end

local function getIDFromPeer(self, peer)
  for k, v in pairs(self.players) do
    if tostring(v.peer) == tostring(peer) then
      return k
    end
  end
end

local function handleReceive(self, event)
  print("Server: ", event.data, event.peer)
  local data = codec:decode(event.data)
  if data[1] == codec.G_SERVER_CODE.guess then
    handleGuess(self, data[2])
  end
end

local function checkStart(self)
  local ready = true
  for k, v in pairs(self.players) do
    if not v.joined then ready = false end
  end
  if ready then
    self.activePlayer = love.math.random(1, 2)
    self.host:broadcast(codec:encode(codec.G_CLIENT_CODE.turn, self.activePlayer))
    self.host:broadcast(codec:encode(codec.G_CLIENT_CODE.turnInfo, self.turn))
  end
end

local function handleConnect(self, event)
  print(tostring(event.peer) .. " connected to server.")
  local player = getIDFromPeer(self, event.peer)
  if not self.players[player] then self.players[player] = {} end
  self.players[player].peer = event.peer
  self.players[player].joined = true
  sendGamestate(self)
  event.peer:send(codec:encode(codec.G_CLIENT_CODE.whoami, player))
  checkStart(self)
end

local function startNewTurn(self)
  self.turn = self.turn + 1
  disableAllTiles(self)
  self.host:broadcast(codec:encode(codec.G_CLIENT_CODE.turn, self.activePlayer))
  self.host:broadcast(codec:encode(codec.G_CLIENT_CODE.turnInfo, self.turn))
  self.acData = ac:getRandom()
  sendGamestate(self)
end

function GameServer:update()
  if self.newTurnTime ~= nil and self.newTurnTime + 10 <= love.timer.getTime() then
    self.newTurnTime = nil
    startNewTurn(self)
  end
  local event = self.run and self.host:service() or nil
  while event do
    if event.type == "receive" then
      handleReceive(self, event)
    elseif event.type == "connect" then
      handleConnect(self, event)
    elseif event.type == "disconnect" then
      print(event.peer .. " disconnected.")
    end
    event = self.host:service()
  end
end

local function setGuessData(self)
  for i = 1, self.numOfTiles do
    table.insert(self.guess, false)
  end
end

function GameServer:start()
  self.host = enet.host_create("localhost:45052")
  self.acData = ac:getRandom()
  setGuessData(self)
end

function GameServer:storePeer(index, peer)
  if not self.players[index] then self.players[index] = {} end
  self.players[index].peer = peer
end

function GameServer:setPlayerData(index, name, hash)
  self.players[index].name = name
  self.players[index].hash = hash
  self.players[index].errors = 0
  self.players[index].points = 0
end

function GameServer:stop()
  self.run = false
  self.host:destroy()
end

function GameServer.create()
  local self = setmetatable({}, GameServer)
  self.players = {}
  self.host = false
  self.acData = {}
  self.guess = {}
  self.numOfTiles = 10
  self.turn = 1
  self.run = true
  return self
end

return GameServer.create()