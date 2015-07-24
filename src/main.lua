local state = require "util/State"
local game = require "state/Game"
local lobby = require "state/Lobby"
local menu = require "state/Menu"
local joinMenu = require "state/JoinMenu"
local states = require "data/States"

local RES = {
  {1280, 720},
  {1600, 900},
  {800, 600}
}

local function addStates()
  state:addState(game)
  state:addState(lobby)
  state:addState(menu)
  state:addState(joinMenu)
end

function love.load(arg)
  love.window.setTitle("Googol Feud")
  love.window.setMode(unpack(RES[1]))
  --love.window.setFullscreen(true)
  addStates()
  state:enterState(states.MENU)
end

function love.draw()
  state:draw()
end

function love.update()
  state:update()
end

function love.textinput(text)
  state:textinput(text)
end

function love.keyreleased(key)
  state:keyreleased(key)
end

function love.keypressed(key)
  state:keypressed(key)
end

function love.mousepressed(x, y, button)
  state:mousepressed(x, y, button)
end