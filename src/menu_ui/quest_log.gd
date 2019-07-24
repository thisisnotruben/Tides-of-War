extends "res://src/menu_ui/in_game_menu.gd"


func _on_filter_pressed() -> void:
	globals.play_sample("click2")
	if quest_log.is_visible():
		quest_log.hide()
		popup.get_node(@"m/filter_options").show()
	else:
		spell_menu.hide()
	popup.show()

func _on_back_pressed():
	globals.play_sample("click3")
	for quest_slot in quest_log.get_node(@"s/v/s/v").get_children():
		quest_slot.show()
	quest_log.hide()
	menu.show()