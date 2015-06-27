local http = require "socket.http"
local url = require "socket.url"
local json = require "/util/Json"

Ac = {}
Ac.__index = Ac

setmetatable(Ac, {
  __call = function (cls, ...)
    return cls.create(...)
  end,
})

local API_URL = "http://suggestqueries.google.com/complete/search?client=chrome&q="

local function loadList(self)
  local list = {}
  for line in love.filesystem.lines("/resources/list.csv") do
    table.insert(list, line)
  end
  return list
end

local function getRawData(self, query)
  local d, c, h = http.request(API_URL .. url.escape(query .. " "))
  if c ~= 200 then error() end
  return json:decode(d)
end

local function cleanData(self, data)
  for k, v in pairs(data[2]) do
    if string.find(v, '://') ~= nil or string.find(v, '/') ~= nil then
      table.remove(data[2], k)
    end
    --data[2][k] = string.sub(v, string.len(data[1]))
  end
  return data
end

local function getData(self, query)
  local data = getRawData(self, query)
  data = cleanData(self, data)
  return data
end

function Ac:getRandom(t)
  local list = loadList(self)
  local query = list[love.math.random(1, table.getn(list))]
  local data = getData(self, query)
  return t == "json" and json:encode(data) or data
end

function Ac:toString(data)
  return json:encode(data)
end

function Ac:toTable(s)
  return json:decode(s)
end

function Ac.create()
  local self = setmetatable({}, Ac)
  return self
end

return Ac.create()