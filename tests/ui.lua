-- Minimal mocked WoW UI smoke test.
-- Run from repository root: lua5.1 tests/ui.lua
-- This does NOT replace a test in WoW; it guards opening and refreshing the
-- complete planner without referencing deleted account-wide SavedVariables.
local RRP = {}
local function widget(name)
    local w={_name=name, _shown=false}
    return setmetatable(w,{__index=function(self,k)
        if k=="GetName" then return function(t) return t._name end end
        if k=="IsShown" then return function(t) return t._shown end end
        if k=="Show" then return function(t) t._shown=true end end
        if k=="Hide" then return function(t) t._shown=false end end
        if k=="CreateFontString" then return function() return widget() end end
        if k=="SetText" then return function(t,v) t._text=v end end
        if k=="SetScript" then return function(t,event,fn) t[event]=fn end end
        return function() end
    end})
end
UIParent=widget("UIParent")
UISpecialFrames={}
CreateFrame=function(_,name) return widget(name) end
GetRealmName=function() return "TestRealm" end
UnitName=function() return "TestWarrior" end
UnitClass=function() return "Warrior","WARRIOR" end
GetItemCount=function() return 0 end
GetItemInfo=function() return nil end
SlashCmdList={}
RRPDB={characters={},materials={},discovered={},scrollItems={},playerTrainer={}}
assert(loadfile("RedridgeRecipePlanner/Catalog.lua"))("RedridgeRecipePlanner",RRP)
assert(loadfile("RedridgeRecipePlanner/Core.lua"))("RedridgeRecipePlanner",RRP)
assert(loadfile("RedridgeRecipePlanner/UI.lua"))("RedridgeRecipePlanner",RRP)
-- Simulates the failing /rrp opening path from the bug report.
RRP.Toggle()
assert(RRP.Window:IsShown(),"Planner did not open")
-- Reproduce a mixed old-Core/new-UI install where the character's
-- learned-recipe table is missing despite the window being displayed.
local originalGetProfile=RRP.GetProfile
local legacy={plan={},roles={Tank=true,Utility=true},profession="All",page=1,showAll=true}
RRP.GetProfile=function() return legacy end
RRP.Refresh()
assert(RRP.Window:IsShown(),"UI crashed when p.known was nil")
RRP.GetProfile=originalGetProfile
local profile=assert(RRP.GetProfile())
assert(type(profile.known)=="table" and RRPDB.known==nil,
    "Test must use only character-specific known recipes")
-- Exercise selected details, known-flag view, quantity, role and shop pane.
local key="Alchemy|Elixir of Lesser Intellect"
RRP.selectedKey=key
profile.known[key]=true
RRP.SetProfession("Alchemy")
RRP.Increment(key,2)
RRP.ToggleRole("Caster")
RRP.Refresh()
RRP.ToggleShopping()
RRP.Increment(key,-1)
RRP.RefreshShopping()
RRP.Toggle()
assert(not RRP.Window:IsShown(),"Planner did not close")
print("UI smoke verified: opening, recipe details, class profile, shopping list and refresh")
