local Simplifier = {}
-- 
Simplifier.NL = "\n"

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

local function resolveAsset(input)
    if not input or input == "" then return "" end
    local str = tostring(input)
    
    if tonumber(str) then
        -- Авто-конвертация ID каталога в Asset ID
        local success, assetId = pcall(function()
            local model = game:GetService("InsertService"):LoadAsset(tonumber(str))
            local item = model:FindFirstChildOfClass("Shirt") or model:FindFirstChildOfClass("Pants") or model:FindFirstChildOfClass("ShirtGraphic")
            local template = item and (item:IsA("Shirt") and item.ShirtTemplate or item.PantsTemplate) or ""
            model:Destroy()
            return template
        end)
        
        if success and assetId ~= "" then
            return assetId
        else
            return "rbxassetid://" .. str -- Если InsertService не сработал
        end
    elseif str:match("^rbxassetid://") or str:match("^http") then
        return str
    else
        local customAssetFn = resolve("getcustomasset")
        return customAssetFn and customAssetFn(str) or str
    end
end

local function getOrCreateClothing(className)
    local lp = game:GetService("Players").LocalPlayer
    if not lp or not lp.Character then return nil end
    return lp.Character:FindFirstChildOfClass(className) or Instance.new(className, lp.Character)
end

Simplifier.Console = {}

function Simplifier.Console.Print(args)   rcall("consoleprint",    processArgs(args)) end
function Simplifier.Console.Warn(args)    rcall("consolewarn",     processArgs(args)) end
function Simplifier.Console.Error(args)   rcall("consoleerr",      processArgs(args)) end
function Simplifier.Console.Info(args)    rcall("consoleinfo",     processArgs(args)) end
function Simplifier.Console.Clear()       rcall("consoleclear")                        end
function Simplifier.Console.Create()      rcall("consolecreate")                       end
function Simplifier.Console.Destroy()     rcall("consoledestroy")                      end
function Simplifier.Console.Input()       return rcall("consoleinput")                 end

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

Simplifier.Change = {}

local currentShirt = nil
local currentPants = nil

local function applyCurrentOutfit(char)
    if currentShirt then
        local shirt = char:FindFirstChildOfClass("Shirt") or Instance.new("Shirt", char)
        shirt.ShirtTemplate = resolveAsset(currentShirt)
    end
    if currentPants then
        local pants = char:FindFirstChildOfClass("Pants") or Instance.new("Pants", char)
        pants.PantsTemplate = resolveAsset(currentPants)
    end
end

local lp = game:GetService("Players").LocalPlayer
if lp then
    lp.CharacterAdded:Connect(applyCurrentOutfit)
    if lp.Character then applyCurrentOutfit(lp.Character) end
end

function Simplifier.Change.Shirt(args)
    local asset = args and args[1]
    if not asset then return end
    currentShirt = asset
    
    local shirt = getOrCreateClothing("Shirt")
    if shirt then
        shirt.ShirtTemplate = resolveAsset(asset)
    end
end

function Simplifier.Change.Pants(args)
    local asset = args and args[1]
    if not asset then return end
    currentPants = asset
    
    local pants = getOrCreateClothing("Pants")
    if pants then
        pants.PantsTemplate = resolveAsset(asset)
    end
end

return Simplifier
