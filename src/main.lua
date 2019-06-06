local function Memoize(f)
    local mem = {} -- memoizing table
    setmetatable(mem, {__mode = 'kv'}) -- make it weak
    return function(x) -- new version of ’f’, with memoizing
        local r = mem[x]
        if r == nil then -- no previous result?
            r = f(x) -- calls original function
            mem[x] = r -- store result for reuse
        end
        return r
    end
end

local _NULLFUNC = function(x)
    return (math.sin(x + 4) - (x ^ 3)) / 7000
end
_NULLFUNC = Memoize(_NULLFUNC)

local runner = _NULLFUNC
local shift = false
local ctrl = false
local alt = false

local textbox = require 'textBox'

local window = {width = 1000, height = 600}
local center = {x = window.width / 2, y = window.height / 2}
local scale = {x = 0.25, y = 0.25}

local bounds = {low = -120, up = 50}

local screenPrint = ''

local function guiPrint(...)
    local args = {...}
    for i = 1, #args do
        args[i] = tostring(args[i])
    end
    screenPrint = table.concat(args, '\t') .. '\r\n'
    print(screenPrint)
end

local function clamp(v, min, max)
    return math.max(min, math.min(v, max))
end

local rects = {}

local n = 10000000

local function calcIntegral()
    rects = {}
    local area = 0
    print(bounds.low, bounds.up, n)
    local a = bounds.low
    local dx = (bounds.up - a) / n
    for i = 0, n do
        local x0 = a + (i - 1) * dx
        local x1 = a + i * dx
        local state0, y0 = pcall(runner, x0)
        local state1, y1 = pcall(runner, x1)
        if state0 and state1 then
            area = area + (((y0 + y1) / 2) * dx)
            if n <= 1000 then
                table.insert(rects, {x0, 0, x0, -y0, x1, -y1, x1, 0})
            elseif i % math.floor(n/1000) == 0 then
                table.insert(rects, {x0, 0, x0, -y0, x1, -y0, x1, 0})
            end
        end
    end
    guiPrint('AREA: ' .. area)
    return area
end

local d = 1

function love.keypressed(k)
    if not textbox.isActive() then
        if k == 'home' then
            center = {x = window.width / 2, y = window.height / 2}
            scale = {x = 0.25, y = 0.25}
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

        if k == '-' then
            scale.y = clamp(scale.y + d, 0.0001, 1000)
            scale.x = clamp(scale.x + d, 0.0001, 1000)
        elseif k == '=' then
            scale.y = clamp(scale.y - d, 0.0001, 1000)
            scale.x = clamp(scale.x - d, 0.0001, 1000)
        end
    else
        textbox.update(k)
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
    if k == 'c' then
        calcIntegral()
    end
end

local function setUpperBound(up)
    up = loadstring('return ' .. up)

    local state, val = pcall(up)
    if not state or not val or type(val) ~= 'number' then
        bounds.up = 0
        guiPrint('Error Setting Upper Bound!')
    else
        bounds.up = val
        guiPrint('Upper Bound Set!')
    end
end

local function setLowerBound(low)
    low = loadstring('return ' .. low)

    local state, val = pcall(low)
    if not state or not val or type(val) ~= 'number' then
        bounds.low = 0
        guiPrint('Error Setting Lower Bound!')
    else
        bounds.low = val
        guiPrint('Lower Bound Set!')
    end
end

local function setNumber(num)
    num = loadstring('return ' .. num)

    local state, val = pcall(num)
    if not state or not val or type(val) ~= 'number' then
        n = 10000000
        guiPrint('Error Setting Number of Blocks!')
    else
        n = math.min(val, 10000000)
        guiPrint('Numbers of Blocks Set!')
    end
end

function setFunction(func)
    if not func then
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
        local exp = math.exp
        local abs = math.abs
        local floor = math.floor
        local ceil = math.ceil
        local acos = math.acos
        local asin = math.asin
        local atan = math.atan
        local tanh = math.tanh
        local sinh = math.sinh
        local cosh = math.cosh
        local e = 2.718281
        local pi = 3.14159265
        return ]] ..
            func .. ' end'
    )

    local state, error = pcall(runner, 1.5)
    if not state or (state and not error) then
        runner = _NULLFUNC
        print(error)
        guiPrint('Error Setting Function!')
    else
        guiPrint('Function Set!')
        runner = Memoize(runner())
    end
end

function love.mousepressed(x, y, button)
    textbox.activateTextBox()
end

function love.mousereleased(_, _, button)
end

function love.mousemoved(x, y)
end

function love.load()
    love.keyboard.setKeyRepeat(true)
    love.graphics.setPointSize(5)
    love.graphics.getLineStyle('smooth')
    love.graphics.setLineWidth(2)
    love.window.setMode(window.width, window.height)
    love.window.setTitle('Mathinator Thing V0.1')
    textbox.new(8, 20, 300, 25, 'function', setFunction)
    textbox.new(315, 20, 70, 25, 'upper', setUpperBound)
    textbox.new(315, 60, 70, 25, 'lower', setLowerBound)
    textbox.new(392, 20, 80, 25, 'blocks', setNumber)
end

local linePnts

function love.update()
    linePnts = {}
    for x = -1000 * scale.x, 1000 * scale.x, scale.x do
        local state, y = pcall(runner, x)
        if state and type(y) == 'number' then
            linePnts[#linePnts + 1] = center.x + x / scale.x
            linePnts[#linePnts + 1] = center.y - y / scale.y
        end
    end
    local scl = math.sqrt(scale.x^2 + scale.y^2)
    d = shift and scl * 10 or alt and 0.01 * scl or scl

    if love.keyboard.isDown('down') then
        if ctrl then
            scale.y = clamp(scale.y - d, 0.0001, 1000)
        else
            center.y = center.y - d
        end
    end
    if love.keyboard.isDown('up') then
        if ctrl then
            scale.y = clamp(scale.y + d, 0.0001, 1000)
        else
            center.y = center.y + d
        end
    end
    if love.keyboard.isDown('right') then
        if ctrl then
            scale.x = clamp(scale.x - d, 0.0001, 1000)
        else
            center.x = center.x - d
        end
    end
    if love.keyboard.isDown('left') then
        if ctrl then
            scale.x = clamp(scale.x + d, 0.0001, 1000)
        else
            center.x = center.x + d
        end
    end
    textbox.update()
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    if #linePnts > 3 then
        love.graphics.line(linePnts)
    end
    love.graphics.setColor(0, 1, 0, 0.25)
    love.graphics.line(center.x - 1000, center.y, center.x + 1000, center.y)
    love.graphics.setColor(0, 0, 1, 0.25)
    love.graphics.line(center.x, center.y - 1000, center.x, center.y + 1000)

    love.graphics.setColor(0.7, 0.7, 0.7, 0.3)
    love.graphics.translate(center.x, center.y)
    love.graphics.scale(1 / scale.x, 1 / scale.y)
    love.graphics.setLineWidth(0.01)

    for _, rect in pairs(rects) do
        love.graphics.line(rect)
    end

    love.graphics.setLineWidth(2)
    love.graphics.origin()

    love.graphics.setColor(1, 0, 0)
    love.graphics.points(center.x, center.y)
    love.graphics.setColor(0.5, 0.5, 0.5, 0.25)
    love.graphics.points(window.width / 2, window.height / 2)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(screenPrint, 8, window.height - 20)
    textbox.draw()
    love.graphics.print('Function:', 8, 5)
    if textbox.isActive('function') then
        love.graphics.setColor(0.5, 0.5, 0.5, 0.25)
        love.graphics.rectangle('fill', 8, 50, 200, 310)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(
            [[
--Functions--
log(x) = log base 10
ln(x) = log base e
sqrt(x) = square root
exp(x) = e^x
abs(x) = absolute value
floor(x) = round down
ceil(x) = round up
tan(x) = tangent
sin(x) = sine
cos(x) = cosine
acos(x) = arc cosine
asin(x) = arc sine
atan(x) = arc tangent
tanh(x) = hyperbolic tangent
sinh(x) = hyperbolic sine
cosh(x) = hyperbolic cosine

--Constants--
e = 2.718281
pi = 3.14159265]],
            24,
            55
        )
    end
end

function love.run()
    love.load(love.arg.parseGameArguments(arg), arg)
    -- We don't want the first frame's dt to include time taken by love.load.
    love.timer.step()

    local dt = 0

    -- Main loop time.
    return function()
        -- Process events.
        love.event.pump()
        for name, a, b, c, d, e, f in love.event.poll() do
            if name == 'quit' then
                if not love.quit or not love.quit() then
                    return a or 0
                end
            end
            love.handlers[name](a, b, c, d, e, f)
        end

        -- Update dt, as we'll be passing it to update
        dt = love.timer.step()

        -- Call update and draw
        love.update(dt)
         -- will pass 0 if love.timer is disabled

        love.graphics.origin()
        love.graphics.clear(love.graphics.getBackgroundColor())

        love.draw()

        love.graphics.present()

        if love.timer then
            love.timer.sleep(0.001)
        end
    end
end
