-- Pure Lua 5.1 checks for the planner's state, filters, scans and calculations.
local RRP = {}
assert(loadfile("RedridgeRecipePlanner/Catalog.lua"))("RedridgeRecipePlanner",RRP)
local character = "Warrior"
GetRealmName=function() return "TestRealm" end
UnitName=function() return character end
UnitClass=function()
    return character=="Warrior" and "Warrior" or "Mage",
           character=="Warrior" and "WARRIOR" or "MAGE"
end
local bag={ [100]=2, [101]=1 }
GetItemCount=function(id) return bag[id] or 0 end
GetMerchantNumItems=function() return 0 end
GetMerchantItemInfo=function() return nil end
GetMerchantItemLink=function() return nil end
local frame={RegisterEvent=function() end,SetScript=function() end}
CreateFrame=function() return frame end
SlashCmdList={}
RRPDB={characters={},materials={},known={},discovered={},scrollItems={},playerTrainer={}}
assert(loadfile("RedridgeRecipePlanner/Core.lua"))("RedridgeRecipePlanner",RRP)

local p=assert(RRP.GetProfile())
p.expandIntermediate=true
-- Regression for the UI.lua:273 crash reported from an existing install:
-- a saved character profile may predate the per-character known field.
local oldPlan=p.plan
local originalRoles=p.roles
p.known=nil
assert(RRP.GetProfile().known and type(RRP.GetProfile().known)=="table",
    "Missing known table must be migrated before the UI uses it")
assert(p.plan==oldPlan, "Profile migration must preserve planned recipes")
-- Simulate a more incomplete old SavedVariables record.
p.roles=nil
p.page=nil
p.profession=nil
RRP.GetProfile()
assert(type(p.roles)=="table" and p.profession=="All" and p.page==1,
    "Incomplete saved profiles must be restored safely")
p.roles=originalRoles
assert(p.roles.Tank and p.roles.Melee and not p.roles.Paladin)
assert(RRP.IsRelevant(RRP.ByKey["Blacksmithing|Guard's Gloves"]))
assert(not RRP.IsRelevant(RRP.ByKey["Blacksmithing|Protector's Gloves"]),
    "Paladin recipes should be opt-in")
RRP.ToggleRole("Paladin")
assert(RRP.IsRelevant(RRP.ByKey["Blacksmithing|Protector's Gloves"]))
RRP.ToggleRole("Paladin")
assert(not RRP.IsRelevant(RRP.ByKey["Blacksmithing|Protector's Gloves"]))

local key="Alchemy|Elixir of Lesser Intellect"
RRP.Increment(key,3)
RRPDB.materials[key]={materials={{itemID=100,quantity=2}},incomplete=false}
local calc=RRP.Calculate()
assert(calc.selected==1 and calc.favor==45, "Purchase once; craft 3 times")
assert(calc.items[100]==6 and calc.missing==4, "Consolidated reagents / bag difference")
assert(#calc.unknown==0)
RRP.Increment(key,-3)
assert(RRP.Calculate().selected==0)

-- Match recipe names, capture only the observed schematic and learned status.
C_TradeSkillUI={
    GetAllRecipeIDs=function() return {500,501} end,
    GetRecipeInfo=function(id)
        return id==500 and {name="Elixir of Lesser Intellect",learned=true}
                   or {name="Guard\'s Gloves",learned=false}
    end,
    GetRecipeSchematic=function(id)
        return {
            reagentSlotSchematics={
                {isRequired=true,quantityRequired=3,reagents={{itemID=101}}},
                {isRequired=true,quantityRequired=1,reagents={{itemID=100}}},
            },
            outputItemID=102,quantityMin=1,
        }
    end,
}
RRP.ScanProfession()
assert(p.known[key] and RRPDB.materials[key].materials, "Scan did not save learned recipe")
assert(RRPDB.materials["Blacksmithing|Guard's Gloves"] and not p.known["Blacksmithing|Guard's Gloves"],
    "Unlearned recipes should be cached when the client exposes materials")
assert(RRPDB.materials[key].outputItemID==102)

-- Known intermediates are expanded only when requested and proven known.
local other="Cooking|Venomous Smoothie"
p.known[other]=true
RRPDB.materials[other]={
    outputItemID=101, outputCount=1, incomplete=false,
    materials={{itemID=103,quantity=4}},
}
RRP.Increment(key,1)
calc=RRP.Calculate()
assert(calc.items[103]==12 and calc.items[100]==1 and not calc.items[101],
    "Intermediate recipe expansion failed")
p.expandIntermediate=false
calc=RRP.Calculate()
assert(calc.items[101]==3 and not calc.items[103], "Raw materials toggle failed")

-- Trainer matches are explicitly user supplied, not verified by the catalog.
local r=RRP.ByKey[key]
assert(RRP.GetTrainerStatus(r)=="Trainer: not verified")
RRP.CycleTrainer(key)
assert(RRP.GetTrainerStatus(r):find("user marked"))
RRP.CycleTrainer(key)
assert(RRP.GetTrainerStatus(r)=="Trainer: not verified")

-- Character-specific known flags and planning; account-scoped schematics.
character="Mage"
local alt=assert(RRP.GetProfile())
assert(alt ~= p and not alt.known[key] and not alt.plan[key])
character="Warrior"

-- Vendor scan should import new observed scrolls without claiming guessed costs.
RRP.SetProfession("Alchemy")
GetMerchantNumItems=function() return 2 end
GetMerchantItemInfo=function(i)
    return (i==1 and "Recipe: Elixir of Lesser Intellect") or "Recipe: Test Recipe"
end
GetMerchantItemLink=function(i) return "item:"..(i==1 and 8888 or 9999) end
RRP.ScanVendor()
assert(RRPDB.scrollItems[key]==8888)
local discovered=RRPDB.discovered["Alchemy|Test Recipe"]
assert(discovered and discovered.favor==nil and discovered.source=="vendor-scan")

print("Core verified: profiles, class tags, trainer notes, live scans, prices, reagents and intermediate crafting")
