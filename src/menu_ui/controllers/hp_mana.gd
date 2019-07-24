extends "res://src/menu_ui/in_game_menu.gd"


func _on_unit_hud_pressed() -> void:
	if get_owner().target:
		globals.play_sample("click5")
		get_owner().set_target(null)

func _on_move_hud(player: bool=true) -> void:
	var meta: Dictionary = {"node":hp_mana.get_node(@"h/p/h/g"), "amount":Vector2(-34.0, 0.0)}
	if player:
		if meta.node.rect_size.x == 100:
			meta.amount.x = -86.0
		if meta.node.rect_position.x != 0:
			meta.amount.x = 0.0
	else:
		meta.node = hp_mana.get_node(@"h/u/h/g")
		meta.amount = Vector2(331.0, 0.0)
		if meta.node.rect_size.x == 100:
			meta.amount.x = 383.0
		if meta.node.rect_position.x != 297:
			meta.amount.x = 297.0
	$tween.interpolate_property(meta.node, @":rect_position", meta.node.rect_position, \
	meta.amount, 0.5, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	$tween.start()