--[[ Simplifier.lua ]]--

local Simplifier = {}

local function rcall(name, ...)
    local fn = getgenv and getgenv()[name] or _G[name]
    if type(fn) == "function" then
        return fn(...)
    end
end

Simplifier.Console = {}

function Simplifier.Console.Print(args)
    local text = (args and args[1]) or ""
    rcall("rconsolprint", text)
    rcall("consolprint", text)
end

function Simplifier.Console.Warn(args)
    local text = (args and args[1]) or ""
    rcall("rconsolwarn", text)
    rcall("consolwarn", text)
end

function Simplifier.Console.Error(args)
    local text = (args and args[1]) or ""
    rcall("rconsolerr", text)
    rcall("consolerr", text)
end

local function setConsoleTitle(args)
    local text = (args and args[1]) or ""
    rcall("rconsolesettitle", text)
    rcall("rconsoletitle", text)
    rcall("consolesettitle", text)
    rcall("consoletitle", text)
end
Simplifier.Console.Title    = setConsoleTitle
Simplifier.Console.Name     = setConsoleTitle
Simplifier.Console.SetTitle = setConsoleTitle

function Simplifier.Console.Create()
    rcall("rconsolecreate")
    rcall("consolecreate")
end

function Simplifier.Console.Destroy()
    rcall("rconsoledestroy")
    rcall("consoledestroy")
end

function Simplifier.Console.Clear()
    rcall("rconsoleclear")
    rcall("consoleclear")
end

-- Info({"text"})
function Simplifier.Console.Info(args)
    local text = (args and args[1]) or ""
    rcall("rconsoleinfo", text)
    rcall("consoleinfo", text)
end

function Simplifier.Console.Input()
    local result = rcall("rconsolinput")
    if result == nil then
        result = rcall("consoleinput")
    end
    return result
end

local function doKick(reason, delay)
    local Players = game:GetService("Players")
    local lp = Players.LocalPlayer
    if not lp then return end

    local function kick()
        if reason and reason ~= "" then
            lp:Kick(reason)
        else
            lp:Kick()
        end
    end

    if delay and delay > 0 then
        task.delay(delay, kick)
    else
        kick()
    end
end

function Simplifier.Kick(args)
    local reason = (args and args[1]) or ""

    local kickObj = {}

    function kickObj.KD(kdArgs)
        local delay = (kdArgs and tonumber(kdArgs[1])) or 0
        doKick(reason, delay)
        return kickObj
    end

    doKick(reason, 0)
    return kickObj
end

return Simplifier
