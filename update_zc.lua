local required_paths = {
	"bin", "lib"
};


local base_url = "https://raw.githubusercontent.com/z0rb1n0/Z0rbputerCraft/master";

local update_files = {
	"update_zc.lua",
	"lib/navigation.lib.lua",
	"bin/dig_box.lua"
};



-- we create the new directories
local path_id; local path_looper;

for path_id, path_looper in ipairs(required_paths) do
	if (not fs.exists("/" .. path_looper)) then
		fs.makeDir("/" .. path_looper);
	end;
end;



-- we the update the files
local target_file;
for path_id, path_looper in ipairs(update_files) do
	source_url = (base_url .. "/" .. path_looper);
	target_file = ("/" .. path_looper);
	print("Updating `" .. target_file .. "` from `" .. source_url .. "`");
	if (fs.exists(target_file .. ".download")) then
		fs.delete(target_file .. ".download");
	end;
	if (shell.run("wget", source_url, (target_file .. ".download"))) then
		if (fs.exists(target_file)) then
			fs.delete(target_file);
		end;
		fs.move((target_file .. ".download"), target_file);
	end;
end;
