extends "res://src/menu_ui/in_game_menu.gd"


func _on_bg_pressed() -> void:
	globals.play_sample("click2")
	popup.get_node(@"m/add_to_slot/clear_slot").hide()
	var count: int = 1
	for button in get_tree().get_nodes_in_group("HUD-shortcut"):
		if button.get_node(@"tween").is_active():
			button.get_node(@"tween").set_active(false)
			button.get_node(@"m/icon/overlay").set_scale(Vector2(1.0, 1.0))
		button.get_node(@"m/label").set_text(str(count))
		button.get_node(@"m/icon/overlay").set_frame_color(Color(1.0, 1.0, 0.0, 0.75))
		button.get_node(@"m/label").show()
		if button.get_item():
			if button.get_item().world_name == selected.world_name:
				popup.get_node(@"m/add_to_slot/clear_slot").show()
		count += 1
	$c/controls/m/right.hide()
	$c/controls.show()
	popup.get_node(@"m/add_to_slot").show()
	popup.show()

func _on_cast_pressed() -> void:
	var show_popup: bool = false
	if get_owner().mana >= selected.mana_cost:
		if get_owner().target:
			if selected.requires_target and not get_owner().target.enemy:
				popup.get_node(@"m/error/label").set_text("Invalid\nTarget!")
				popup.get_node(@"m/error").show()
				show_popup = true
			elif get_owner().unit_center_pos.distance_to(get_owner().target.get_center_pos()) > selected.spell_range \
			and selected.spell_range > 0 and selected.requires_target:
				popup.get_node(@"m/error/label").set_text("Target Not\nIn Range!")
				popup.get_node(@"m/error").show()
				show_popup = true
		elif not get_owner().target and selected.requires_target:
			popup.get_node(@"m/error/label").set_text("Target\nRequired!")
			popup.get_node(@"m/error").show()
			show_popup = true
	else:
		popup.get_node(@"m/error/label").set_text("Not Enough\nMana!")
		popup.get_node(@"m/error").show()
		show_popup = true
	if show_popup:
		if not get_tree().is_paused():
			$c/game_menu.show()
			selected = null
			selected_index = -1
		popup.show()
		return
	globals.play_sample("click2")
	var spell = globals.spell.instance()
	spell.get_obj(get_owner(), false)
	spell.set_type(selected.get_type(true))
	spell.configure_spell()
	get_owner().spell = spell
	spell_book.set_slot_cool_down(selected_index, spell.cooldown, 0.0)
	item_info.hide()
	hide_menu()

func _on_use_pressed(slot_select: bool=false) -> void:
	match selected.get_type():
		"FOOD":
			if get_owner().get_state(true) == "ATTACKING":
				popup.get_node(@"m/error/label").set_text("Cannot Eat\nIn Combat!")
				popup.get_node(@"m/error").show()
				if not get_tree().is_paused():
					$c/game_menu.show()
					selected_index = -1
					selected = null
				popup.show()
				return
			else:
				globals.play_sample("eat")
		"POTION":
			globals.play_sample("drink")
		_:
			globals.play_sample("click2")
	var meta: Item = inventory_bag.get_item_metadata(selected_index)
	if meta and selected.get_type() == "POTION":
		inventory_bag.set_slot_cool_down(selected_index, meta.duration, 0.0)
	inventory_bag.remove_item(selected_index)
	selected.consume(get_owner(), 0.0)
	selected_index = -1
	selected = null
	if item_info.get_node(@"s/h/v/back").is_connected("pressed", self, "hide_menu"):
		hide_menu()
	elif not slot_select:
		item_info.hide()
		inventory.show()

func _on_buy_pressed() -> void:
	globals.play_sample("click2")
	item_info.hide()
	if get_owner().level < selected.level and selected.get_filename().get_file().get_basename() == "spell":
		popup.get_node(@"m/error/label").set_text("Can't Learn\nThis Yet!")
		popup.get_node(@"m/error").show()
	elif selected.gold <= get_owner().gold:
		if selected.get_filename().get_file().get_basename() == "item":
			popup.get_node(@"m/yes_no/label").set_text("Buy?")
		else:
			popup.get_node(@"m/yes_no/label").set_text("Learn?")
		popup.get_node(@"m/yes_no").show()
	else:
		popup.get_node(@"m/error/label").set_text("Not Enough\nGold!")
		popup.get_node(@"m/error").show()
	popup.show()

func _on_sell_pressed() -> void:
	globals.play_sample("click2")
	item_info.hide()
	popup.get_node(@"m/yes_no/label").set_text("Sell?")
	popup.get_node(@"m/yes_no").show()
	popup.show()

func _on_equip_pressed() -> void:
	item_info.hide()
	if inventory_bag.get_item_count() < inventory_bag.ITEM_MAX:
		match selected.get_type():
			"WEAPON":
				var weapon: Item = get_owner().weapon
				if weapon:
					weapon.unequip()
			"ARMOR":
				var vest: Item = get_owner().vest
				if vest:
					vest.unequip()
	elif (selected.get_type() == "WEAPON" and get_owner().weapon) \
	or (selected.get_type() == "ARMOR" and get_owner().vest):
		popup.get_node(@"m/error/label").set_text("Inventory\nFull!")
		popup.get_node(@"m/error").show()
		popup.show()
		return
	var slot: Slot = inventory_bag.get_item_slot(selected)
	slot.set_block_signals(true)
	selected.equip()
	slot.set_block_signals(false)
	if selected.has_meta("loaded"):
		selected.set_meta("loaded", null)
	else:
		globals.play_sample(snd_configure(true))
	var tex: Texture = load("res://asset/img/ui/black_bg_icon_used0.res")
	var path: NodePath = NodePath("s/v/h/%s_slot" % selected.get_type().to_lower())
	inventory.get_node(path).set_normal_texture(tex)
	stats_menu.get_node(path).set_normal_texture(tex)
	selected_index = -1
	selected = null
	if item_info.get_node(@"s/h/left").is_visible():
		inventory.show()
	else:
		hide_menu()

func _on_unequip_pressed() -> void:
	if inventory_bag.get_item_count() == inventory_bag.ITEM_MAX:
		popup.get_node(@"m/error").show()
	else:
		item_info.get_node(@"s/h/left").show()
		item_info.get_node(@"s/h/right").show()
		globals.play_sample("click2")
		item_info.hide()
		popup.get_node(@"m/yes_no/label").set_text("Unequip?")
		popup.get_node(@"m/yes_no").show()
	popup.show()

func _on_drop_pressed() -> void:
	globals.play_sample("click2")
	item_info.hide()
	popup.get_node(@"m/yes_no/label").set_text("Drop?")
	popup.get_node(@"m/yes_no").show()
	popup.show()

func _on_back_pressed() -> void:
	globals.play_sample("click3")
	item_info.hide()
	if selected in spell_book.get_items():
		spell_menu.show()
	else:
		item_info.get_node(@"s/h/left").show()
		item_info.get_node(@"s/h/right").show()
		var sound_name: String = "click3"
		if selected.is_class("Area2D"):
			sound_name = snd_configure()
		if not get_owner().get_node(@"inventory").get_children().has(selected) \
		or merchant.get_node(@"s/v/label").get_text() == "Inventory":
			sound_name = sound_name.replace("on", "off")
			merchant.show()
		elif typeof(selected_index) != TYPE_INT and selected_index:
			stats_menu.show()
		else:
			inventory.show()
		sound_played = globals.play_sample(sound_name)
	selected_index = -1
	selected = null

func _on_item_info_label_draw() -> void:
	var label_node: Label = item_info.get_node(@"s/v/c/v/c/label")
	label_node.set_custom_minimum_size(label_node.get_parent().rect_size)