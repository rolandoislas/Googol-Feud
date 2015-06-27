State = {}
State.__index = State

setmetatable(State, {
  __call = function (cls, ...)
    return cls.create(...)
  end,
})

local function stub() end

local function getState(self)
  return self.activeState > 0 and self.states[self.activeState] or {update=stub,draw=stub}
end

function State:getState(id)
  return self.states[id]
end

function State:enterState(id)
  if self.activeState > 0 then
    getState(self):leave(self)
  end
  self.activeState = id
  getState(self):enter(self)
end

function State:addState(state)
  table.insert(self.states, state)
  self:enterState(table.getn(self.states))
end

-- Love overrides

function State:draw()
  getState(self):draw(self)
end

function State:update()
  getState(self):update(self)
end

function State:textinput(text)
  local state = getState(self)
  pcall(state.textinput, state, text, self)
end

function State:keyreleased(key)
  local state = getState(self)
  pcall(state.keyreleased, state, key, self)
end

function State:keypressed(key)
  local state = getState(self)
  pcall(state.keypressed, state, key, self)
end

function State:mousepressed(x, y, button)
  local state = getState(self)
  pcall(state.mousepressed, state, x, y, button)
end

function State.create()
  local self = setmetatable({}, State)
  self.states = {}
  self.activeState = 0
  return self
end

return State.create()