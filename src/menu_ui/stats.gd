extends "res://src/menu_ui/in_game_menu.gd"


func _on_back_pressed():
	globals.play_sample("click3")
	stats_menu.hide()
	menu.show()

func _on_weapon_slot_pressed() -> void:
	item_info_go(get_owner().weapon)

func _on_armor_slot_pressed() -> void:
	item_info_go(get_owner().vest)
