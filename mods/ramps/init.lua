--[[
Copyright (c) 2015, Robert 'Bobby' Zenz
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]

log.set_print_all(true)


base_path = minetest.get_modpath(minetest.get_current_modname())

dofile(base_path .. "/nodes.lua")
dofile(base_path .. "/parameters.lua")


-- The list of nodes.
local nodes = create_and_register_nodes()
local noise_manager = nil
local noise_heightmap = nil


-- We'll be giving every player some blocks to place.
minetest.register_on_joinplayer(function(player)
	nodes:foreach(function(item, index)
		player:get_inventory():set_stack("main", index + 1, ItemStack(item .. " 64"))
	end)
end)

-- Main settings for the worldgen.
minetest.register_on_mapgen_init(function(mapgen_params)
	minetest.set_mapgen_params({
		flags = "nolight",
		mgname = "singlenode",
		water_level = -31000
	})
end)

minetest.register_on_generated(function(minp, maxp, seed)
	if noise_manager == nil then
		noise_manager = NoiseManager:new()
		noise_heightmap = noise_manager:get_map2d(5, 0.9, 1, 750)
	end
	
	local placeholder = minetest.get_content_id("ramps:node_heightmap")
	
	local manipulator = MapManipulator:new()
	
	-- Now we will generate the basic heightmap.
	local heightmap = noise_heightmap:get2dMap({ x = minp.x, y = minp.z })
	heightmap = arrayutil.swapped_reindex2d(heightmap, minp.x, minp.z)
	
	for x = minp.x, maxp.x, 1 do
		for z = minp.z, maxp.z, 1 do
			local height = heightmap[x][z]
			height = transform.linear(height, -1, 1, -20, 50)
			
			for y = minp.y, math.min(height, maxp.y), 1 do
				manipulator:set_node(x, z, y, placeholder)
			end
		end
	end
	
	-- And now do the ramps.
	local air = minetest.get_content_id("air")
	local ignore  = minetest.get_content_id("ignore")
	local test = function(node)
		return node == nil or node == ignore or node == air
	end
	
	local mask_equals = function(a, b)
		if b == nil then
			return true
		end
		
		return a == b
	end
	
	local ramps = List:new()
	ramps:add({
		id = minetest.get_content_id("ramps:node_ramp"),
		-- n f n
		-- f   f
		-- n t n
		mask = { nil, false, nil, false, nil, true, nil, false },
		name = "ramps:node_ramp"
	})
	ramps:add({
		id = minetest.get_content_id("ramps:node_inner_corner_ramp"),
		-- f f f
		-- f   f
		-- n f n
		masks = {
			{ false, false, false, false, false, false, true, false },
			{ false, false, false, false, true, false, false, false }
		},
		name = "ramps:node_inner_corner_ramp"
	})
	ramps:add({
		id = minetest.get_content_id("ramps:node_outer_corner_ramp"),
		-- f f n
		-- f   t
		-- n t t
		mask = { false, false, nil, true, true, true, nil, false },
		name = "ramps:node_outer_corner_ramp"
	})
	
	stopwatch.start("rampification")
	for y = minp.y, maxp.y, 1 do
		for x = minp.x, maxp.x, 1 do
			for z = minp.z, maxp.z, 1 do
				if not test(manipulator:get_node(x, z, y)) then
					if test(manipulator:get_node(x, z, y + 1)) then
						--  -- ?- +-
						--  -?    +?
						--  -+ ?+ ++
						local node_mask = {
							test(manipulator:get_node(x - 1, z - 1, y)),
							test(manipulator:get_node(x, z - 1, y)),
							test(manipulator:get_node(x + 1, z - 1, y)),
							test(manipulator:get_node(x + 1, z, y)),
							test(manipulator:get_node(x + 1, z + 1, y)),
							test(manipulator:get_node(x, z + 1, y)),
							test(manipulator:get_node(x - 1, z + 1, y)),
							test(manipulator:get_node(x - 1, z, y))
						}
						minetest.dir_to_facedir({x=0,y=0,z=1})
						ramps:foreach(function(ramp, index)
							local ramp_rotation = -1
							
							if ramp.masks ~= nil then
								for index = 1, #ramp.masks, 1 do	
									local rotation = arrayutil.index(node_mask, ramp.masks[index], mask_equals, 2)
									if rotation >= 0 then
										ramp_rotation = rotation
									end
								end
							else
								ramp_rotation = arrayutil.index(node_mask, ramp.mask, mask_equals, 2)
							end
							
							if ramp_rotation >= 0 then
								local dir = { x = 0, y = 0, z = 0 }
								
								if ramp_rotation == 1 then
									dir.z = -1
								elseif ramp_rotation == 3 then
									dir.x = 1
								elseif ramp_rotation == 5 then
								elseif ramp_rotation == 7 then
									dir.x = -1
								end
								
								manipulator:set_node(x, z, y, ramp.id, minetest.dir_to_facedir(dir, true))
							end
						end)
					end
				end
			end
		end
	end
	stopwatch.stop("rampification")
	
	manipulator:set_data()
end)

