"""
UI controller for the move cursor.
"""
extends Sprite
class_name Cursor

func _on_anim_finished(anim_name: String) -> void:
	queue_free()

func add_to_map(originator, pos: Vector2) -> void:
	# Deletes self when player adds a new cursor to map
	originator.connect("pos_changed", self, "queue_free")

	globals.current_scene.get_node(@"ground").add_child(self)
	set_global_position(globals.current_scene.get_grid_position(pos))