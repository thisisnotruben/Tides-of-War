extends Node2D
class_name Map

onready var _map: TileMap = $meta/coll_nav
#onready var quest_system = $quests
onready var astar: AStar = AStar.new()

var path_start_position: Vector2 = Vector2() setget _set_path_start_position
var path_end_position: Vector2 = Vector2() setget _set_path_end_position
var obstacles: PoolVector2Array = PoolVector2Array()
var map_size: Vector2 = Vector2()

const _HALF_CELL_SIZE: Vector2 = Vector2(8.0, 8.0)
const ASTAR_OCCUPIED_WEIGHT: float = 25.0
const ASTAR_NORMAL_WEIGHT: float = 1.0

func _ready() -> void:
	globals.current_scene = self
	map_size = _map.get_used_rect().size
	set_obstacles()
	var walkable_cells_list: PoolVector2Array = astar_add_walkable_cells(obstacles)
	astar_connect_walkable_cells_diagonal(walkable_cells_list)
	set_veil_size()
	set_player_camera_limits(globals.player)
	set_units()
	randomize()

##############
# Setup Code #
##############

func set_player_camera_limits(player) -> void:
	var map_limits: Rect2 = $ground/g1.get_used_rect()
	var map_cellsize: Vector2 = $ground/g1.get_cell_size()
	player.get_node(@"img/camera").limit_left = map_limits.position.x * map_cellsize.x
	player.get_node(@"img/camera").limit_right = map_limits.end.x * map_cellsize.x
	player.get_node(@"img/camera").limit_top = map_limits.position.y * map_cellsize.y
	player.get_node(@"img/camera").limit_bottom = map_limits.end.y * map_cellsize.y

func set_veil_size() -> void:
	var veil_size: Vector2 = map_size * _HALF_CELL_SIZE
	$veil_fog.get_process_material().set_emission_box_extents(Vector3(veil_size.x ,veil_size.y, 0.0))
	$veil_fog.set_amount(int(round((veil_size.x + veil_size.y) / 2.0)))
	$veil_fog.set_visibility_rect(Rect2(-veil_size, veil_size * 2.0))
	$veil_fog.set_global_position(veil_size)

func set_veil(dead: bool=true) -> void:
	$veil_fog.set_emitting(dead)
	if dead:
		set_material(load("res://src/map/doodads/veil.tres"))
		$veil_fog.show()
	else:
		set_material(null)
		$veil_fog.hide()

func set_units() -> void:
	"""master function for set_rand & set_determined unit"""
	for unit in $zed/z1.get_children():
		if "character" in unit.get_filename():
			unit.origin = get_grid_position(unit.get_global_position())
			unit.set_global_position(unit.origin)
			unit.path.append(occupy_origin_cell(unit.origin))
			if unit.npc:
				if globals.unit_meta[get_name()].has(unit.get_name()) or "<*>" in unit.get_name():
					set_determined_unit(unit)
				else:
					set_randomized_unit(unit)

func set_determined_unit(unit: Character) -> void:
	var uname: String = unit.get_name()
	if "<*>" in uname:
		uname = uname.split('-')[0]
	var unit_meta = globals.unit_meta[get_name()][uname]
	for attribute in unit_meta:
		match attribute:
			"img":
				unit.set_img("res://asset/img/character".plus_file(unit_meta[attribute]))
			"item", "spell":
				if unit_meta.type == "trainer" or unit_meta.type == "merchant":
					for item in unit_meta[attribute]:
						var itm = globals.get(attribute).instance()
						for item_attribute in item:
							itm.set(item_attribute, item[item_attribute])
						itm.get_obj(unit, false)
			_:
				unit.set(attribute, unit_meta[attribute])

func set_randomized_unit(unit: Character) -> void:
	var race: String = unit.get_name().to_lower().split('-')[0]
	var dir_path: String = "res://asset/img/character".plus_file(race)
	var sprites: PoolStringArray = PoolStringArray()
	var dir: Directory = Directory.new()
	var res: String
	dir.open(dir_path)
	dir.list_dir_begin(true, true)
	while true:
		res = dir.get_next()
		if res == '':
			break
		res = dir_path.plus_file(res)
		if dir.file_exists(res) and res.get_extension() != "tsx" \
		and not "flail" in res and not "tsx.import" in res:
			if "critter" in unit.get_name():
				if not unit.get_name().split('-')[1] in res:
#				checks if critter race is equal with sprite race
#				if not, onto the next
					continue
			elif ("<#>" in unit.get_name() and not "comm" in res) \
			or (not "<#>" in unit.get_name() and "comm" in res):
#				same condition as critters
				continue
			if ".import" in res:
				res.erase(res.find(".import"), 7)
			sprites.append(res)
	dir.list_dir_end()
	res = sprites[randi() % sprites.size()]
	unit.world_name = globals.unit_meta.meta[race][res.get_file().get_basename()]
	unit.enemy = globals.unit_meta.meta[race].enemy
	unit.set_img(res)

#####################
# Navigational Code #
#####################

func set_obstacles() -> void:
	obstacles = PoolVector2Array()
	for cell in _map.get_used_cells():
		if _map.get_cellv(cell) == 4577:
			obstacles.append(cell)

func astar_add_walkable_cells(obstacles=PoolVector2Array()) -> PoolVector2Array:
	astar.clear()
	var points_array: PoolVector2Array = PoolVector2Array()
	for y in map_size.y:
		for x in map_size.x:
			var point: Vector2 = Vector2(x, y)
			if point in obstacles:
				continue
			points_array.append(point)
			var point_index: int = calculate_point_index(point)
			astar.add_point(point_index, Vector3(point.x, point.y, 0.0))
	return points_array

func astar_connect_walkable_cells(points_array: PoolVector2Array) -> void:
	for point in points_array:
		var point_index: int = calculate_point_index(point)
		var points_relative: PoolVector2Array = PoolVector2Array([
			Vector2(point.x + 1, point.y),
			Vector2(point.x - 1, point.y),
			Vector2(point.x, point.y + 1),
			Vector2(point.x, point.y - 1)])
		for point_relative in points_relative:
			var point_relative_index: int = calculate_point_index(point_relative)
			if is_outside_map_bounds(point_relative) \
			or not astar.has_point(point_relative_index):
				continue
			astar.connect_points(point_index, point_relative_index, false)

func astar_connect_walkable_cells_diagonal(points_array: PoolVector2Array) -> void:
	for point in points_array:
		var point_index: int = calculate_point_index(point)
		for local_y in 3:
			for local_x in 3:
				var point_relative: Vector2 = Vector2(point.x + local_x - 1, point.y + local_y - 1)
				var point_relative_index: int = calculate_point_index(point_relative)
				if (point_relative == point or is_outside_map_bounds(point_relative)) \
				or not astar.has_point(point_relative_index):
					continue
				astar.connect_points(point_index, point_relative_index, false)

func is_outside_map_bounds(point: Vector2) -> bool:
	return point.x < 0 or point.y < 0 or point.x >= map_size.x or point.y >= map_size.y

func calculate_point_index(point: Vector2) -> int:
	return int(point.x + map_size.x * point.y)

func _get_recalculated_path() -> PoolVector3Array:
	var start_point_index: int = calculate_point_index(path_start_position)
	var end_point_index: int = calculate_point_index(path_end_position)
	return astar.get_point_path(start_point_index, end_point_index)

func _set_path_start_position(value: Vector2) -> void:
	if not value in obstacles and not is_outside_map_bounds(value):
		path_start_position = value

func _set_path_end_position(value: Vector2) -> void:
	if not value in obstacles and not is_outside_map_bounds(value):
		path_end_position = value

func get_apath(world_start: Vector2, world_end: Vector2) -> PoolVector2Array:
	_set_path_start_position(_map.world_to_map(world_start))
	_set_path_end_position(_map.world_to_map(world_end))
	var path_world: PoolVector2Array = PoolVector2Array()
	for point in _get_recalculated_path():
		path_world.append(_map.map_to_world(Vector2(point.x, point.y)) + _HALF_CELL_SIZE)
	return path_world

func get_grid_position(pos: Vector2) -> Vector2:
	return _map.map_to_world(_map.world_to_map(pos)) + _HALF_CELL_SIZE

func set_point_weight(pos: Vector2, weight: float) -> void:
	astar.set_point_weight_scale(calculate_point_index(_map.world_to_map(pos)), weight)

func request_move(cur_pos: Vector2, direction: Vector2) -> Vector2:
	var cell_start: Vector2 = _map.world_to_map(cur_pos)
	var cell_target: Vector2 = cell_start + direction
	var point = calculate_point_index(cell_target)
	if astar.has_point(point):
		if astar.get_point_weight_scale(point) != ASTAR_OCCUPIED_WEIGHT:
			astar.set_point_weight_scale(calculate_point_index(cell_start), ASTAR_NORMAL_WEIGHT)
			astar.set_point_weight_scale(calculate_point_index(cell_target), ASTAR_OCCUPIED_WEIGHT)
			return _map.map_to_world(cell_target) + _HALF_CELL_SIZE
	return Vector2()

func is_valid_move(pos: Vector2) -> bool:
	var point: int = calculate_point_index(_map.world_to_map(pos))
	if astar.has_point(point):
		if astar.get_point_weight_scale(point) == ASTAR_NORMAL_WEIGHT:
			return true
	return false

func reset_path(path_array: PoolVector2Array) -> PoolVector2Array:
	for point in path_array:
		set_point_weight(point, ASTAR_NORMAL_WEIGHT)
	return PoolVector2Array()

func get_attack_slot(unit_pos: Vector2, target_pos: Vector2) -> PoolVector2Array:
	target_pos = _map.world_to_map(target_pos)
	var points_array: PoolVector2Array = PoolVector2Array()
	for local_y in 3:
		for local_x in 3:
			var point_relative: Vector2 = Vector2(target_pos.x + local_x - 1, target_pos.y + local_y - 1)
			var point_relative_index: int = calculate_point_index(point_relative)
			if astar.has_point(point_relative_index):
				if astar.get_point_weight_scale(point_relative_index) != ASTAR_OCCUPIED_WEIGHT:
					points_array.append(point_relative)
	return get_apath(unit_pos, \
	_map.map_to_world(points_array[randi() % points_array.size()]) + _HALF_CELL_SIZE)

func get_patrol_path(world_name: String) -> PoolVector2Array:
	var patrol_paths: Array = $paths.get_children()
	var find_unit: int = patrol_paths.find(world_name)
	if find_unit == -1:
		return PoolVector2Array()
	return patrol_paths[find_unit].points

func occupy_origin_cell(cur_pos: Vector2) -> Vector2:
	cur_pos = _map.world_to_map(cur_pos)
	if not cur_pos in obstacles and not is_outside_map_bounds(cur_pos):
		var cell_point: int = calculate_point_index(cur_pos)
		astar.set_point_weight_scale(cell_point, ASTAR_OCCUPIED_WEIGHT)
		var cell_pos: Vector3 = astar.get_point_position(cell_point)
		return Vector2(cell_pos.x, cell_pos.y)
	print("Object incorrectly placed at\ngrid position: %s\nglobal position: %s\n" \
	% [cur_pos, _map.map_to_world(cur_pos)])
	return Vector2()
