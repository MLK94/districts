-- This is the first grid script I wrote and as such, I call it the "default" 9x9(81) sector grid.
--
local storage = minetest.get_mod_storage()
districts.db_entry = "sector_names_9" -- This is the name of the mod storage entry you want to store your sector numbers and their region names in.
districts.grid_sizex = 9 
districts.grid_sizey = 1 -- Not used yet. Districts cover entire Y axis.
districts.grid_sizez = 9  
-- This is ignored once a database entry has been set. If running for the first time, it is best to leave this dummy data in.
districts.names = {["41"] = "Middle of the grid!"} 


-- Set lower left boundary points. Sector area sizes have not been written in yet. Variables are global and can be altered on the fly for experiments or read into a formspec for other uses.
-- IMPORTANT: These tables MUST have one more entry than their grid size, i.e. if grid_sizex = 9 then the number of entries in dboundx has to be 10.
-- DOUBLEY IMPORTANT: The numbers MUST be in ascending order. The first number must be BELOW the minimum map size and the last number must be ABOVE it (so that is normally -31007 and +31007)
-- If you fail to follow these conditions, it will result in broken or misaligned districts (at least) or cause a server crash (more likely). If in doubt, 9x9 works well enough.
-- I have not considered even numbers in the grid but it will work, know that dboundx[(grid_sizex/2)+1] will usually be zero (dboundx will have an odd number if you've done it right).
districts.dboundx = {"-32000","-24000","-17000","-10000","-3000","3000","10000","17000","24000","32000"}
districts.dboundy = {}
districts.dboundz = {"-32000","-24000","-17000","-10000","-3000","3000","10000","17000","24000","32000"}


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
{"Hammond District","1","2","3","4"}, -- Yep, each "District" can have multiple sectors. You just have to work out the sector numbers you want! And make sure they are in quotes (quirky coding and all that).
}
for i, dataRow in ipairs(override_table) do
    local sname = dataRow[1]
    for k = 2, #dataRow do
        local sector = tostring(dataRow[k])
        if sector then 
            districts.names[tostring(sector)] = tostring(sname)
        else
            minetest.log("dataRow sector failure in override table") -- Have not seen this happen since I fixed something early on in development but have left it here for reference.
        end
    end
end
storage:set_string(districts.db_entry,minetest.serialize(districts.names)) -- So, we set up dnames, load mod storage into it, override with custom settings, then save to mod storage.





