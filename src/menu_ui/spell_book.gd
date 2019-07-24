extends "res://src/menu_ui/in_game_menu.gd"


func _on_spell_item_selected(index: int, sifting: bool) -> void:
	if not sifting:
		globals.play_sample("spell_select")
	selected = spell_book.get_item_metadata(index)
	selected_index = index
	if spell_book.is_cooling_down(index) or get_owner().dead:
		item_info_hide_except()
	else:
		item_info_hide_except(["cast"])
	selected.describe()
	if selected.get_index() == 0:
		item_info.get_node(@"s/h/left").set_disabled(true)
	if selected_index == spell_book.get_item_count() - 1:
		item_info.get_node(@"s/h/right").set_disabled(true)
	spell_menu.hide()
	item_info.show()

func _on_back_pressed():
	globals.play_sample("spell_book_close")
	spell_menu.hide()
	hide_menu()
