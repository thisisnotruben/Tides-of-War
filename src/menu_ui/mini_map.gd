"""
UI controller the in game mini-map.
"""
extends Node2D
class_name MiniMap

const draw_size: Vector2 = Vector2(14.0, 14.0)
var offset: Vector2 = Vector2(draw_size.x / 2.0, 0.0)
var path: PoolVector2Array = PoolVector2Array()
var ratio: int = 0

func _ready() -> void:
	set_process(false)
	if Directory.new().file_exists("res://asset/img/map/%s.png" % globals.current_scene.get_name()):
		$map.set_texture(load("res://asset/img/map/%s.png" % globals.current_scene.get_name()))
	else:
		get_owner().get_node(@"c/controls/m/right/v/mini_map/icon"). \
		disconnect("pressed", get_owner(), "_on_mini_map_pressed")
	set_owner(get_owner().get_owner())

func _process(delta: float) -> void:
	if get_owner().moving:
		hide()
	else:
		update()

func _draw() -> void:
	"""Draws all units in """
	for unit in get_tree().get_nodes_in_group("npc"):
		var rect : Rect2 = Rect2($player_pos.get_global_position() - (get_owner().get_center_pos() - unit.get_center_pos()) * ratio - offset, draw_size)
		match unit.get_type():
			"PLAYER":
				draw_rect(rect, Color(1.0, 0.0, 0.0))
			"QUEST_GIVER":
				draw_rect(rect, Color(1.0, 1.0, 0.0))
			"TRAINER":
				draw_rect(rect, Color(0.0, 1.0, 1.0))
			"MERCHANT":
				draw_rect(rect, Color(0.0, 1.0, 0.0))
	if get_owner().dead and path.size() > 0:
		for p in path.size() - 1:
			draw_line($player_pos.get_global_position() - (get_owner().get_global_position() - path[p]) * ratio, \
			$player_pos.get_global_position() - (get_owner().get_global_position() - path[p + 1]) * ratio, Color(1.0, 1.0, 1.0), 4.0)
		draw_rect(Rect2($player_pos.get_global_position() - (get_owner().get_global_position() - path[path.size() - 1]) \
		* ratio - offset, draw_size), Color(0.58, 0.816, 0.835))
	draw_rect(Rect2($player_pos.get_global_position() - offset, draw_size), Color(1.0, 0.0, 1.0))

func _on_mini_map_draw() -> void:
	if ratio == 0:
		var tile: TileMap = globals.current_scene.get_node(@"ground/g1")
		ratio = 1.0 / (tile.get_used_rect().size * tile.get_cell_size() / ($map.get_texture().get_size() * $map.get_scale())).x
	if get_owner().dead and get_owner().grave != Vector2() and path.size() == 0:
		path = globals.current_scene.get_apath(get_owner().get_global_position(), get_owner().grave)
	$map.set_position($player_pos.get_global_position() - get_owner().get_center_pos() * ratio)
	set_process(true)

func _on_mini_map_hide() -> void:
	path = PoolVector2Array()
	set_process(false)