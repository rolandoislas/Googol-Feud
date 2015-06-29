local enet = require "enet"
local codec = require "/net/common/Codec"

GameClient = {}
GameClient.__index = GameClient

setmetatable(GameClient, {
  __call = function (cls, ...)
    return cls.create(...)
  end,
})

local function handleReceive(self, event)
  print("Client: ", event.data, event.peer)
  local data = codec:decode(event.data)
  if data[1] == codec.G_CLIENT_CODE.player then
    self.game:setPlayerData(data[2], data[3], data[4], data[5], data[6])
  elseif data[1] == codec.G_CLIENT_CODE.acData then
    self.game:setAcData(data[2])
  elseif data[1] == codec.G_CLIENT_CODE.guess then
    table.remove(data, 1)
    self.game:setGuessData(data)
  elseif data[1] == codec.G_CLIENT_CODE.whoami then
    self.game:setPlayer(data[2])
  elseif data[1] == codec.G_CLIENT_CODE.turn then
    self.game:setTurn(data[2])
  elseif data[1] == codec.G_CLIENT_CODE.intermission then
    self.game:setIntermission()
  elseif data[1] == codec.G_CLIENT_CODE.turnInfo then
    self.game:setTurnInfo(data[2])
  elseif data[1] == codec.G_CLIENT_CODE.win then
    self.game:doWin(data[2])
  end
end

function GameClient:update()
  local event = self.host:service()
  while event do
    if event.type == "receive" then
      handleReceive(self, event)
    elseif event.type == "connect" then
    elseif event.type == "disconnect" then
    end
    event = self.run and self.host:service() or nil
  end
end

function GameClient:connect()
  self.host = enet.host_create(self.port and "*:" .. self.port or "*:*")
  self.server = self.host:connect(self.ip .. ":45052")
end

function GameClient:sendGuess(text)
  self.server:send(codec:encode(codec.G_SERVER_CODE.guess, text))
end

function GameClient:stop()
  self.run = false
  self.host:destroy()
end

function GameClient.create(game, port, ip)
  local self = setmetatable({}, GameClient)
  self.game = game
  self.port = port
  self.run = true
  self.ip = ip
  return self
end

return GameClient.create(0)