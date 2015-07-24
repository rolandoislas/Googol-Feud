local codec = require "/net/common/Codec"
local md5 = require "/util/md5"

LobbyServer = {}
LobbyServer.__index = LobbyServer

setmetatable(LobbyServer, {
  __call = function (cls, ...)
    return cls.create(...)
  end,
})

local PLAYER_LIMIT = 2

local function getPlayer(self, id)
  return self.players[id]
end

local function sendGamestate(self)
  for k, player in pairs(self.players) do
    local playerInfo = codec:encode(codec.CLIENT_CODE.player, k, player.name, player.hash)
    self.host:broadcast(playerInfo)
    self.host:broadcast(codec:encode(codec.CLIENT_CODE.ready, k, player.ready))
  end
end

local function setPlayer(self, id, peer)
  self.players[id] = {}
  self.players[id].peer = peer
  self.players[id].name = "Player " .. tostring(id)
  self.players[id].hash = ""
  self.players[id].ready = false
end

local function getIDFromPeer(self, peer)
  for k, v in pairs(self.players) do
    if v.peer == peer then
      return k
    end
  end
end

local function canStart(self)
  local ready = 0
  for k, player in pairs(self.players) do
    if player.ready then
      ready = ready + 1
    end
  end
  return ready == #self.players
end

local function sendCanStart(self)
  self.host:broadcast(codec:encode(codec.CLIENT_CODE.canStart, canStart(self)))
end

local function doStart(self)
  self.host:broadcast(codec:encode(codec.CLIENT_CODE.bigData, self.players[1].peer, self.players[2].peer)) -- TODO hard-coded 2 players
  self.host:broadcast(codec:encode(codec.CLIENT_CODE.start))
end

local function handleReceive(self, event)
  print("Server: ", event.data, event.peer)
  local data = codec:decode(event.data)
  if data[1] == codec.SERVER_CODE.ready then
    local ready = data[2] == "true"
    getPlayer(self, getIDFromPeer(self, event.peer)).ready = ready
    sendGamestate(self)
    sendCanStart(self)
  elseif data[1] == codec.SERVER_CODE.start and canStart(self) then
    doStart(self)
  elseif data[1] == codec.SERVER_CODE.nameChange then
    local player = getPlayer(self, getIDFromPeer(self, event.peer))
    player.name = (data[2] ~= nil and data[2] ~= "") and data[2] or player.name
    player.hash = (data[3] ~= nil and data[3] ~= "") and md5.sumhexa(data[3]) or player.hash
    sendGamestate(self)
  end
end

local function handleConnect(self, event)
  print(tostring(event.peer) .. " connected to lobby server.")
  if table.getn(self.players) < PLAYER_LIMIT then
    local player = table.getn(self.players) + 1
    setPlayer(self, player, event.peer)
    sendGamestate(self)
    event.peer:send(codec:encode(codec.CLIENT_CODE.whoami, player))
  else
    event.peer:send(codec:encode(codec.CLIENT_CODE.die, "No slots left in lobby."))
  end
end

function LobbyServer:update()
  local event = self.run and self.host:service() or nil
  while event do
    if event.type == "receive" then
      handleReceive(self, event)
    elseif event.type == "connect" then
      handleConnect(self, event)
    elseif event.type == "disconnect" then
      print(tostring(event.peer) .. " disconnected.")
    end
    event = self.host:service()
  end
end

function LobbyServer:start()
  self.run = true
  self.host = enet.host_create("*:45052")
end

function LobbyServer:stop()
  self.run = false
  self.host:destroy()
end

function LobbyServer.create()
  local self = setmetatable({}, LobbyServer)
  self.players = {}
  return self
end

return LobbyServer.create()