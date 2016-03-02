
-- The following is a representation of how we start (for each layer)
-- (The "greater than" symbol is the turtle at start
-- A 0 degrees heading means facing "north" IN THIS REFERENCE FRAME, NOT MINECRAFT
--  ########
--  ########
--  ########
--  ^#######

blacklisted_blocks = {
	["MINECRAFT:ANDESITE"] = true,
	["MINECRAFT:COBBLESTONE"] = true,
	["MINECRAFT:DIORITE"] = true,
	["MINECRAFT:DIRT"] = true,
	["MINECRAFT:GRANITE"] = true,
	["MINECRAFT:GRAVEL"] = true,
	["MINECRAFT:SAND"] = true,
	["MINECRAFT:STONE"] = true
};


-- burning logs is not desirable as we might me mining them
blacklisted_fuels = {
	["MINECRAFT:LOG"] = true,
	["MINECRAFT:LOG2"] = true,
	["MINECRAFT:SAPLING"] = true
};



offset_x = 0;
offset_y = 0;
offset_z = 0;
heading = 0;




local function heading_set(direction)
ret_val = nil;


	local target_heading = nil;

	-- we adjust the direction
	if (direction == "N") then
		target_heading = 0;
	elseif (direction == "E") then
		target_heading = 90;
	elseif (direction == "S") then
		target_heading = 180;
	elseif (direction == "W") then
		target_heading = 270;
	end

	if (target_heading == nil) then
		print( "Direction must be one of the following N, S, E, W");
		return false;
	end;


	-- we do the shortest rotation. Some normalization is required
	local heading_difference = (target_heading - heading);
	if (heading_difference > 180) then
		heading_difference = (heading_difference - 360);
	elseif (heading_difference < -180) then
		heading_difference = (heading_difference + 360);
	end;

	if (heading_difference ~= 0) then
	
		while (heading_difference ~= 0) do

			if (heading_difference < 0) then
				turtle.turnLeft()
				heading_difference = (heading_difference + 90);
			else
				turtle.turnRight()
				heading_difference = (heading_difference - 90);
			end;

		end;
		
		if (ret_val == nil) then
			heading = (target_heading % 360); -- we normalize the angles from 0 to 360
			--print("Heading set to " .. heading .. " degrees");
		else
			print("Failed to set turtle heading");
			return false;
		end;
	end;
	
	ret_val = true;
	
	return ret_val;
end



-- Possible values of "direction" relative to the local grid pictured above,
-- and NOT the global world:
--  N, S, E, W, U, D
local function dig_and_go(direction)
ret_val = nil;


	if ((direction ~= "U") and (direction ~= "D")) then
		if (not heading_set(direction)) then
			print("Call to `heading_set()` failed");
			return false;
		end;
	end;
	
	--print("Moving " .. direction);

	if ((direction ~= "U") and (direction ~= "D")) then
		-- we dig ahead and go there
		if (turtle.detect()) then
			if (not turtle.dig()) then
				print("Failed to dig ahead");
				return false;
			end;
		end;

		if (turtle.forward()) then
			if (heading == 0) then
				offset_y = (offset_y + 1);
			elseif (heading == 90) then
				offset_x = (offset_x + 1);
			elseif (heading == 180) then
				offset_y = (offset_y - 1);
			elseif (heading == 270) then
				offset_x = (offset_x - 1);
			end;
		else
			print("Failed to move ahead");
			return false;
		end;

	else
		-- above or below? This is a little redundant due to specific calls
		if (direction == "U") then
			if (turtle.detectUp()) then
				if (not turtle.digUp()) then
					print("Failed to dig up");
					return false;
				end;
			end;
			if (turtle.up()) then
				offset_z = (offset_z + 1);
			else
				print("Failed to move up");
				return false;
			end;
		elseif (direction == "D") then
			if (turtle.detectDown()) then
				if (not turtle.digDown()) then
					print("Failed to dig down");
					return false;
				end;
			end;
			if (turtle.down()) then
				offset_z = (offset_z - 1);
			else
				print("Failed to move down");
				return false;
			end;
		else
			print("Unsupported direction: " .. direction);
			return false;
		end;
	end;
		
	ret_val = true;

	return ret_val;
end


local function back_to_start()
	while (offset_z ~= 0) do
		if (offset_z < 0) then
			dig_and_go("U");
		else
			dig_and_go("D");
		end;
	end;

	while (offset_x ~= 0) do
		if (offset_x < 0) then
			dig_and_go("E");
		else
			dig_and_go("W");
		end;
	end;

	while (offset_y ~= 0) do
		if (offset_y < 0) then
			dig_and_go("N");
		else
			dig_and_go("S");
		end;
	end;
	
	heading_set("N");

end;



--dig_and_go(argv[1]);




local argv = { ... };
local size_x = tonumber(argv[1]);
local size_y = tonumber(argv[2]);
local target_layer = tonumber(argv[3]);


	if (((size_x == nil) or (size_x < 1)) or ((size_y == nil) or (size_y < 1)) or ((target_layer == nil) or (target_layer == 0))) then
		print("Usage:");
		print("    quarry <size_x> <size_y> <depth_limit>");
		print("    (X/Y values must be positive)");
		return 1;
	end;

	
	-- On even numbered layers, we move right on even numbered rows and left on odd numbers ones.
	-- All the multipliers are inverted for odd numbered layers. Do not forget that all of this is
	-- in the reference frame of the position/heading of the turtle when we start
	
	-- we start by "burrowing" in the first layer, row 0, col 0 (or just moving there if it's air)

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

			
			if (turtle.getFuelLevel() < (math.abs(offset_x) + math.abs(offset_y) + math.abs(offset_z))) then
				low_fuel = true;
				print("Fuel level barely sufficient to return to base. Abandoning excavation");
			end;
			
		end;

		dig_complete = (offset_z == target_layer);
		if (target_layer < 0) then
			dig_and_go("D");
		else
			dig_and_go("U");
		fi;

		
	end;

	back_to_start();
