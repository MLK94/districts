DISTRICTS - cover your entire map with district names, not unlike naming states or counties on a real map.

This is a pre-release, it is currently running on a public server but it does need several changes to the code. If you adjust the minimum and maximum grid values within any of the scripts, note that these values must exist OUTSIDE of your map's limits or there is a possibility of a crash.

There are three sizes at the moment, selected by commenting out a page in the init.lua file. 9x9 (81 sectors), 20x20 (400) and 31x31 (961). The first sector is located in grid location (1,1) which is in the top LEFT of your map, not the bottom left as some might expect.

When a player moves into or out of a sector, if that sector has a different district name the player will be informed of the new district name and sector via a HUD that appears just above the centre of your screen. It does not inform the player if they change sector and it has the same name as the previous sector (for districts that span multiple sectors).

There are three chat commands to control the mod:

/districts (no parameters) - Tells the user the name, sector number and grid location of the district they are in (via chat).

/districts_name (sector) [(name)] - Sets the name of the district using its sector number. Leave name empty to wipe the district name.

/districts_list - Opens a formspec and shows all named sectors on the map.
