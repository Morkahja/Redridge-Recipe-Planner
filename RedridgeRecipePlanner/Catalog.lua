-- Factual vendor catalog based on WoW Forever beta listings (October 2026).
-- This catalog contains names, skill requirements, level, favor and reputation.
-- It does NOT pretend to know item IDs, reagents, or trainer availability.
local addonName, RRP = ...
RRP.Catalog = {}
RRP.ByKey = {}
RRP.Professions = {"All", "Alchemy", "Blacksmithing", "Cooking", "Enchanting", "Engineering", "Leatherworking", "Tailoring"}
RRP.Roles = {"All", "Tank", "Melee", "Healer", "Caster", "Hunter", "Paladin", "Utility"}

local function add(prof, name, level, skill, favor, rep, roles)
    assert(not RRP.ByKey[prof .. "|" .. name], "Duplicate catalog entry: " .. prof .. "|" .. name)
    local entry = {
        profession = prof, name = name, level = level, skill = skill,
        favor = favor, reputation = rep or "None", roles = roles or "Utility",
        key = prof .. "|" .. name, source = "vendor-list",
    }
    RRP.Catalog[#RRP.Catalog + 1] = entry
    RRP.ByKey[entry.key] = entry
end

-- name|level|skill|favor|reputation|roles
local function rows(prof, input)
    for line in input:gmatch("[^\r\n]+") do
        if line:match("%S") then
            local col = {}
            for part in (line .. "|"):gmatch("(.-)|") do col[#col + 1] = part end
            add(prof, col[1], tonumber(col[2]), tonumber(col[3]), tonumber(col[4]),
                col[5] ~= "-" and col[5] or "None", col[6])
        end
    end
end

rows("Alchemy", [[
Mender's Potion|25|130|45|-|Healer
Spellblasting Potion|25|135|45|-|Caster
Frenzy Potion|25|140|45|-|Melee,Hunter
Disorienting Smog Potion|45|180|120|Friendly|Utility
Dragonfire Potion|35|245|120|Friendly|Utility
Caustic Smog Potion|45|265|180|Honored|Utility
Potion of Venomous Blood|30|275|180|Honored|Tank
Major Mender's Potion|55|280|180|Honored|Healer
Potion of Elemental Purging|40|280|180|Honored|Caster
Major Spellblasting Potion|55|285|180|Honored|Caster
Major Frenzy Potion|55|290|240|Honored|Melee,Hunter
Elixir of Lesser Spirit|25|65|45|-|Healer,Caster
Lesser Mageblood Elixir|25|75|45|-|Healer,Caster
Elixir of Lesser Intellect|25|95|45|-|Healer,Caster
Lesser Cleric's Elixir|25|95|45|-|Healer
Lesser Arcane Elixir|25|120|45|-|Caster
Elixir of Greater Spirit|55|165|120|Friendly|Healer,Caster
Greater Mageblood Elixir|55|175|120|Friendly|Healer,Caster
Greater Cleric's Elixir|55|195|120|Friendly|Healer
Elixir of Greater Fortitude|55|200|120|Friendly|Tank
Elixir of the Phalanx|55|250|180|Honored|Tank
Elixir of Cunning|55|275|180|Honored|Caster,Hunter
Elixir of Ferocity|55|275|180|Honored|Melee,Hunter
Elixir of Sages|55|275|180|Honored|Caster,Healer
Elixir of the Whale|55|275|180|Honored|Caster,Healer
Elixir of the Owl|55|280|180|Honored|Caster
Elixir of Nature Power|55|285|180|Honored|Caster
Elixir of Wicked Regeneration|55|285|180|Honored|Healer,Caster
Elixir of the Grizzly|55|300|240|Honored|Melee
]])

-- All five Blacksmithing equipment lines.
local function smithLine(low, high, role)
    local names = {
        {low .. " Chain Belt",12,45,30}, {low .. " Gloves",15,80,30},
        {low .. " Boots",17,85,30}, {low .. " Silvered Chain Helm",20,95,30},
        {low .. " Silvered Chain Shirt",22,110,30},
        {low .. " Silvered Chain Leggings",25,125,30},
        {high .. " Gauntlet",35,175,60,"Friendly"},
        {high .. " Pauldrons",42,210,60,"Friendly"},
        {high .. " Wristguards",45,225,90,"Honored"},
        {high .. " Sabatons",47,240,90,"Honored"},
        {high .. " Waistguard",50,250,90,"Honored"},
    }
    for _,r in ipairs(names) do add("Blacksmithing",r[1],r[2],r[3],r[4],r[5],role) end
end
smithLine("Guard's","Sentinel's","Tank")
smithLine("Veteran's","Officer's","Melee")
smithLine("Acolyte's","Prefect's","Healer,Paladin")
smithLine("Protector's","Warder's","Tank,Paladin")
smithLine("Crusader's","Justicar's","Melee,Paladin")
rows("Blacksmithing", [[
Thorium Cestus|50|250|90|Honored|Melee
Legionite Glaive|58|300|120|Honored|Melee,Hunter
Enriched Thorium Breastplate|57|300|120|Honored|Tank,Paladin
Enriched Thorium Helm|58|300|120|Honored|Tank,Paladin
Enriched Thorium Leggings|58|300|120|Honored|Tank,Paladin
Thorium Greatmace|50|250|90|Honored|Melee,Paladin
]])

rows("Cooking", [[
Venomous Smoothie|1|25|30|-|Healer,Caster
Slimy Smoothie|5|100|30|-|Healer,Caster
Mrrggl Smrrthle|15|125|30|-|Healer,Caster
Calcified Smoothie|25|180|60|Friendly|Healer,Caster
Spicy Smoothie|35|200|60|Friendly|Healer,Caster
Wicked Smoothie|45|250|90|Honored|Healer,Caster
]])

rows("Enchanting", [[
Enchant Necklace - Agility|-|210|120|Friendly|Melee,Hunter
Enchant Necklace - Deflection|-|210|120|Friendly|Tank
Enchant Necklace - Healing Power|-|210|120|Friendly|Healer
Enchant Necklace - Spell Power|-|210|120|Friendly|Caster
Enchant Necklace - Strength|-|210|120|Friendly|Melee
Enchant Weapon - Insight|-|140|45|-|Healer,Caster
Enchant Weapon - Recovery|-|140|45|-|Tank,Melee
Enchant Weapon - Revelation|-|140|45|-|Caster
Enchant 2H Weapon - Mighty Healing Power|-|300|240|Honored|Healer
Enchant 2H Weapon - Mighty Spell Power|-|300|240|Honored|Caster
Enchant 2H Weapon - Spellblasting|-|300|240|Honored|Caster
Enchant Chest - Absorption|-|220|120|Friendly|Tank
Enchant Bracer - Greater Spellpower|-|300|240|Honored|Caster
Enchant Bracer - Superior Deflection|-|300|240|Honored|Tank
Enchant Bracer - Superior Intellect|-|300|240|Honored|Healer,Caster
Enchant Cloak - Agility|-|300|240|Honored|Melee,Hunter
Enchant Gloves - Arcane Power|-|300|240|Honored|Caster
Enchant Gloves - Holy Power|-|300|240|Honored|Caster,Paladin
Enchant Gloves - Natural Power|-|300|240|Honored|Caster
Enchant Gloves - Superior Strength|-|300|240|Honored|Melee
Enchant Off-Hand - Wisdom|-|300|240|Honored|Healer,Caster
Mystic Mushroom|20|130|45|-|Caster
Polished Driftwood Icon|20|130|45|-|Healer,Caster
Tenets of the Silver Hand|20|130|45|-|Paladin
Libram of Invocation|40|210|120|Friendly|Paladin
Talons of Wrath|40|210|120|Friendly|Caster
Totem of Ancestral Protection|40|210|120|Friendly|Healer
Idol of the Dream|55|300|240|Honored|Caster,Healer
Libram of Holy Alacrity|55|300|240|Honored|Paladin
Totem of Thunder|60|300|240|Honored|Caster
Glimmering Staff|25|140|45|-|Caster
Orb of Mystic Insight|25|140|45|-|Caster
Orb of Souls|25|140|45|-|Caster
Soulstaff|25|140|45|-|Caster
Dreamstaff|45|220|120|Friendly|Healer
Radiant Staff|45|220|120|Friendly|Caster
Truesilver Conduit|45|220|120|Friendly|Caster
Twisting Essence Jar|45|220|120|Friendly|Caster
Brilliant Wand|55|275|180|Honored|Caster
]])

rows("Engineering", [[
SAF-T Dynamite|1|25|45|-|Utility
SAF-T Copper Bomb|1|55|45|-|Utility
EZ-Thro Copper Bomb XL|1|130|45|-|Utility
Satchel of Copper Bombs|13|85|45|-|Utility
Satchel of Bronze Bombs|28|165|180|Friendly|Utility
Satchel of Iron Bombs|41|230|270|Honored|Utility
Satchel of Dark Iron Bombs|52|285|270|Honored|Utility
Clanking Cord|30|175|180|Friendly|Melee,Tank,Hunter
Gizmo Girdle|30|175|180|Friendly|Melee,Hunter
Whimsical Waistwrap|30|175|180|Friendly|Healer,Caster
Bent Goggles|40|200|180|Friendly|Melee
Dented Goggles|40|200|180|Friendly|Tank
Floppy Goggles|40|200|180|Friendly|Caster,Healer
Stuckbutton Goggles|40|200|180|Friendly|Hunter
Emergency Field Cloak|1|225|270|Honored|Utility
SAF-T Disposable Parachute|1|250|270|Honored|Utility
Gnomish Poultryizer|60|300|360|Honored|Utility
Compact Critter Carrier|40|225|270|Honored|Utility
Stealthman 52|55|300|360|Honored|Utility
Ultralight Goblin Glider|-|300|360|Honored|Utility
Ultrasafe Rechargeable Battery|60|300|360|Honored|Utility
SAF-T Tabs|1|25|45|-|Utility
EZ-Thro Wrap|1|100|45|-|Utility
No Slip SAF-T Padding|1|145|45|-|Utility
SAF-T Bell|1|175|180|Friendly|Utility
EZ-Thro Fireproof Fuse|1|190|180|Friendly|Utility
]])

local leatherLow = {
    {"Leather Belt",12,60,30}, {"Leather Gloves",15,75,30},
    {"Leather Boots",17,85,30}, {"Leather Hood",20,100,30},
    {"Leather Tunic",22,110,30},
}
local leatherHigh = {
    {"Leather Gloves",35,175,60,"Friendly"}, {"Leather Shoulder",42,210,60,"Friendly"},
    {"Leather Bracers",45,225,90,"Honored"},
    {"Leather Boots",47,235,90,"Honored"}, {"Leather Waistguard",50,250,90,"Honored"},
}
local function leatherBase(prefix, legName, role)
    for _,r in ipairs(leatherLow) do add("Leatherworking",prefix.." "..r[1],r[2],r[3],r[4],r[5],role) end
    add("Leatherworking",prefix.." Leather "..legName,25,125,30,"None",role)
end
local function leatherUpper(prefix,role)
    for _,r in ipairs(leatherHigh) do add("Leatherworking",prefix.." "..r[1],r[2],r[3],r[4],r[5],role) end
end
leatherBase("Brawler's","Legguards","Melee")
for _,prefix in ipairs({"Prowler's","Skulker's"}) do leatherUpper(prefix,"Melee") end
leatherBase("Defender's","Kilt","Tank")
leatherUpper("Warden's","Tank")
leatherBase("Trapper's","Legguards","Hunter")
rows("Leatherworking", [[
Stalker's Leather Gloves|35|175|60|Friendly|Hunter
Stalker's Mail Shoulder|42|210|60|Friendly|Hunter
Stalker's Mail Bracers|45|225|90|Honored|Hunter
Stalker's Mail Sabatons|47|235|90|Honored|Hunter
Stalker's Mail Belt|50|250|90|Honored|Hunter
]])
leatherBase("Totemic","Leggings","Melee")
rows("Leatherworking", [[
Skirmisher's Leather Gloves|35|175|60|Friendly|Melee
Skirmisher's Mail Shoulder|42|210|60|Friendly|Melee
Skirmisher's Mail Bracers|45|225|90|Honored|Melee
Skirmisher's Mail Sabatons|47|235|90|Honored|Melee
Skirmisher's Mail Belt|50|250|90|Honored|Melee
]])
leatherBase("Stormrider's","Kilt","Caster")
leatherUpper("Skycaller's","Caster")
rows("Leatherworking", [[
Skycaller's Mail Shoulder|42|210|60|Friendly|Caster
Skycaller's Mail Bracers|45|225|90|Honored|Caster
Skycaller's Mail Sabatons|47|235|90|Honored|Caster
Skycaller's Mail Belt|50|250|90|Honored|Caster
]])
leatherBase("Wisdom's","Leggings","Healer")
leatherUpper("Mender's","Healer")
rows("Leatherworking", [[
Mender's Mail Shoulder|42|210|60|Friendly|Healer
Mender's Mail Bracers|45|225|90|Honored|Healer
Mender's Mail Sabatons|47|235|90|Honored|Healer
Mender's Mail Belt|50|250|90|Honored|Healer
Forceful Thick Armor Kit|40|185|60|Friendly|Melee
Mystic Rugged Armor Kit|50|235|90|Honored|Caster
]])

-- Six full cloth sets and the truncated Pristine set.
local function tailorLow(prefix, role)
    local parts = {"Boots","Gloves","Sash","Circlet","Gown","Leggings"}
    local lv = {12,15,17,20,22,25}
    local sk = {60,75,85,100,110,125}
    for i,part in ipairs(parts) do add("Tailoring",prefix.." "..part,lv[i],sk[i],30,"None",role) end
end
local function tailorHigh(hand,nether,boots,role)
    add("Tailoring",hand.." Handwraps",35,165,60,"Friendly",role)
    add("Tailoring",nether.." Shoulders",42,195,60,"Friendly",role)
    add("Tailoring",nether.." Cuffs",45,205,60,"Friendly",role)
    add("Tailoring",boots.." Waistcord",47,215,60,"Friendly",role)
    add("Tailoring",boots.." Sandals",50,235,90,"Honored",role)
end
tailorLow("Flame","Caster")  tailorHigh("Fiery","Netherflame","Fiery","Caster")
tailorLow("Silky","Caster")  tailorHigh("Frothing","Netherfroth","Frothing","Caster")
tailorLow("Pearly","Caster") tailorHigh("Golden","Nethershine","Golden","Caster")
tailorLow("Shadow","Caster") tailorHigh("Black","Netherpearl","Black","Caster")
tailorLow("Shining","Caster") tailorHigh("Radiant","Netherlight","Radiant","Caster")
tailorLow("Pristine","Healer")
rows("Tailoring", [[
Nethergeld Shoulders|42|195|60|Friendly|Healer
Nethergeld Cuffs|45|205|60|Friendly|Healer
Gilded Waistcord|47|215|60|Friendly|Healer
Gilded Sandals|50|235|90|Honored|Healer
Mageweave Reagent Bag|-|190|60|Friendly|Utility
Runecloth Reagent Bag|-|215|60|Friendly|Utility
]])

-- Comparison is by *effect*, not by matching recipe names.
RRP.ByKey["Alchemy|Elixir of Lesser Intellect"].alternative =
    "Elixir of Wisdom (trainer): both +6 Intellect; Wisdom lasts 60m instead of 30m. Different herbs."
RRP.CatalogSource = "https://www.wow-professions.com/forever/merchants-favor-durotar-supply-azeroth-commerce"
