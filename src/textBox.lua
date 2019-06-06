local textBox = {}
textBox.__index = textBox

function textBox:draw(active)
    if active then
        love.graphics.setColor(0.8,0.8,0.8)
    else
        love.graphics.setColor(0.6,0.6,0.6,0.3)
    end
    love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
    love.graphics.setColor(1,1,1)
    love.graphics.print(self.txt, self.x+5, self.y + self.h/5)
end

function textBox:update(k, delete)
    if delete then
        self.txt = string.sub(self.txt, 1, #self.txt - 1)
    else
        self.txt = self.txt .. k
    end
    self.func(self.txt)
end

function textBox:chkBox(x, y)
    return x > self.x and x < self.x + self.w and y > self.y and y < self.y + self.h
end

local txtbxs = {}

local shiftKeys = {
    ['`'] = '~',
    ['1'] = '!',
    ['2'] = '@',
    ['3'] = '#',
    ['4'] = '$',
    ['5'] = '%',
    ['6'] = '^',
    ['7'] = '&',
    ['8'] = '*',
    ['9'] = '(',
    ['0'] = ')',
    ['-'] = '_',
    ['='] = '+',
    ['['] = '{',
    [']'] = '}',
    ['\\'] = '|',
    [';'] = ':',
    ["'"] = '"',
    [','] = '<',
    ['.'] = '>',
    ['/'] = '?'
}

local textBoxM = {}
local isDown = love.keyboard.isDown
local active = 'nil'

function textBoxM.update(k)
    if not k then return end
    local delete = false
    local char = false
    if #k == 1 then
        if isDown('lshift') or isDown('rshift') then
            if shiftKeys[k] then
                k = shiftKeys[k]
            end
            char = string.upper(k)
        else
            char = k
        end
    elseif k == 'backspace' then
        delete = true
    elseif k == 'space' then
        char = ' '
    end
    if active ~= 'nil' and (delete or type(char) == 'string') then
        txtbxs[active]:update(char, delete)
    end
end

function textBoxM.activateTextBox()
    local mx, my = love.mouse.getPosition()
    for i, txt in pairs(txtbxs) do
        if txt:chkBox(mx, my) then
            active = i
            return
        end
    end
    active = 'nil'
end

function textBoxM.draw()
    for i, txt in pairs(txtbxs) do
        txt:draw(i == active)
    end
end

function textBoxM.isActive(ID)
    if ID then
        return active == ID
    end
    return active ~= 'nil'
end

function textBoxM.new(x, y, w, h, ID, func)
    local o = {}
    o.x = x
    o.y = y
    o.w = w
    o.h = h
    o.txt = ''
    o.func = func
    setmetatable(o, textBox)
    txtbxs[ID] = o
end

return textBoxM