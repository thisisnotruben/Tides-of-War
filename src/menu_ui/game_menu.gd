extends "res://src/menu_ui/in_game_menu.gd"


func _on_game_menu_draw() -> void:
	get_tree().set_pause(true)
	list_of_menus.show()
	if get_owner().spell:
		if get_owner().spell.get_sub_type() == "CHOOSE_AREA_EFFECT":
			get_owner().spell.unmake()
	for node in $c.get_children():
		if node != $c/game_menu:
			node.hide()

func _on_game_menu_hide() -> void:
	get_tree().set_pause(false)
	$c/controls.show()
	hp_mana.show()
	popup.hide()
	selected_index = -1
	selected = null
	for node in list_of_menus.get_children():
		if node != menu:
			node.hide()
		else:
			node.show()