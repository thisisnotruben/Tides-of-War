extends "res://src/menu_ui/in_game_menu.gd"


func _on_merchant_draw() -> void:
	if get_owner().target:
		if not (get_owner().weapon and get_owner().vest) \
		or get_owner().target.get_type() == "TRAINER":
			merchant.get_node(@"s/v2/repair").hide()
			return
		if get_owner().weapon:
			if get_owner().weapon.durability < 1.0:
				merchant.get_node(@"s/v2/repair").show()
			else:
				merchant.get_node(@"s/v2/repair").hide()
		if get_owner().vest:
			if get_owner().vest.durability < 1.0:
				merchant.get_node(@"s/v2/repair").show()
			elif not merchant.get_node(@"s/v2/repair").is_visible() or !get_owner().weapon:
				merchant.get_node(@"s/v2/repair").hide()

func _on_merchant_item_selected(index: int, sifting: bool=false) -> void:
	bag = merchant_bag
	merchant.hide()
	selected = merchant_bag.get_item_metadata(index)
	if selected.get_filename().get_file().get_basename() == "spell":
		var trained: bool = false
		for spell in spell_book.get_items():
			if spell.get_type(true) == selected.get_type(true):
				trained = true
				break
		if not trained:
			item_info.get_node(@"s/h/v/buy/label").set_text("Train")
			item_info_hide_except(["buy"])
	else:
		if not sifting:
			globals.play_sample(snd_configure(true))
		if merchant.get_node(@"s/v/label").get_text() == "Inventory":
			item_info_hide_except(["sell"])
		else:
			item_info_hide_except(["buy"])
	if not sifting:
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

func _on_inventory_pressed() -> void:
	globals.play_sample("click1")
	if merchant.is_visible():
		merchant_bag.clear()
		merchant.get_node(@"s/v/label").set_text("Inventory")
		merchant.get_node(@"s/v2/inventory").hide()
		merchant.get_node(@"s/v2/merchant").show()
		for item in inventory_bag.get_items(true):
			item.setup_shop()

func _on_merchant_pressed() -> void:
	globals.play_sample("click1")
	merchant_bag.clear()
	merchant.get_node(@"s/v/label").set_text(get_owner().target.world_name)
	merchant.get_node(@"s/v2/merchant").hide()
	merchant.get_node(@"s/v2/inventory").show()
	for item in get_owner().target.get_node(@"inventory").get_children():
		item.setup_shop(false)

func _on_repair_pressed() -> void:
	globals.play_sample("click1")
	popup.get_node(@"m/repair").show()
	var text: String = ""
	if not get_owner().weapon:
		popup.get_node(@"m/repair/repair_weapon").hide()
		popup.get_node(@"m/repair/repair_all").hide()
	else:
		popup.get_node(@"m/repair/repair_weapon").show()

		text = "Weapon: %s" % stats.item_repair_cost(get_owner().weapon.get_level())
	if not get_owner().vest:
		popup.get_node(@"m/repair/repair_armor").hide()
		popup.get_node(@"m/repair/repair_all").hide()
	else:
		popup.get_node(@"m/repair/repair_armor").show()
		if not get_owner().weapon:
			text += "Armor: %s"
		else:
			text += "\nArmor: %s"
		text = text % stats.item_repair_cost(get_owner().vest.get_level())
	if get_owner().weapon and get_owner().vest:
		text += "\nAll %s" % stats.item_repair_cost(get_owner().weapon.get_level()) \
		+ stats.item_repair_cost(get_owner().vest.get_level())
	popup.get_node(@"m/repair/label").set_text(text)
	popup.show()

func _on_back_pressed() -> void:
	globals.play_sample("click3")
	if get_owner().target:
		if get_owner().target.get_type() == "TRAINER":
			item_info.get_node(@"s/h/v/buy/label").set_text("Buy")
			popup.get_node(@"m/yes_no/label").set_text("Buy?")
			sound_played = globals.play_sample("spell_book_close")
		else:
			sound_played = globals.play_sample("merchant_close")
	item_info.get_node(@"s/v/c/v/bg").set_disabled(false)
	merchant.get_node(@"s/v/label").set_text("")
	merchant.get_node(@"s/v2/merchant").hide()
	merchant.get_node(@"s/v2/repair").hide()
	merchant.get_node(@"s/v2/inventory").show()
	merchant.hide()
	merchant_bag.clear()
	get_owner().set_target(null)
	hide_menu()