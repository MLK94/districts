-- This is a rewrite of the default (9x9) and pushing the grid size to 20x20, which makes 400 sectors.
-- 
local storage = minetest.get_mod_storage()
districts.db_entry = "sector_names_20" -- This is the name of the mod storage entry you want to store your sector numbers and their region names in.
districts.grid_sizex = 20 
districts.grid_sizey = 1 -- Not used yet. Districts cover entire Y axis.
districts.grid_sizez = 20 
-- This is ignored once a database entry has been set. If running for the first time, it is best to leave this dummy data in.
districts.names = {["190"] = "Grid centre (NW)",["191"] = "Grid centre (NE)",["210"] = "Grid centre (SW)",["211"] = "Grid centre (SE)"} 

districts.dboundx = {}
districts.dboundy = {}
districts.dboundz = {}
districts.b_first = -31000 -- maybe -31007 ?
districts.b_last = 31000

-- process the x grid lines
-- 21 grid lines, 10,10 to 11,11 centre (4 sectors)
local dcount = districts.b_first
local dstep = 3100 -- gonna cheat and set it manually for this setup! but i imagine it would be ((b_last-b_first) / grid_sizex), which in this case will create nice round numbers ;-)
while dcount <= districts.b_last do
    table.insert(districts.dboundx,tostring(dcount))
    dcount = dcount + dstep
end

-- process the z grid lines (replicate x)
local dcount = districts.b_first
local dstep = 3100
while dcount <= districts.b_last do
    table.insert(districts.dboundz,tostring(dcount))
    dcount = dcount + dstep
end

-- Check for mod storage string (first time run usually fails check).
local names_exist = storage:get_string(districts.db_entry)
if not names_exist or names_exist == "" or names_exist == nil then
    storage:set_string(districts.db_entry,minetest.serialize(districts.names)) -- This caused issues if the initial districts.names table was empty (""), hence the dummy code above.
end
districts.names = minetest.deserialize(storage:get_string(districts.db_entry))

-- Regardless of who sets or removes a district name, 
-- upon reboot you can reinforce protected/indisputable districts with this override section.
local override_table = {}
override_table = {
--{"Central District","190","191","210","211"} -- Set a district name and the sector(s) you want it on. For multiple sectors just add more "numbers" e.g. {"Big Place","1","2","3","4","5"}
}
for i, dataRow in ipairs(override_table) do
    local sname = dataRow[1]
    for k = 2, #dataRow do
        local sector = tostring(dataRow[k])
        if sector then 
            districts.names[tostring(sector)] = tostring(sname)
        else
            minetest.log("dataRow sector failure in override table") -- Have not seen this happen since I fixed something early on in development but have left it here for reference, to confuse me in the years to come.
        end
    end
end
storage:set_string(districts.db_entry,minetest.serialize(districts.names)) -- So, we set up dnames, load mod storage into it, override with custom settings, then save to mod storage.





