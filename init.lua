-- DISTRICTS mod by MaLang 2023

local MP = minetest.get_modpath(minetest.get_current_modname())
local storage = minetest.get_mod_storage()
districts = {}


--
-- These files contain grid sizes, overridden district names, the name of the database entry in use as well as the x/z tables for the grid line co-ordinates. (d20 and d31 feature automated table creation code.)
-- UNCOMMENT ONE LINE FROM THE LIST BELOW TO CHOOSE THAT SIZE OF GRID FOR THE MAP --
--

--dofile(MP.."/d9_default.lua")             -- 9x9 grid (81 sectors)
--dofile(MP.."/d20.lua")                    -- 20x20 (400)
dofile(MP.."/d31.lua")                      -- 31x31 (961)


--------------------------------------------------------------------------------------------------------------

districts.hudtime = 6 -- The numbers of seconds a HUD notification will remain on a player's screen. Moving between regions quickly may cause notifications to vanish quicker than 6 seconds.
districts.timer_interval = 2 -- The interval in seconds between checking all online players' regions for any changes. 
districts.hud = {} -- Each player will need its own HUD. Previously the code created one size fits all and this was causing no end of problems with other display outputs.
districts.pdis = {} -- Holds the name of the sector an online player is in.
districts.secn = {} -- Holds the sector number an online player is in.

--------------------------------------------------------------------------------------------------------------

--
-- Run a timer, checking the name of the sector each player is in. If it is different to the one stored, it is updated and that player is notified of the new region and sector number via HUD.
--

local timer = 0
local hudtext = ""

--HUD

-- timer to check district change
minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer < districts.timer_interval then
		return
	end
	timer = 0
	for _, player in pairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local ppos = player:get_pos()
        	local psector_x,psector_z = 1,1
 
		-- Check player's x-axis against the boundary table.
		local checker = 0 -- remember to nil all one-time variables in this code sometime.
		local checkcount = 1
		while checker == 0 do
		    if ppos.x >= tonumber(districts.dboundx[checkcount]) then
		        checkcount = checkcount +1
		    else
		        checkcount = checkcount -1    
		        checker = 1    
		    end
		end
		psector_x = checkcount
	  
		-- Check player's z-axis against the boundary table.
		local checker = 0 
		local checkcount = 1
		while checker == 0 do
		    if ppos.z >= tonumber(districts.dboundz[checkcount]) then
		        checkcount = checkcount +1
		    else
		        checkcount = checkcount -1    
		        checker = 1    
		    end
		end
		psector_z = checkcount

		-- Calculate the sector number, 1 is top left, NOT bottom left as you might expect!!
		local sectcalc = ((districts.grid_sizez-psector_z)*districts.grid_sizez) + psector_x
	      
		-- Find the district name.
		local dname = districts.names[tostring(sectcalc)]
		if not dname or dname == "" or dname == nil or dname == "nil" then dname = "an unnamed region" end -- Inform the player that an empty district name means it's usually unclaimed or unnamed?

		-- If the player changes sector, update the variable but don't notify the player unless the region changes name.
		if districts.secn[pname] ~= tostring(sectcalc) then
		    districts.secn[pname] = tostring(sectcalc)
		end

		-- If the player changes region, store the new region name and notify the player via a HUD message.
		if districts.pdis[pname] ~= dname then
		    districts.pdis[pname] = dname
		    local hudtext = "You have entered "..dname.."\n(sector "..sectcalc..")"
		    	--HUD
			if not districts.hud[pname] then
				districts.hud[pname] = {}
				districts.hud[pname].id = player:hud_add({
					hud_elem_type = "text",
					name = "Districts",
					text = hudtext,
					number = 0xFFFF00,
					scale = {x = 200, y = 60},
					position = {x = 0.5, y = 0.42},
					offset = {x = 0, y = 0},
					alignment = {x = 0, y = 0},
				    })
			else
			    	player:hud_change(districts.hud[pname].id,"text", hudtext)
			end
		    	minetest.after(districts.hudtime,function()
		        player:hud_change(districts.hud[pname].id,"text","") -- Blank the HUD - The HUD stays active for your session and is only removed when you leave. This shouldn't cause an issue? Famous last words :-D
		    	end)
        	end
    	end
end)




--
-- CHAT COMMANDS --
--

-- Check "districts.db_entry" which should've been set by one of the grid scripts at the beginning. This identifies which mod storage table to read for the chatcommands.
local secnames = districts.db_entry
if not secnames then minetest.log("ERROR","DISTRICTS MOD - secnames failed, db_entry failed, without it the chatcommands will crash the server!!!!") end

-- Chatcommands for manipulating the data in-game (probably best to not use these from console for now!).		
minetest.register_chatcommand("districts", { 
    description = "Shows the name of the district you're in.",
    privs = {interact=true},
    func = function(caller)
        -- Get caller's sector location (as globally stored).
        local dsector = tonumber(districts.secn[caller]) or 0
        if not dsector or dsector == 0 then minetest.chat_send_player(caller, "Unable to retrieve sector number.") return end
        -- Create grid location (1-1 would be the top left of the MT map).
        local srx,srz = 0,0
        local srn = dsector
        while (srz*districts.grid_sizez) < srn do
            srz = srz + 1
        end
        srx = srn - ((srz-1)*districts.grid_sizez)
        -- Get sector name.
        local dname = districts.pdis[caller]
        if not dname or dname == "" or dname == nil or dname == "nil" then dname = "an unnamed region" end
        minetest.chat_send_player(caller, "You are in "..tostring(dname)..", sector "..dsector..", grid location ("..srx.."-"..srz..")")
    end,
})

-- Chatcommand for editing the districts.names table - params: [sector_number] [<name>] (optional, leave empty to wipe - turns into unnamed region or should do) .
minetest.register_chatcommand("districts_name", { 
    description = "Sets the name of the district using its sector number (1st field). Leave name (2nd field) empty to wipe the district name.",
    params = "[sector]".." ".."[<name>]",
    privs = {server=true},
    func = function(caller, param)
        param = param:trim()
        local pnode = ""
        pnode = (param ~= "" and param)
        if not pnode or pnode == "" then 
            minetest.chat_send_player(caller,"failed - parameter cannot be empty!") 
            return
        end
        pnode = tostring(pnode)
        local ptab = pnode:split(" ")
        if #ptab > 6 then -- If you seriously want longer district titles, consider the width of the screen for mobile/tablet users.
            minetest.chat_send_player(caller,"failed - too many parameters!")
            return
        end
        if not tonumber(ptab[1]) then
            minetest.chat_send_player(caller,"failed - first parameter must be a number")
            return
        end
        local sector = tonumber(ptab[1])
        local grid_area = (districts.grid_sizex * districts.grid_sizez)
        if not sector or sector < 1 or sector > grid_area then
            minetest.chat_send_player(caller,"Invalid sector number. Must be between 1 and "..grid_area)
            return
        end
        local sname = ""
        for x = 2,(#ptab-1) do
        sname = sname..ptab[x].." "
        end
        if #ptab > 1 then sname = sname..ptab[#ptab] end -- The sector name doesn't need a space at the end.

        if not sname or sname == "nil" or sname == "" or sname == " " then -- Could it be that the user didn't enter a name? Well then, empty it. Maybe consider nil?
            minetest.chat_send_player(caller,"Wiping the name from sector "..sector)
            sname = "" 
        else
            minetest.chat_send_player(caller,sname.." is now the name of sector "..sector)
            --minetest.chat_send_all(sname.." is now the name of sector "..sector)
        end
        districts.names[tostring(sector)] = tostring(sname) -- Set the new name for the sector.
        storage:set_string(secnames,minetest.serialize(districts.names)) -- Save to mod storage. Seems to be ok so far :-)
    end
})

-- Chatcommand for viewing a map's entire district list in a formspec. This has not been fully tested with a massive district list yet!
minetest.register_chatcommand("districts_list", { 
    description = "Shows a complete list of named sectors.",
    privs = {server=true},
    func = function(caller)
        local ts = storage:get_string(secnames) -- should this be referencing mod storage or the global variable districts.names ??
        if not ts then minetest.chat_send_player(caller,secnames.." doesnt exist in DB, oops!") return end
        local tt = minetest.deserialize(ts)
        if tt == nil or tt == "nil" or tt == " " then minetest.chat_send_player(caller,"Deserialization failure - Pretty bad. :-p") return end
        local tv = {}
        table.foreach (tt, function (k, v) table.insert (tv, k) end ) 
        table.sort (tv) -- Sorts by k, which is the sector number. v is the district name.
        -- formspec data
        local nodezy = ""
        for x, y in pairs(tv) do
            local sr = tostring(y)
            if not sr then 
                minetest.chat_send_player(caller,"Failure whilst trying to read sector. Stopped.")                
                return
            end
            local dn = districts.names[sr]
            if not dn then 
                minetest.chat_send_player(caller,"Failure whilst trying to read names. Stopped.")                
                return 
            end
            if dn == "" or dn == "nil" or dn == nil then dn = "-recently vacated-" end
            -- turn sr into co-ords for the grid location (1-1 is top left of map)
            local srx, srz = 0,0
            local srn = tonumber(y)
            while (srz*districts.grid_sizez) < srn do
                srz = srz + 1
            end
            srx = srn - ((srz-1)*districts.grid_sizez)

            local nadds = sr.." ("..srx.."-"..srz.."): "..dn        --dn.." (sector "..sr..")"
            nodezy = nodezy..nadds..","
        end
        local form_name = "districtB994EVA"
        local sizex = 12
        local sizey = 10
        local tablezy = "district_list"
        local titlezy = "SECTOR / GRID LOC / DISTRICT NAME:"
        local gui = (
            "formspec_version[4]"..
            "size["..sizex..","..sizey.."]"..
            "no_prepend[]"..
            "bgcolor[#55AA55FF;false]"..
            "table[.5,.5;"..(sizex-1)..","..(sizey-1)..";tablezy;"..titlezy..","..nodezy..";1]"
        )
        minetest.show_formspec(caller, form_name ,gui)    
    end
})





-- Scrub a player's hud,sector and district data when they leave the game. 
minetest.register_on_leaveplayer(function(player)
	districts.pdis[player:get_player_name()] = nil
	districts.secn[player:get_player_name()] = nil   
	districts.hud[player:get_player_name()] = nil
end)
