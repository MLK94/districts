-- This is a 31x31 (961 sectors) monster! each sector should be around 2000x2000 blocks. Central sector will only be one sector, as is with the default 9x9 grid. Odd numbered grids do this.
-- 
local storage = minetest.get_mod_storage()
districts.db_entry = "sector_names_31" -- This is the name of the mod storage entry you want to store your sector numbers and their region names in.
districts.grid_sizex = 31 
districts.grid_sizey = 1 -- Not used yet. Districts cover entire Y axis.
districts.grid_sizez = 31 
-- This is ignored once a database entry has been set. If running for the first time, it is best to leave this dummy data in.
districts.names = {["481"] = "Middle of the grid! -1000 to 1000 x/z"}  

districts.dboundx = {}
districts.dboundy = {}
districts.dboundz = {}
districts.b_first = -31000 -- maybe -31007 ?
districts.b_last = 31000

-- process the x grid lines
-- 21 grid lines, 10,10 to 11,11 centre (4 sectors)
local dcount = districts.b_first
local dstep = 2000 -- gonna cheat and set it manually for this setup! but i imagine it would be ((b_last-b_first) / grid_sizex), which in this case will create nice round numbers ;-)
while dcount <= districts.b_last do
    table.insert(districts.dboundx,tostring(dcount))
    dcount = dcount + dstep
end

-- process the z grid lines (replicate x)
local dcount = districts.b_first
local dstep = 2000
while dcount <= districts.b_last do
    table.insert(districts.dboundz,tostring(dcount))
    dcount = dcount + dstep
end

-- Check for mod storage string (first time run usually fails check).
local names_exist = storage:get_string(districts.db_entry)
if not names_exist or names_exist == "" or names_exist == nil then
    storage:set_string(districts.db_entry,minetest.serialize(districts.names)) -- This caused issues on my computer if the initial districts.names table was empty (""), hence the dummy code above.
end
districts.names = minetest.deserialize(storage:get_string(districts.db_entry))

-- Regardless of who sets or removes a district name, 
-- upon reboot you can reinforce protected/indisputable districts with this override section.
local override_table = {}
override_table = {
{"Central District","481"}, -- Set a district name and the sector(s) you want it on. For multiple sectors just add more "numbers" e.g. {"Big Place","1","2","3","4","5"}
}
for i, dataRow in ipairs(override_table) do
    local sname = dataRow[1]
    for k = 2, #dataRow do
        local sector = tostring(dataRow[k])
        if sector then 
            districts.names[tostring(sector)] = tostring(sname)
        else
            minetest.log("dataRow sector failure in override table") -- Have not seen this happen since I fixed something early on in development but have left it here for reference and already forgotten why :-D
        end
    end
end
storage:set_string(districts.db_entry,minetest.serialize(districts.names)) -- So, we set up dnames, load mod storage into it, override with custom settings, then save to mod storage.





