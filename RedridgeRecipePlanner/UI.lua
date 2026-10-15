local addonName, RRP = ...
local W,H = 920,630
local function text(parent, size, color, x, y, width, height)
    local s = parent:CreateFontString(nil,"OVERLAY",size or "GameFontHighlightSmall")
    s:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    s:SetSize(width,height)
    s:SetJustifyH("LEFT")
    s:SetJustifyV("TOP")
    if color then s:SetTextColor(unpack(color)) end
    return s
end
local function button(parent, label, width, height, x, y, callback)
    local b = CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(width,height)
    b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    b:SetText(label)
    b:SetScript("OnClick",callback)
    return b
end
local function short(s,n)
    s = tostring(s or "")
    if #s > n then return s:sub(1,n-3) .. "..." end
    return s
end
local function itemName(id)
    local name = (GetItemInfo and GetItemInfo(id)) or nil
    if not name and C_Item and C_Item.GetItemNameByID then
        local ok,v = pcall(C_Item.GetItemNameByID,id)
        if ok then name=v end
    end
    return name or ("Item #" .. id)
end
local function bagCount(id)
    if type(GetItemCount) == "function" then
        local ok,c = pcall(GetItemCount,id,false)
        if ok and type(c) == "number" then return c end
    end
    return 0
end

local f = CreateFrame("Frame","RedridgeRecipePlannerFrame",UIParent,"BackdropTemplate")
f:SetSize(W,H)
f:SetPoint("CENTER")
f:SetFrameStrata("DIALOG")
f:EnableMouse(true)
f:SetMovable(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart",function(self) self:StartMoving() end)
f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
if f.SetBackdrop then
    f:SetBackdrop({
        bgFile="Interface/Tooltips/UI-Tooltip-Background",
        edgeFile="Interface/Tooltips/UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,
        insets={left=4,right=4,top=4,bottom=4},
    })
    f:SetBackdropColor(0.055,0.07,0.1,0.98)
end
f:Hide()
if UISpecialFrames then table.insert(UISpecialFrames,f:GetName()) end

local title = text(f,"GameFontNormalLarge",nil,18,-14,740,26)
title:SetText("|cffffd28bRedridge Recipe Planner|r   |cffaaaaaaWoW Forever|r")
local subtitle = text(f,"GameFontHighlightSmall",nil,18,-41,840,25)
subtitle:SetText("Merchant's Favor recipes  |  Build-aware planning  |  Unverified data is marked")
button(f,"X",28,24,874,-14,function() f:Hide() end)

local professionButtons = {}
for i,prof in ipairs(RRP.Professions) do
    professionButtons[i] = button(f,short(prof,14),107,25,18+(i-1)*111,-74,function()
        RRP.SetProfession(prof)
    end)
end
local roleButtons={}
for i,role in ipairs(RRP.Roles) do
    roleButtons[i] = button(f,role,107,24,18+(i-1)*111,-105,function()
        RRP.ToggleRole(role)
    end)
end

local header = text(f,"GameFontNormalSmall",nil,19,-142,525,22)
header:SetText("RECIPES      click to inspect    |    +/- to plan crafts")
local detailsHeader = text(f,"GameFontNormalSmall",nil,564,-142,340,22)
detailsHeader:SetText("SELECTED RECIPE")

local rows={}
for i=1,11 do
    local y=-168-(i-1)*27
    local row={}
    row.select = button(f,"",430,25,18,y,function()
        if row.recipe then
            RRP.selectedKey = row.recipe.key
            RRP.Refresh()
        end
    end)
    row.qty = text(f,"GameFontHighlightSmall",nil,457,y-4,22,24)
    row.qty:SetJustifyH("CENTER")
    row.minus = button(f,"-",23,25,484,y,function()
        if row.recipe then RRP.Increment(row.recipe.key,-1) end
    end)
    row.plus = button(f,"+",23,25,513,y,function()
        if row.recipe then RRP.Increment(row.recipe.key,1) end
    end)
    rows[i]=row
end

local pageLabel=text(f,"GameFontHighlightSmall",nil,154,-473,205,25)
local prev = button(f,"< Previous",125,27,18,-466,function()
    local p=RRP.GetProfile()
    p.page=math.max(1,(p.page or 1)-1)
    RRP.Refresh()
end)
local nextB=button(f,"Next >",125,27,412,-466,function()
    local p=RRP.GetProfile()
    p.page=(p.page or 1)+1
    RRP.Refresh()
end)
local summary=text(f,"GameFontNormal",nil,18,-514,520,24)
local hint=text(f,"GameFontHighlightSmall",nil,18,-540,520,72)
hint:SetText("Open a profession and click Scan Profession to cache known recipes and materials.\nVendor Scan imports recipe scrolls from the currently open camp vendor.\nMaterials remain unknown until the client exposes a recipe schematic.")

local pickedName=text(f,"GameFontNormal",nil,562,-168,335,47)
local pickedInfo=text(f,"GameFontHighlightSmall",nil,562,-219,335,66)
local pickedNote=text(f,"GameFontHighlightSmall",nil,562,-290,340,65)
local selectedQty=text(f,"GameFontNormal",nil,564,-368,80,24)
local decrement=button(f,"-",40,26,650,-364,function()
    if RRP.selectedKey then RRP.Increment(RRP.selectedKey,-1) end
end)
local increment=button(f,"+",40,26,696,-364,function()
    if RRP.selectedKey then RRP.Increment(RRP.selectedKey,1) end
end)
local trainer=button(f,"Mark trainer match",155,26,747,-364,function()
    if RRP.selectedKey then RRP.CycleTrainer(RRP.selectedKey) end
end)
local compare=text(f,"GameFontHighlightSmall",nil,562,-405,330,50)
local materialHeading=text(f,"GameFontNormalSmall",nil,562,-457,330,20)
materialHeading:SetText("COMBINED MATERIALS (across all planned recipes)")
local materialText=text(f,"GameFontHighlightSmall",nil,562,-480,335,120)

local scanProf=button(f,"Scan Profession",142,26,18,-591,function() RRP.ScanProfession() end)
local scanVendor=button(f,"Scan Open Vendor",153,26,165,-591,function() RRP.ScanVendor() end)
local expand=button(f,"Intermediate: ON",145,26,324,-591,function()
    local p=RRP.GetProfile()
    p.expandIntermediate=not p.expandIntermediate
    RRP.Refresh()
end)
local showAll=button(f,"Show All Builds",145,26,473,-591,function()
    RRP.ToggleRole("All")
end)
local shopBtn=button(f,"Full Shopping List",153,26,629,-591,function()
    if RRP.ToggleShopping then RRP.ToggleShopping() end
end)
local footer=text(f,"GameFontHighlightSmall",nil,788,-593,110,24)
footer:SetText("/rrp")

-- A separate, paginated shopping list shows *every* material and missing schematic.
local shop=CreateFrame("Frame","RedridgeShoppingListFrame",UIParent,"BackdropTemplate")
shop:SetSize(610,582)
shop:SetPoint("CENTER")
shop:SetFrameStrata("FULLSCREEN_DIALOG")
shop:EnableMouse(true)
shop:SetMovable(true)
shop:RegisterForDrag("LeftButton")
shop:SetScript("OnDragStart",function(self) self:StartMoving() end)
shop:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
if shop.SetBackdrop then
    shop:SetBackdrop({
        bgFile="Interface/Tooltips/UI-Tooltip-Background",
        edgeFile="Interface/Tooltips/UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,
        insets={left=4,right=4,top=4,bottom=4},
    })
    shop:SetBackdropColor(0.055,0.07,0.1,0.99)
end
shop:Hide()
if UISpecialFrames then table.insert(UISpecialFrames,shop:GetName()) end
local shopTitle=text(shop,"GameFontNormalLarge",nil,18,-16,510,26)
shopTitle:SetText("Shopping & Gathering List")
button(shop,"X",28,24,565,-14,function() shop:Hide() end)
local shopSummary=text(shop,"GameFontHighlightSmall",nil,18,-45,560,43)
local shopRows={}
for i=1,15 do
    shopRows[i]=text(shop,"GameFontHighlightSmall",nil,20,-90-(i-1)*28,568,27)
end
local shopPage=1
local shopPageLabel=text(shop,"GameFontHighlightSmall",nil,175,-521,270,24)
button(shop,"< Previous",135,26,20,-514,function()
    shopPage=math.max(1,shopPage-1)
    RRP.RefreshShopping()
end)
button(shop,"Next >",135,26,456,-514,function()
    shopPage=shopPage+1
    RRP.RefreshShopping()
end)
local shopFoot=text(shop,"GameFontHighlightSmall",nil,20,-554,560,20)
shopFoot:SetText("Owned = bags only. Unknown reagents cannot be included in totals.")
function RRP.RefreshShopping()
    if not shop:IsShown() then return end
    local calc=RRP.Calculate()
    local entries={}
    for id,amount in pairs(calc.items) do
        entries[#entries+1]={id=id,amount=amount,missing=math.max(0,amount-bagCount(id))}
    end
    table.sort(entries,function(a,b)
        if a.missing ~= b.missing then return a.missing>b.missing end
        return itemName(a.id)<itemName(b.id)
    end)
    local full={}
    for _,entry in ipairs(entries) do
        full[#full+1]=short(itemName(entry.id),37)..
            "     "..bagCount(entry.id).."/"..entry.amount..
            (entry.missing>0 and "    NEED "..entry.missing or "    READY")
    end
    for _,name in ipairs(calc.unknown) do
        full[#full+1]="|cffffaa55? "..short(name,68).." - ingredients unknown|r"
    end
    if #full==0 then full[1]="No recipes selected. Use + in the planner." end
    local pages=math.max(1,math.ceil(#full/#shopRows))
    shopPage=math.max(1,math.min(shopPage,pages))
    local start=(shopPage-1)*#shopRows+1
    for i,row in ipairs(shopRows) do row:SetText(full[start+i-1] or "") end
    shopPageLabel:SetText("Page "..shopPage.."/"..pages.."    |    "..#entries.." materials, "..#calc.unknown.." unknown recipes")
    shopSummary:SetText(calc.selected.." recipes selected. Purchase cost: "..calc.favor..
        (calc.unknownFavor and "+ (some unknown)" or "").." Merchant's Favor.\n"..
        "Missing known reagents: "..calc.missing.." items.")
end
function RRP.ToggleShopping()
    if shop:IsShown() then shop:Hide() else shop:Show(); shopPage=1; RRP.RefreshShopping() end
end

function RRP.Refresh()
    if not f:IsShown() then return end
    local p=RRP.GetProfile()
    if not p then return end
    -- Defensive against old/mixed addon versions and legacy character data.
    local knownRecipes = type(p.known) == "table" and p.known or {}
    local plan = type(p.plan) == "table" and p.plan or {}
    local roles = type(p.roles) == "table" and p.roles or {}
    local list=RRP.VisibleRecipes()
    local pages=math.max(1,math.ceil(#list / #rows))
    p.page=math.max(1,math.min(p.page or 1,pages))
    local start=(p.page-1)*#rows+1
    for i,b in ipairs(professionButtons) do
        local name=RRP.Professions[i]
        local active=(name==p.profession)
        b:SetText((active and "> " or "")..short(name,13))
    end
    for i,b in ipairs(roleButtons) do
        local name=RRP.Roles[i]
        local active = name=="All" and p.showAll or roles[name]
        b:SetText((active and "[x] " or "[ ] ")..name)
    end
    for i,row in ipairs(rows) do
        local r=list[start+i-1]
        row.recipe=r
        if r then
            local qty=plan[r.key] or 0
            local marker=qty>0 and "|cff66ee99*|r " or ""
            local known=knownRecipes[r.key] and "|cff66ccff (Known)|r" or ""
            local selected=RRP.selectedKey == r.key and "|cffffff88>|r " or ""
            row.select:SetText(selected..marker..short(r.name,37)..known)
            row.qty:SetText(qty>0 and tostring(qty) or "-")
            row.select:Show(); row.qty:Show(); row.minus:Show(); row.plus:Show()
        else
            row.select:Hide(); row.qty:Hide(); row.minus:Hide(); row.plus:Hide()
        end
    end
    pageLabel:SetText(string.format("%d recipes | Page %d/%d",#list,p.page,pages))
    prev:SetEnabled(p.page>1)
    nextB:SetEnabled(p.page<pages)
    expand:SetText(p.expandIntermediate and "Intermediate: ON" or "Intermediate: OFF")
    showAll:SetText(p.showAll and "Showing All Builds" or "Show All Builds")

    local r=RRP.selectedKey and RRP.GetByKey(RRP.selectedKey)
    if not r then r=list[1] end
    if r then
        RRP.selectedKey=r.key
        pickedName:SetText(r.name)
        local known=knownRecipes[r.key] and "Learned (observed)" or "Not confirmed learned"
        pickedInfo:SetText(
            r.profession .. "  |  " .. known ..
            "\nRequired level: " .. (r.level or "?") ..
            "  |  Skill: " .. (r.skill or "?") ..
            "\nFavor: " .. (r.favor or "?") .. "  |  Rep: " .. (r.reputation or "?") ..
            "\nBuild tags: " .. (r.roles or "Unsorted"))
        local schem=RRPDB.materials[r.key]
        pickedNote:SetText(
            (r.alternative or "Trainer comparison: no independently verified duplicate.") ..
            "\nCraft reagents: " .. (schem and (schem.incomplete and "partial scan" or "scanned") or "not yet scanned"))
        selectedQty:SetText("Craft: "..(plan[r.key] or 0))
        compare:SetText(RRP.GetTrainerStatus(r) ..
            "\nMarks are personal observations, not verified trainer data.")
        decrement:Enable(); increment:Enable(); trainer:Enable()
    else
        pickedName:SetText("No recipes match these filters")
        pickedInfo:SetText("Enable more build categories, or choose All.")
        pickedNote:SetText("")
        selectedQty:SetText("")
        compare:SetText("")
        decrement:Disable(); increment:Disable(); trainer:Disable()
    end

    local calc=RRP.Calculate()
    local cost=tostring(calc.favor)..(calc.unknownFavor and "+ (some costs unknown)" or "")
    summary:SetText(calc.selected.." wanted recipes    |    "..cost.." Merchant's Favor")
    local sorted={}
    for id,amount in pairs(calc.items) do sorted[#sorted+1]={id=id,amount=amount} end
    table.sort(sorted,function(a,b) return a.amount > b.amount end)
    local lines={}
    for i=1,math.min(5,#sorted) do
        local ent=sorted[i]
        local owned=bagCount(ent.id)
        lines[#lines+1]=short(itemName(ent.id),21).." "..owned.."/"..ent.amount..
            (owned<ent.amount and " (need "..(ent.amount-owned)..")" or " (ready)")
    end
    if #sorted>5 then lines[#lines+1]="... and "..(#sorted-5).." more materials" end
    if #calc.unknown>0 then
        lines[#lines+1]="|cffffaa55Unscanned recipes: "..#calc.unknown.."|r"
    end
    if #lines==0 then
        lines[1]="Choose recipes with +, then scan your profession."
        lines[2]="Unknown materials are NOT counted as zero."
    end
    materialText:SetText(table.concat(lines,"\n"))
    RRP.RefreshShopping()
end

function RRP.Toggle()
    if f:IsShown() then f:Hide() else f:Show(); RRP.Refresh() end
end
RRP.Window=f
