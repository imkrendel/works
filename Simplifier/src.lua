local Simplifier = {}

local genv = getgenv and getgenv() or _G

local function resolve(name)
    return genv["r" .. name] or genv[name] or nil
end

local function rcall(name, ...)
    local fn = resolve(name)
    if fn then
        return fn(...)
    else
        error("Simplifier | " .. name .. " not working (r" .. name .. " & " .. name .. " not found)")
    end
end

local function processArgs(args)
    if not args then return "" end
    local parts = {}
    for _, v in ipairs(args) do
        if v == "NL" then
            table.insert(parts, "\n")
        else
            table.insert(parts, tostring(v))
        end
    end
    return table.concat(parts)
end

Simplifier.Console = {}

function Simplifier.Console.Print(args)   rcall("consoleprint",    processArgs(args)) end
function Simplifier.Console.Warn(args)    rcall("consolewarn",     processArgs(args)) end
function Simplifier.Console.Error(args)   rcall("consoleerr",      processArgs(args)) end
function Simplifier.Console.Info(args)    rcall("consoleinfo",     processArgs(args)) end
function Simplifier.Console.Clear()       rcall("consoleclear")                       end
function Simplifier.Console.Create()      rcall("consolecreate")                      end
function Simplifier.Console.Destroy()     rcall("consoledestroy")                     end
function Simplifier.Console.Input()       return rcall("consoleinput")                end

local function setTitle(args)             rcall("consolesettitle", processArgs(args)) end
Simplifier.Console.Title    = setTitle
Simplifier.Console.Name     = setTitle
Simplifier.Console.SetTitle = setTitle

local function doKick(reason, delay)
    local lp = game:GetService("Players").LocalPlayer
    if not lp then return end
    local function kick()
        if reason ~= "" then lp:Kick(reason) else lp:Kick() end
    end
    if delay and delay > 0 then task.delay(delay, kick) else kick() end
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
