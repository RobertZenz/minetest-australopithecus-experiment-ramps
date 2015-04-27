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

local function register_node(name, color, nodebox, mesh)
	local node = {
		description = "Node " .. name,
		
		on_punch = function(pos, node, puncher, pointed_thing)
			minetest.after(0.066, function()
				minetest.set_node(pos, {
					name = "air"
				})
			end)
		end,
		tiles = {
			textureutil.dummy(color, tango.aluminium_1)
		}
	}
	
	if nodebox ~= nil then
		node = tableutil.merge(node, {
			drawtype = "nodebox",
			node_box = {
				fixed = nodebox,
				type = "fixed"
			},
			paramtype = "light",
			paramtype2 = "facedir"
		})
	end
	
	if mesh then
		node = tableutil.merge(node, {
			drawtype = "mesh",
			mesh = name .. ".obj"
		})
	end
	
	minetest.register_node("ramps:node_" .. name, node)	
	
	return "ramps:node_" .. name;
end

function create_and_register_nodes()
	local nodes = List:new()
	
	local nodebox_ramp = {}
	local nodebox_outer_corner_ramp = {}
	local nodebox_inner_corner_ramp = {}
	local steps = parameters.nodebox_resolution
	local part = 1 / steps

	for step = 0, steps - 1, 1 do
		table.insert(nodebox_ramp, {
			-0.5, part * step - 0.5, part * step - 0.5,
			0.5, part * step + part - 0.5, 0.5,
		})
	
		table.insert(nodebox_outer_corner_ramp, {
			-0.5 + part * step, part * step - 0.5, part * step - 0.5,
			0.5, part * step + part - 0.5, 0.5,
		})
	
		local inner_corner = -0.5 + part * step
		table.insert(nodebox_inner_corner_ramp, {
			inner_corner, part * step - 0.5, -0.5,
			0.5, part * step + part - 0.5, 0.5,
		})
		table.insert(nodebox_inner_corner_ramp, {
			-0.5, part * step - 0.5, inner_corner,
			inner_corner, part * step + part - 0.5, 0.5,
		})
	end
	
	nodes:add(register_node("heightmap", tango.chameleon_3))
	nodes:add(register_node("ramp", tango.chameleon_3, nodebox_ramp, parameters.use_meshes))
	nodes:add(register_node("inner_corner_ramp", tango.chameleon_3, nodebox_inner_corner_ramp, parameters.use_meshes))
	nodes:add(register_node("outer_corner_ramp", tango.chameleon_3, nodebox_outer_corner_ramp, parameters.use_meshes))
	
	return nodes
end

