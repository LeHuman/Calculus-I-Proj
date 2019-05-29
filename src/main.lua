local _NULLFUNC = function()
    return 0
end
local runner = _NULLFUNC
local setFunc = false
local shift = false
local ctrl = false
local alt = false

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

local window = {width = 1000, height = 600}
local center = {x = window.width / 2, y = window.height / 2}
local scale = {x = 1, y = 1}

local screenPrint = ''

function guiPrint(...)
    local args = {...}
    -- table.insert(args, 1, screenPrint)
    for i = 1, #args do
        args[i] = tostring(args[i])
    end
    screenPrint = table.concat(args, '\t') .. '\r\n'
    print(screenPrint)
end

function love.keypressed(k)
    if k == 'home' then
        center = {x = window.width / 2, y = window.height / 2}
        scale = {x = 1, y = 1}
    end
    if k == 'lshift' or k == 'rshift' then
        shift = true
    end
    if k == 'lctrl' or k == 'rctrl' then
        ctrl = true
    end
    if k == 'lalt' or k == 'ralt' then
        alt = true
    end

    if k == 'f2' then
        guiPrint('Function Set')
        setFunction()
    elseif k == 'f1' then
        guiPrint([[
Press any key to begin creating function
---------------------- NOTE! ---------------------------
implicit multiplication '4x' will not work, it must be '4*x'
sqrt is just 'sqrt(x)'
make sure to only use '()'' for parenthesis]])
        setFunc = ''
    elseif setFunc then
        if #k == 1 then
            if shift then
                if shiftKeys[k] then
                    k = shiftKeys[k]
                end
                setFunc = setFunc .. string.upper(k)
            else
                setFunc = setFunc .. k
            end
        elseif k == 'backspace' then
            setFunc = string.sub(setFunc, 1, #setFunc - 1)
        end
        guiPrint('Setting Function: ' .. setFunc)
    end
end

function love.keyreleased(k)
    if k == 'lshift' or k == 'rshift' then
        shift = false
    end
    if k == 'lctrl' or k == 'rctrl' then
        ctrl = false
    end
    if k == 'lalt' or k == 'ralt' then
        alt = false
    end
end

function setFunction()
    if not setFunc then
        return
    end

    runner =
        loadstring(
        [[return
    function(x)
        local log = math.log10
        local tan = math.tan
        local sin = math.sin
        local cos = math.cos
        local ln = math.log
        local sqrt = math.sqrt
        local abs = math.abs
        return ]] ..
            setFunc .. ' end'
    )

    local state, error = pcall(runner, 1.5)
    if not state or (state and not error) then
        runner = _NULLFUNC
        print(error)
        guiPrint('Error Setting Function!')
    else
        runner = runner()
        setFunc = false
    end
end

function love.mousepressed(x, y, button)
end

function love.mousereleased(_, _, button)
end

function love.mousemoved(x, y)
end

local function clamp(v, min, max)
    return math.max(min, math.min(v, max))
end

function love.load()
    love.graphics.setPointSize(2)
    love.graphics.setLineWidth(2)
    love.window.setMode(window.width, window.height)
    love.window.setTitle('Mathinator Thing V0.1')
end
local linePnts
function love.update(dt)
    linePnts = {}
    for x = -1000, 1000 do
        local y = runner(x)
        linePnts[#linePnts + 1] = center.x + x / scale.x
        linePnts[#linePnts + 1] = center.y - y / scale.y
    end

    local d = shift and 10 or alt and 0.01 or 1

    if love.keyboard.isDown('up') then
        if ctrl then
            scale.y = clamp(scale.y - d, 0.0001, 1000)
        else
            center.y = center.y - d
        end
    end
    if love.keyboard.isDown('down') then
        if ctrl then
            scale.y = clamp(scale.y + d, 0.0001, 1000)
        else
            center.y = center.y + d
        end
    end
    if love.keyboard.isDown('left') then
        if ctrl then
            scale.x = clamp(scale.x - d, 0.0001, 1000)
        else
            center.x = center.x - d
        end
    end
    if love.keyboard.isDown('right') then
        if ctrl then
            scale.x = clamp(scale.x + d, 0.0001, 1000)
        else
            center.x = center.x + d
        end
    end
end

function love.draw()
    love.graphics.print(screenPrint, 10, 10)
    love.graphics.setColor(1, 0, 0)
    love.graphics.points(center.x, center.y)
    love.graphics.setColor(1, 1, 1)
    love.graphics.line(linePnts)
end
