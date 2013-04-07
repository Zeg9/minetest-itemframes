minetest.register_entity("itemframes:item",{
	hp_max = 1,
	visual="wielditem",
	visual_size={x=.33,y=.33},
	collisionbox = {0,0,0,0,0,0},
	physical=false,
	textures={"air"}
})

local facedir = {}
facedir[0] = {x=0,y=0,z=1} --
facedir[1] = {x=1,y=0,z=0} --
facedir[2] = {x=0,y=0,z=-1} --
facedir[3] = {x=-1,y=0,z=0} --

local remove_item = function(pos)
	objs = minetest.env:get_objects_inside_radius(pos, .5)
	for _, obj in ipairs(objs) do
		if obj:get_luaentity().name == "itemframes:item" then
			obj:remove()
		end
	end
end

local update_item = function(pos, node)
	remove_item(pos)
	local meta = minetest.env:get_meta(pos)
	if meta:get_string("item") ~= "" then
		posad = facedir[node.param2]
		pos.x = pos.x + posad.x*7/16
		pos.y = pos.y + posad.y*7/16
		pos.z = pos.z + posad.z*7/16
		local e = minetest.env:add_entity(pos,"itemframes:item")
		local name = meta:get_string("item")
		e:set_properties({textures={name}})
		local yaw = math.pi*2 - node.param2 * math.pi/2
		e:setyaw(yaw)
	end
end

local drop_item = function(pos)
	local meta = minetest.env:get_meta(pos)
	if meta:get_string("item") ~= "" then
		minetest.env:add_item(pos, meta:get_string("item"))
		meta:set_string("item","")
	end
	remove_item(pos)
end

minetest.register_node("itemframes:frame",{
	description = "Item frame",
	drawtype = "nodebox",
	node_box = { type = "fixed", fixed = {-0.5, -0.5, 7/16, 0.5, 0.5, 0.5} },
	tiles = {"itemframes_frame.png"},
	inventory_image = "itemframes_frame.png",
	wield_image = "itemframes_frame.png",
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,
	groups = { choppy=2,dig_immediate=2 },
	legacy_wallmounted = true,
	sounds = default.node_sound_defaults(),
	after_place_node = function(pos, placer, itemstack)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("owner",placer:get_player_name())
		meta:set_string("infotext","Item frame (owned by "..placer:get_player_name()..")")
	end,
	on_rightclick = function(pos, node, clicker, itemstack)
		local meta = minetest.env:get_meta(pos)
		if clicker:get_player_name() == meta:get_string("owner") then
			drop_item(pos,clicker)
			meta:set_string("item",itemstack:get_name())
			itemstack:take_item()
			update_item(pos,node)
		end
		return itemstack
	end,
	on_punch = function(pos,node,puncher)
		local meta = minetest.env:get_meta(pos)
		if puncher:get_player_name() == meta:get_string("owner") then
			drop_item(pos)
		end
	end,
	can_dig = function(pos,player)
		
		local meta = minetest.env:get_meta(pos)
		return player:get_player_name() == meta:get_string("owner")
	end,
})


minetest.register_abm({
	nodenames = {"itemframes:frame"},
	interval = 1.0,
	chance = 2,
	action = function(pos, node, active_object_count, active_object_count_wider)
		update_item(pos,node)
	end,
}) -- This allows items to reappear in frames when chunks are unloaded

