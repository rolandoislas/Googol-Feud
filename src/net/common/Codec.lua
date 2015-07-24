local textUtil = require "/util/TextUtil"

Codec = {}
Codec.__index = Codec

setmetatable(Codec, {
  __call = function (cls, ...)
    return cls.create(...)
  end,
})

local CLIENT_CODE = {
  player = "player",
  whoami = "whoami",
  ready = "ready",
  die = "die",
  canStart = "canstart",
  bigData = "googol",
  start = "start"
}
local SERVER_CODE = {
  ready = "ready",
  start = "start",
  nameChange = "namechange"
}
local G_CLIENT_CODE = {
  player = "player",
  acData = "ac",
  guess = "guess",
  whoami = "whoami",
  turn = "turn",
  intermission = "intermission",
  turnInfo = "turninfo",
  win = "win"
}
local G_SERVER_CODE = {
  guess = "guess"
}

function Codec:decode(message)
  return textUtil:split(message, self.del)
end

function Codec:encode(...)
  local s = ""
  for k, v in pairs({...}) do
    s = s .. tostring(v)
    if k < table.getn({...}) then
      s = s .. self.del
    end
  end
  return s
end

function Codec.create()
  local self = setmetatable({}, Codec)
  self.SERVER_CODE = SERVER_CODE
  self.CLIENT_CODE = CLIENT_CODE
  self.G_SERVER_CODE = G_SERVER_CODE
  self.G_CLIENT_CODE = G_CLIENT_CODE
  self.del = "/n"
  return self
end

return Codec.create()