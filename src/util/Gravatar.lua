local http = require "socket.http"

Gravatar = {}
Gravatar.__index = Gravatar

local GRAVATAR_URL = "http://www.gravatar.com/avatar/"
local ICON_PARAM = "?d=retro"

setmetatable(Gravatar, {
  __call = function (cls, ...)
    return cls.create(...)
  end,
})

local function checkHash(hash)
  return (hash == "" or hash == nil) and "default" or hash
end

local function imageExists(hash)
  return love.filesystem.exists("gravatar/" .. hash .. ".jpg")
end

local function downloadImage(hash)
  if not love.filesystem.exists("gravatar") then
    love.filesystem.createDirectory("gravatar")
  end
  local d, c, h = http.request(GRAVATAR_URL .. hash .. ICON_PARAM)
  love.filesystem.write("gravatar/" .. hash .. ".jpg", d)
  print("Downloaded profile icon.")
end

function Gravatar:getImage(hash)
  hash = checkHash(hash)
  if not imageExists(hash) then
    downloadImage(hash)
  end
  return love.graphics.newImage("gravatar/" .. hash .. ".jpg")
end

function Gravatar.create(x, y, width, height)
  local self = setmetatable({}, Gravatar)
  return self
end

return Gravatar.create()