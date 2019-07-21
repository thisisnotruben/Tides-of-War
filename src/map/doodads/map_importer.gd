extends Node

export (PackedScene) var map_to_import

func _ready():
	var code = check_map()
	printt("Error code:", code)

func check_map():
	var scene = PackedScene.new()
	var map = map_to_import.instance()

	map.get_node(@"meta").hide()
	map.get_node(@"zed/z1").set_y_sort_mode(true)
	map.get_node(@"meta/coll_nav").set_collision_friction(0)
	map.get_node(@"meta/coll_nav").set_modulate(Color(1.0, 1.0, 1.0, 0.5))

	for node in map.get_children():
		node.set_use_parent_material(true)
		for sub_node in node.get_children():
			sub_node.set_use_parent_material(true)

	var paths = Node2D.new()
	paths.set_name("paths")
	map.get_node(@"meta").add_child(paths)
	map.get_node(@"meta").set_z_index(1)
	paths.set_owner(map)

	var loaded_day_time = load("res://src/map/doodads/day_time.tscn")
	var day_time = loaded_day_time.instance()
	map.add_child(day_time)
	day_time.set_owner(map)

	var loaded_veil = load("res://src/map/doodads/veil_fog.tscn")
	var veil = loaded_veil.instance()
	map.add_child(veil)
	veil.set_owner(map)
	veil.hide()

	for graveyard in map.get_node(@"meta/gravesites").get_children():
		graveyard.add_to_group("gravesite", true)

	var count = 0
	for character in map.get_node(@"zed/characters").get_children():
		if character.is_class("Position2D"):
			var lp = load("res://src/character/player/player.tscn")
			var player = lp.instance()
			player.set_name("player")
			map.get_node(@"zed/z1").add_child(player)
			player.set_owner(map)
			player.set_global_position(character.global_position)
		else:
			var tex = character.get_texture().get_path()
			var parsed_name = ""
			var npc
			for letter in character.get_name():
				if not letter.is_valid_integer():
					parsed_name += letter
			parsed_name = parsed_name.strip_edges().capitalize()
			if "<*>" in character.get_name():
				parsed_name = parsed_name.split("<*>")[0] + "-%s<*>" % count
				count += 1
			elif parsed_name == "" and not "target_dummy" in tex.to_lower():
				parsed_name = tex.get_base_dir().get_file()
				if parsed_name == "critter":
					parsed_name += "-" + tex.get_basename().get_file().split("_")[0]
				parsed_name += "-%s" % count
				if "comm" in tex.get_file().get_basename().to_lower():
					parsed_name += "<#>"
				count += 1
			if tex.get_base_dir().get_file() == "misc":
				var loaded_npc = load("res://src/misc/other/target_dummy.tscn")
				npc = loaded_npc.instance()
				parsed_name = "Target Dummy-%s" % count
				count += 1
			else:
				var loaded_npc = load("res://src/character/npc/npc.tscn")
				npc = loaded_npc.instance()
			npc.set_name(parsed_name)
			map.get_node(@"zed/z1").add_child(npc)
			npc.set_owner(map)
			npc.set_global_position(character.global_position)


	for cell in map.get_node(@"zed/z1").get_used_cells():
		var tile = map.get_node(@"zed/z1").get_cellv(cell)
		var path = "res://src/misc/light/torch_post"
		match tile:
			10266:
				path += "_base.tscn"
			10267:
				path += ".tscn"
			10376:
				path += "_black_base.tscn"
			10377:
				path += "_black.tscn"
		if path.get_extension() == "tscn":
			var x = load(path)
			var i = x.instance()
			i.set_global_position(cell * Vector2(16.0, 16.0) + Vector2(8.0, 16.0))
			map.get_node(@"zed/z1").add_child(i)
			i.set_owner(map)
			i.set_name("light-%s" % count)
			count += 1

	for tilemap in map.get_node(@"ground").get_children():
		for cell in tilemap.get_used_cells():
			var tile = tilemap.get_cellv(cell)
			var path = "res://src/misc/light/"

			match tile:
				2739:
					path += "pit.tscn"
				2633:
					path += "torch.tscn"
				2742:
					path += "torch_handles.tscn"
				6857:
					path += "torch_handles_black.tscn"
			if path.get_extension() == "tscn":
				var x = load(path)
				var i = x.instance()
				i.set_global_position(cell * Vector2(16.0, 16.0) + Vector2(8.0, 8.0) - i.get_offset())
				map.get_node(@"zed/z1").add_child(i)
				i.set_owner(map)
				i.set_name("light-%s" % count)
				count += 1

	map.get_node(@"zed/characters").queue_free()

	map.get_node(@"zed/z1").move_child(map.get_node(@"zed/z1/player"), 0)
	map.get_node(@"meta").move_child(map.get_node(@"coll_nav"), 0)
	map.move_child(map.get_node(@"day_time"), 0)
	map.move_child(map.get_node(@"veil_fog"), 1)
	map.move_child(map.get_node(@"meta"), 2)

	map.set_script(load("res://src/map/map.gd"))
	scene.pack(map)
	return ResourceSaver.save(map.get_filename(), scene)
