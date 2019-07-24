extends "res://src/menu_ui/in_game_menu.gd"


func _on_inventory_item_selected(index: int, sifting: bool=false) -> void:
	item_info_hide_except()
	selected_index = index
	var bag: Bag = inventory_bag
	inventory.hide()
	selected = inventory_bag.get_item_metadata(index)
	match selected.get_type():
		"WEAPON", "ARMOR":
			if not get_owner().dead:
				item_info.get_node(@"s/h/v/equip").show()
		"FOOD", "POTION":
			item_info.get_node(@"s/h/v/use/label"). \
			set_text("%s" % "Eat" if selected.get_type() == "FOOD" else "Drink")
			if not inventory_bag.is_cooling_down(index) and not get_owner().dead:
				item_info.get_node(@"s/h/v/use").show()
	if not get_owner().dead:
		item_info.get_node(@"s/h/v/drop").show()

	if not sifting:
		globals.play_sample("inventory_open")
		if bag.get_item_slot(selected, true) == 0:
			item_info.get_node(@"s/h/left").set_disabled(true)
		else:
			item_info.get_node(@"s/h/left").set_disabled(false)
		if bag.get_item_slot(selected, true) == bag.get_item_count() - 1:
			item_info.get_node(@"s/h/right").set_disabled(true)
		else:
			item_info.get_node(@"s/h/right").set_disabled(false)
		selected.describe()
		item_info.show()

func _on_back_pressed():
	globals.play_sample("click3")
	inventory.hide()
	menu.show()