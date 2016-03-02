
-- The following is a representation of how we start (for each layer)
-- (The caret symbol is the turtle at start, with initial_step_ahead set to 1).
-- Higher numbers increase the distance
-- A 0 degrees heading means facing "north" IN THIS REFERENCE FRAME, NOT MINECRAFT
--  ########
--  ########
--  ########
--  ########
--  ^


os.loadAPI("/" .. fs.getDir(shell.getRunningProgram()) .. "/../lib/navigation.lib.lua");



local argv = { ... };
local size_x = tonumber(argv[1]);
local size_y = tonumber(argv[2]);
local target_layer = tonumber(argv[3]);
local initial_step_ahead = tonumber(argv[4]);


	if (target_layer == nil) then
		target_layer = 0;
	end;

	if (initial_step_ahead == nil) then
		initial_step_ahead = 1;
	end;

	
	if (((size_x == nil) or (size_x < 1)) or ((size_y == nil) or (size_y < 1)) or ((initial_step_ahead == nil) or (initial_step_ahead < 1))) then
		print("Usage:");
		print("    dig_box <size_x> <size_y> [ target_layer = 0 [ initial_step_ahead = 1 ]]");
		print("    (X/Y/stepahead values must be positive)");
		return 1;
	end;


	print("Positioning to initial square");
	local step_ahead_loop;
	-- let's move ahead as much as it takes
	for step_ahead_loop = 1, initial_step_ahead do
		dig_and_go("N");
		offset_y = 0; -- this doesn't count
	end;

	print("Initial square reached");
	print("Digging " .. size_x .. "x" .. size_y .. "x" .. (math.abs(target_layer) + 1) .. " cavity");
	

	local on_bedrock = false;
	local low_fuel = false;
	local dig_complete = false;
	local layer_complete = false;
	local returning_y = false;
	local returning_x = false;
	local block_below = nil;

	-- we stop if:
	--  - we're going down and we hit bedrock
	--  - we're finished
	--  - we've got just enough fuel to get back to origin

	while (not (((target_layer < 0) and on_bedrock) or dig_complete or low_fuel)) do

		print("Excavating layer " .. offset_z .. "; target is " .. target_layer);
		layer_complete = false;

		while (not layer_complete) do
			-- did we just complete a column?
			if ((returning_y and (offset_y == 0)) or ((not returning_y) and (offset_y >= (size_y - 1)))) then
				-- Yes we are. did we just complete a row too?
				if ((returning_x and (offset_x == 0)) or ((not returning_x) and (offset_x >= (size_x - 1)))) then

					-- we just completed a column AND a row. Time to invert everything and loop out.
					returning_y = (not returning_y);
					returning_x = (not returning_x);
					layer_complete = true;

					-- we also ditch all the rubbish and refuel if possible/needed
					print("Layer complete. Refueling and discarding blacklisted blocks");
					local slot_idx;
					local slot_info;
					local previous_fuel_level;

					for slot_idx = 1, 16 do

						turtle.select(slot_idx);
						slot_info = turtle.getItemDetail(slot_idx);
						previous_fuel_level = turtle.getFuelLevel();

						if (slot_info) then
							if (blacklisted_fuels[string.upper(slot_info.name)] == nil) then
								if (previous_fuel_level < turtle.getFuelLimit()) then
									-- we refuel if possible, desirable and needed
									if (turtle.refuel()) then
										print("Refueled " .. (turtle.getFuelLevel() - previous_fuel_level) .. " units from slot " .. slot_idx .. " (" .. slot_info.name ..")");
										print("New fuel level: " .. turtle.getFuelLevel());
									end;
								end;
							else
								print("Fuel `" .. slot_info.name .. "` at slot " .. slot_idx .. " is blacklisted");
							end;


							if (blacklisted_blocks[string.upper(slot_info.name)]) then
								print("Item `" .. slot_info.name .. "` at slot " .. slot_idx .. " is blacklisted. Dropping");
								turtle.drop();
							end;

						end;
						
						
					end;
				else
					-- this is just the end of a column. We just shift one column and invert N/S
					if (returning_x) then
						dig_and_go("W");
					else
						dig_and_go("E");
					end;
					returning_y = (not returning_y);
				end;
			else
				-- no. keep digging N/S
				if (returning_y) then
					dig_and_go("S");
				else
					dig_and_go("N");
				end;
			end;

			-- if we're digging down, then it's time to find out what's beneath us,
			-- in order to stop at the first bedrock we meet
			if (target_layer < 0) then
				local block_below = nil;
				local block_is_below = false;

				block_is_below, block_below = turtle.inspectDown();
				if (not block_is_below) then
					-- we just re-nullify it
					block_below = nil;
				end;

				if (block_below ~= nil) then
					if ((not on_bedrock) and (string.upper(block_below.name) == "MINECRAFT:BEDROCK")) then
						on_bedrock = true;
						print("Bedrock encountered. Will stop at this layer")
					end;
				end;
			end;

			
			if (turtle.getFuelLevel() < (initial_step_ahead + math.abs(offset_x) + math.abs(offset_y) + math.abs(offset_z))) then
				low_fuel = true;
				print("Fuel level barely sufficient to return to base. Returning to starting point");
			end;
			
		end;

		dig_complete = (offset_z == target_layer);

		if (dig_complete) then
			print("Excavation complete. Returning to starting point");
		else
			if (target_layer < 0) then
				dig_and_go("D");
			else
				dig_and_go("U");
			end;
		end;

	end;

	back_to_start();

	-- let's move back to the starting point
	for step_ahead_loop = 1, initial_step_ahead do
		dig_and_go("S");
	end;
	heading_set("N");
