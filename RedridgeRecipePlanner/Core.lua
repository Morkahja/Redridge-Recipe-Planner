local addonName, RRP = ...
local function say(message)
    print("|cffdca75fRedridge Planner|r: " .. tostring(message))
end
RRP.Say = say

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c = pcall(fn, ...)
    if ok then return a, b, c end
    return nil
end

local function trim(s)
    return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end
local function normalize(s)
    s = trim(s):lower()
    s = s:gsub("^[^:]+:%s+", "") -- Recipe:, Plans:, Formula:, Pattern:, etc.
    s = s:gsub("[^%w]+", " ")
    return trim(s)
end
RRP.Normalize = normalize

local function keyFor(name, profession)
    return (profession or "") .. "|" .. (name or "")
end

function RRP.GetProfile()
    if not RRPDB then return nil end
    local realm = (GetRealmName and GetRealmName()) or "Realm"
    local name = (UnitName and UnitName("player")) or "Player"
    local charKey = realm .. "-" .. name
    RRPDB.characters = RRPDB.characters or {}
    if not RRPDB.characters[charKey] then
        local _, class = UnitClass("player")
        local defaults = {All = false}
        if class == "WARRIOR" or class == "ROGUE" then
            defaults.Tank = class == "WARRIOR"
            defaults.Melee = true
        elseif class == "PALADIN" then
            defaults.Tank, defaults.Melee, defaults.Healer, defaults.Paladin = true,true,true,true
        elseif class == "HUNTER" then
            defaults.Hunter, defaults.Melee = true,true
        elseif class == "DRUID" or class == "SHAMAN" then
            defaults.Tank, defaults.Melee, defaults.Healer, defaults.Caster = true,true,true,true
        elseif class == "PRIEST" then
            defaults.Healer, defaults.Caster = true,true
        else
            defaults.Caster = true
        end
        defaults.Utility = true
        RRPDB.characters[charKey] = {plan = {}, known = {}, roles = defaults, profession = "All", showAll = false, page = 1}
    end
    local p = RRPDB.characters[charKey]
    p.known = p.known or {}
    return p
end

function RRP.GetRecipes()
    local result = {}
    for _, r in ipairs(RRP.Catalog) do result[#result + 1] = r end
    if RRPDB and RRPDB.discovered then
        for key, d in pairs(RRPDB.discovered) do
            if not RRP.ByKey[key] then result[#result + 1] = d end
        end
    end
    table.sort(result, function(a,b)
        if a.profession ~= b.profession then return a.profession < b.profession end
        if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) < (b.level or 0) end
        return a.name < b.name
    end)
    return result
end

function RRP.GetByKey(key)
    return RRP.ByKey[key] or (RRPDB and RRPDB.discovered and RRPDB.discovered[key])
end

function RRP.IsRelevant(r)
    local p = RRP.GetProfile()
    if not p then return true end
    if p.showAll then return true end
    -- Paladin-tagged designs should not appear on a Warrior just because
    -- they also match Tank or Melee. Players may opt in to Paladin gear.
    if r.roles and r.roles:find("Paladin", 1, true) and not p.roles.Paladin then
        return false
    end
    if p.roles.All or not r.roles then return true end
    for part in r.roles:gmatch("[^,]+") do
        if p.roles[trim(part)] then return true end
    end
    return false
end

function RRP.VisibleRecipes()
    local p = RRP.GetProfile()
    local t = {}
    for _, r in ipairs(RRP.GetRecipes()) do
        if (p.profession == "All" or p.profession == r.profession) and RRP.IsRelevant(r) then
            t[#t + 1] = r
        end
    end
    return t
end

function RRP.Increment(key, delta)
    local p = RRP.GetProfile()
    if not p then return end
    local n = math.max(0, math.min(999, (p.plan[key] or 0) + delta))
    p.plan[key] = n > 0 and n or nil
    if RRP.Refresh then RRP.Refresh() end
end
function RRP.SetProfession(prof)
    local p = RRP.GetProfile()
    p.profession, p.page = prof, 1
    if RRP.Refresh then RRP.Refresh() end
end
function RRP.ToggleRole(role)
    local p = RRP.GetProfile()
    if role == "All" then
        p.showAll = not p.showAll
    else
        p.showAll = false
        p.roles[role] = not p.roles[role]
    end
    p.page = 1
    if RRP.Refresh then RRP.Refresh() end
end
function RRP.CycleTrainer(key)
    if not RRPDB then return end
    -- This is a personal observation, never represented as database verification.
    RRPDB.playerTrainer = RRPDB.playerTrainer or {}
    RRPDB.playerTrainer[key] = not RRPDB.playerTrainer[key] and true or nil
    if RRP.Refresh then RRP.Refresh() end
end
function RRP.GetTrainerStatus(r)
    if RRPDB and RRPDB.playerTrainer and RRPDB.playerTrainer[r.key] then
        return "Trainer: user marked (unverified)"
    end
    return "Trainer: not verified"
end

local function inspectSchematic(recipeID)
    local api = C_TradeSkillUI
    if not api or type(api.GetRecipeSchematic) ~= "function" then return nil end
    local sch = safeCall(api.GetRecipeSchematic, recipeID, false)
    if type(sch) ~= "table" or type(sch.reagentSlotSchematics) ~= "table" then return nil end
    local materials, incomplete = {}, false
    for _, slot in ipairs(sch.reagentSlotSchematics) do
        if slot.isRequired ~= false then
            local reagents = slot.reagents
            if type(reagents) == "table" and #reagents == 1 then
                local reagent = reagents[1]
                local id = tonumber(reagent.itemID or reagent.itemId)
                local amount = tonumber(slot.quantityRequired or reagent.quantityRequired)
                if id and amount and amount > 0 then
                    materials[id] = (materials[id] or 0) + amount
                else
                    incomplete = true
                end
            else
                -- Optional choices cannot be evaluated without user selection.
                incomplete = true
            end
        end
    end
    local result = {}
    for id, qty in pairs(materials) do result[#result+1] = {itemID=id, quantity=qty} end
    table.sort(result, function(a,b) return a.itemID < b.itemID end)
    if #result == 0 then return nil end
    return {
        materials = result,
        incomplete = incomplete,
        outputItemID = tonumber(sch.outputItemID),
        outputCount = tonumber(sch.quantityMin) or 1,
    }
end

function RRP.ScanProfession()
    if not RRPDB or not C_TradeSkillUI then
        say("Open a profession window to scan recipes.")
        return
    end
    local api = C_TradeSkillUI
    local ids = safeCall(api.GetAllRecipeIDs)
    if type(ids) ~= "table" then
        say("No profession recipes available. Open your profession window and try again.")
        return
    end
    local catalog = {}
    for _,r in ipairs(RRP.GetRecipes()) do
        local n = normalize(r.name)
        catalog[n] = catalog[n] or {}
        catalog[n][#catalog[n]+1] = r
    end
    local checked, cached = 0, 0
    for _, id in ipairs(ids) do
        local info = safeCall(api.GetRecipeInfo, id)
        if type(info) == "table" and type(info.name) == "string" then
            local matches = catalog[normalize(info.name)]
            if matches then
                for _,r in ipairs(matches) do
                    if info.learned then
                        RRP.GetProfile().known[r.key] = true
                        local sch = inspectSchematic(id)
                        if sch then
                            RRPDB.materials[r.key] = sch
                            cached = cached + 1
                        end
                    end
                    checked = checked + 1
                end
            end
        end
    end
    say("Profession scanned: " .. checked .. " catalog matches; " .. cached .. " material schematics captured.")
    if RRP.Refresh then RRP.Refresh() end
end

function RRP.ScanVendor()
    local p = RRP.GetProfile()
    if not p or p.profession == "All" then
        say("Choose the vendor's profession first, then open the camp merchant.")
        return
    end
    if type(GetMerchantNumItems) ~= "function" or type(GetMerchantItemInfo) ~= "function" then
        say("Merchant API is unavailable.")
        return
    end
    local n = safeCall(GetMerchantNumItems)
    if not n or n == 0 then say("Open the merchant window before scanning."); return end
    local added, linked = 0, 0
    for i=1,n do
        local name = safeCall(GetMerchantItemInfo, i)
        if type(name) == "string" then
            local base = name:match("^[^:]+:%s*(.+)$")
            if base then
                local matches = {}
                for _,r in ipairs(RRP.GetRecipes()) do
                    if r.profession == p.profession and normalize(r.name) == normalize(base) then
                        matches[#matches+1] = r
                    end
                end
                local link = safeCall(GetMerchantItemLink, i)
                local id = type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil
                if #matches == 0 then
                    -- Import only plausible recipe scrolls, never arbitrary merchandise.
                    local prefix = name:match("^([^:]+):")
                    if prefix == "Recipe" or prefix == "Plans" or prefix == "Pattern"
                        or prefix == "Schematic" or prefix == "Formula" or prefix == "Design" then
                        local key = keyFor(base, p.profession)
                        if not RRP.ByKey[key] and not RRPDB.discovered[key] then
                            RRPDB.discovered[key] = {
                                key=key, name=base, profession=p.profession,
                                roles="Utility", source="vendor-scan", scrollItemID=id,
                                reputation="Unknown",
                            }
                            added = added + 1
                        end
                    end
                else
                    for _,r in ipairs(matches) do
                        if id then RRPDB.scrollItems[r.key] = id end
                        linked = linked + 1
                    end
                end
            end
        end
    end
    say("Vendor scan: " .. linked .. " existing matches; " .. added .. " newly discovered recipe scrolls.")
    if RRP.Refresh then RRP.Refresh() end
end

function RRP.Calculate()
    local p = RRP.GetProfile()
    local result = {favor=0, unknownFavor=false, items={}, unknown={}, selected=0, missing=0}
    if not p then return result end
    local craftsByOutput = {}
    for key,d in pairs(RRPDB.materials) do
        if d.outputItemID and not d.incomplete and #d.materials > 0 and p.known[key] then
            craftsByOutput[d.outputItemID] = d
        end
    end
    local function addReagent(id, amount, visited)
        if p.expandIntermediate and craftsByOutput[id] and not visited[id] then
            local sch = craftsByOutput[id]
            visited[id] = true
            local crafts = math.ceil(amount / math.max(1,sch.outputCount))
            for _,m in ipairs(sch.materials) do addReagent(m.itemID,m.quantity*crafts,visited) end
            visited[id] = nil
        else
            result.items[id] = (result.items[id] or 0) + amount
        end
    end
    for key, qty in pairs(p.plan) do
        local r = RRP.GetByKey(key)
        if r and qty > 0 then
            result.selected = result.selected + 1
            if r.favor then result.favor = result.favor + r.favor
            else result.unknownFavor = true end
            local sch = RRPDB.materials[key]
            if sch and #sch.materials > 0 then
                for _,m in ipairs(sch.materials) do addReagent(m.itemID,m.quantity*qty,{}) end
                if sch.incomplete then result.unknown[#result.unknown+1] = r.name .. " (partial)" end
            else
                result.unknown[#result.unknown+1] = r.name
            end
        end
    end
    for id,amount in pairs(result.items) do
        local owned = (type(GetItemCount) == "function" and safeCall(GetItemCount,id,false)) or 0
        if type(owned) ~= "number" then owned = 0 end
        result.missing = result.missing + math.max(0,amount-owned)
    end
    table.sort(result.unknown)
    return result
end

SLASH_REDRIDGERECIPEPLANNER1 = "/rrp"
SLASH_REDRIDGERECIPEPLANNER2 = "/redridge"
SlashCmdList["REDRIDGERECIPEPLANNER"] = function(msg)
    local cmd = trim(msg):lower()
    if cmd == "scan" then RRP.ScanProfession()
    elseif cmd == "vendor" then RRP.ScanVendor()
    elseif cmd == "list" then
        if RRP.ToggleShopping then RRP.ToggleShopping() end
    elseif cmd == "resetview" then
        local p = RRP.GetProfile()
        p.profession, p.page, p.showAll = "All", 1, false
        if RRP.Refresh then RRP.Refresh() end
    else
        if RRP.Toggle then RRP.Toggle() end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent",function(_,event,arg)
    if event == "ADDON_LOADED" and arg == addonName then
        RRPDB = RRPDB or {}
        RRPDB.characters = RRPDB.characters or {}
        RRPDB.materials = RRPDB.materials or {}
        RRPDB.discovered = RRPDB.discovered or {}
        RRPDB.scrollItems = RRPDB.scrollItems or {}
        RRPDB.playerTrainer = RRPDB.playerTrainer or {}
    elseif event == "PLAYER_LOGIN" then
        local p = RRP.GetProfile()
        if p.expandIntermediate == nil then p.expandIntermediate = true end
        say("Ready. Type /rrp to open, /rrp scan with professions open.")
    end
end)
