local codec = require "/net/common/Codec"

LobbyClient = {}
LobbyClient.__index = LobbyClient

setmetatable(LobbyClient, {
  __call = function (cls, ...)
    return cls.create(...)
  end,
})

local function handleReceive(self, event)
  print("Client: ", event.data, event.peer)
  local data = codec:decode(event.data)
  if data[1] == codec.CLIENT_CODE.player then
    self.lobby:setPlayer(data[2], data[3], data[4])
  elseif data[1] == codec.CLIENT_CODE.whoami then
    self.lobby:setPID(data[2])
  elseif data[1] == codec.CLIENT_CODE.ready then
    self.lobby:setPlayerReady(data[2], data[3])
  elseif data[1] == codec.CLIENT_CODE.die then
    self.lobby:error(data[2])
  elseif data[1] == codec.CLIENT_CODE.canStart then
    self.lobby:canStart(data[2])
  elseif data[1] == codec.CLIENT_CODE.bigData then
    self.lobby:storePeers(data[2], data[3]) -- TODO hard-coded 2 players
  elseif data[1] == codec.CLIENT_CODE.start then
    self.lobby:start()
  end
end

function LobbyClient:update()
  local event = self.client:service()
  while event do
    if event.type == "receive" then
      handleReceive(self, event)
    elseif event.type == "connect" then
    elseif event.type == "disconnect" then
    end
    event = self.run and self.client:service() or nil
  end
end

function LobbyClient:connect()
  self.run = true
  self.client = enet.host_create()
  self.server = self.client:connect(self.ip .. ":45052")
end

function LobbyClient:sendReady(bool)
  self.server:send(codec:encode(codec.SERVER_CODE.ready, bool))
end

function LobbyClient:sendStart()
  self.server:send(codec:encode(codec.SERVER_CODE.start))
end

function LobbyClient:stop()
  self.run = false
  self.client:destroy()
end

function LobbyClient:getServerPeer()
  return self.server
end

function LobbyClient:sendNameChange(name, email)
  self.server:send(codec:encode(codec.SERVER_CODE.nameChange, name, email))
end

function LobbyClient.create(lobby, ip)
  local self = setmetatable({}, LobbyClient)
  self.lobby = lobby
  self.ip = ip
  return self
end

return LobbyClient.create("localhost")