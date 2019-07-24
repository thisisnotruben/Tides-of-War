extends "res://src/menu_ui/in_game_menu.gd"


func _on_spell_book_pressed() -> void:
	globals.play_sample("turn_page")
	spell_menu.get_node(@"s/v/m/v/label"). \
	set_text("Health: %s / %s" % [get_owner().hp, get_owner().hp_max])
	spell_menu.get_node(@"s/v/m/v/label2"). \
	set_text("Mana: %s / %s" % [get_owner().mana, get_owner().mana_max])
	menu.hide()
	$c/game_menu.show()
	spell_menu.show()

func _on_mini_map_pressed() -> void:
	globals.play_sample("click5")
	if get_owner().spell:
		if get_owner().spell.get_sub_type() == "CHOOSE_AREA_EFFECT":
			get_owner().spell.unmake()
	if $c/mini_map.is_visible():
		$c/mini_map.hide()
	else:
		$c/mini_map.show()

func _on_pause_pressed(slot_select: bool=false) -> void:
	$c/game_menu.show()
	if not slot_select:
		globals.play_sample("click5")
		menu.show()

func _on_hud_slot_pressed(slot: Slot, itm: Pickable) -> void:
	selected = itm
	if spell_book.has_item(itm):
		selected_index = spell_book.get_item_slot(itm, true)
	elif inventory_bag.has_item(itm):
		selected_index = inventory_bag.get_item_slot(itm, true)
	if itm.get_filename().get_file().get_basename() == "item":
		if not get_owner().dead and not slot.is_cooling_down \
		and (itm.get_type() == "FOOD" or itm.get_type() == "POTION"):
			_on_use_pressed(true)
		elif get_owner().weapon == itm or get_owner().vest == itm:
			item_info.get_node(@"s/h/v/back").disconnect("pressed",self, "_on_back_pressed")
			item_info.get_node(@"s/h/v/back").connect("pressed", self, "hide_menu")
			item_info_go(itm)
			item_info_hide_except(["unequip"])
			menu.hide()
			$c/game_menu.show()
		else:
			prep_item_info()
			globals.play_sample(snd_configure(true))
			_on_bag_index_selected(selected_index, true)
			itm.describe()
			item_info.show()
	elif slot.is_cooling_down or get_owner().dead:
		prep_item_info()
		globals.play_sample("turn_page")
		_on_spell_selected(selected_index, true)
	else:
		_on_cast_pressed()
	selected_index = -1