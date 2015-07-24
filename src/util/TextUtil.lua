TextUtil = {}
TextUtil.__index = TextUtil

setmetatable(TextUtil, {
  __call = function (cls, ...)
    return cls.create(...)
  end,
})

function TextUtil:resizeFontForLine(text, width, font, fontSize)
  local fw, fl = font:getWrap(text, width)
  return love.graphics.newFont(fontSize / (fl > 0 and fl or 1))
end

function TextUtil:getTextWidth(text, font)
  return font:getWidth(text)
end

function TextUtil:getTextHeight(text, font)
  return font:getHeight(text)
end

function TextUtil.create()
  local self = setmetatable({}, TextUtil)
  return self
end

-- split snippet from Lua-Users.org
function TextUtil:split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
        table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

return TextUtil.create()