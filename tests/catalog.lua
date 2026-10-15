-- Run from repository root: lua5.1 tests/catalog.lua
local RRP = {}
local chunk = assert(loadfile("RedridgeRecipePlanner/Catalog.lua"))
chunk("RedridgeRecipePlanner",RRP)
local counts = {}
local known = 0
for _,r in ipairs(RRP.Catalog) do
    assert(type(r.name)=="string" and #r.name>0, "Bad name")
    assert(type(r.key)=="string" and RRP.ByKey[r.key] == r, "Bad key")
    assert(type(r.favor)=="number" and r.favor>0, "Bad favor: "..r.name)
    assert(type(r.skill)=="number" and r.skill>0, "Bad skill: "..r.name)
    assert(type(r.roles)=="string" and r.roles~="", "Missing roles: "..r.name)
    counts[r.profession]=(counts[r.profession] or 0)+1
    known=known+1
end
local expected={
    Alchemy=29, Blacksmithing=61, Cooking=6, Enchanting=39,
    Engineering=26, Leatherworking=81, Tailoring=67,
}
for prof,number in pairs(expected) do
    assert(counts[prof] == number, prof.." expected "..number.." got "..tostring(counts[prof]))
end
assert(known==309, "Catalog count "..known.." != 309")
assert(RRP.ByKey["Alchemy|Elixir of Lesser Intellect"].alternative)
print("Catalog verified: "..known.." unique recipes in 7 professions")
