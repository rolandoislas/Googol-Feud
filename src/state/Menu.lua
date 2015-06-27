local button = require "/gui/Button"
local states = require "/data/States"

Menu = {}
Menu.__index = Menu

local function changeMenu(self, menu)
  self:createMenu(menu)
end

local function setState(self, state)
  self.state:enterState(state)
end

local function startLobby(self)
  local lobby = self.state:getState(states.LOBBY)
  lobby:setIP("localhost")
  lobby:setHost(true)
  self.state:enterState(states.LOBBY)
end

local menuData = {
  ["main"] = {
    {"Multiplayer", function (...) changeMenu(..., "multiplayer") end},
    {"Exit", function () love.event.quit() end}
  },
  ["multiplayer"] = {
    {"Join", function (...) setState(..., states.JOIN_MENU) end},
    {"Host", function (...) startLobby(...) end},
    {"Back", function (...) changeMenu(..., "main") end}
  }
}

function Menu:createMenu(menu)
  self.buttons = {}
  local window = {love.window.getMode()}
  local width = window[1] * .15
  local height = window[2] * .035
  local x = 0
  local y = 0
  for k, v in pairs(menuData[menu]) do
    local but = button.create(x, y, width, height)
    but:addListener(self, v[2])
    but:setText(v[1])
    but:setBackgroundColor("blur", 0, 0, 0)
    but:setFont(height)
    table.insert(self.buttons, but)
    y = y + height
  end
end

function Menu:draw(state)
  for k, v in pairs(self.buttons) do
    v:draw()
  end
end

function Menu:update(state)
  for k, v in pairs(self.buttons) do
    v:update()
  end
end

function Menu:enter(state)
  self.state = state
  self:createMenu("main")
end

function Menu:leave(state)
  
end

function Menu:mousepressed(x, y, button)
  for k, v in pairs(self.buttons) do
    v:mousepressed(x, y, button)
  end
end

function Menu.create()
  local self = setmetatable({}, Menu)
  self.buttons = {}
  return self
end

setmetatable(Menu, {
  __call = function (cls, ...)
    return cls.create(...)
  end,
})

return Menu.create()