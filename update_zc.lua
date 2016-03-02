local required_paths = {
	"bin", "lib"
};


local base_url = "https://raw.githubusercontent.com/z0rb1n0/Z0rbputerCraft/master";

local update_me = {
	"bin/update_zc.lua",
	"lib/navigation.lua",
	"bin/dig_box.lua"
};



-- we create the new directories
local path_looper;

for path_looper in required_paths do
	if (not fs.exists("/" .. path_looper)) then
		fs.makeDir("/" .. path_looper);
	end;
end;



-- we the update the files
for path_looper in required_paths do
	if (fs.exists("/" .. path_looper)) then
		fs.delete("/" .. path_looper);
	end;
end;
