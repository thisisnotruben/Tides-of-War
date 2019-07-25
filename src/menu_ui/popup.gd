"""
UI controller for popup that is instanced by start_menu/igm.
"""
extends CenterContainer
class_name PopUp

onready var menu = get_owner()

func _ready():
	randomize()

func _on_delete_pressed():
	globals.play_sample("click1")
	$m/save_load.hide()
	$m/yes_no/label.set_text("Delete?")
	$m/yes_no.show()
	show()

func _on_popup_hide():
	if menu.get_name() == "in_game_menu":
		menu.get_node(@"c/game_menu/bg").set_frame_color(Color(0.43, 0.43, 0.43, 1.0))
	else:
		globals.get_node(@"progress_bar").show()
	menu.list_of_menus.get_parent().show()
	for node in $m.get_children():
		node.hide()

func _on_popup_draw():
	if menu.get_name() == "in_game_menu":
		menu.get_node(@"c/game_menu/bg").set_frame_color(Color(0.0, 0.0, 0.0, 0.25))
		menu.list_of_menus.get_parent().hide()
	else:
		globals.get_node(@"progress_bar").hide()

func _on_error_draw():
	globals.play_sample("click6")

func _on_m_resized():
	$bg.set_custom_minimum_size($m.get_size())

func _on_all_pressed():
	globals.play_sample("click1")
	for quest_slot in menu.quest_log.get_node(@"s/v/s/v").get_children():
		quest_slot.show()
	hide()
	menu.quest_log.show()

func _on_active_pressed():
	globals.play_sample("click1")
	for quest_slot in menu.quest_log.get_node(@"s/v/s/v").get_children():
		if quest_slot.quest.get_state() != "active":
			quest_slot.hide()
		else:
			quest_slot.show()
	hide()
	menu.quest_log.show()

func _on_completed_pressed():
	globals.play_sample("click1")
	for quest_slot in menu.quest_log.get_node(@"s/v/s/v").get_children():
		if quest_slot.quest.get_state() != "delivered":
			quest_slot.hide()
		else:
			quest_slot.show()
	hide()
	menu.quest_log.show()

func _on_back_pressed():
	var sound_played: bool = false
	if menu.get_name() == "start_menu":
		menu.get_node(@"list_of_menus").show()
		menu.load_menu.show()
	elif $m/exit.is_visible():
		menu.menu.show()
	elif $m/filter_options.is_visible():
		menu.quest_log.show()
	elif $m/add_to_slot.is_visible():
		menu.item_info.show()
		menu.get_node(@"c/controls/m/right").show()
		if menu.item_info.get_node(@"s/h/v/back"). \
		is_connected("pressed", menu, "hide_menu"):
			sound_played = true
		elif $m/add_to_slot/clear_slot.is_visible():
			sound_played = globals.play_sample("click1")
		for button in get_tree().get_nodes_in_group("HUD-shortcut"):
			button.get_node(@"tween").set_active(true)
			button.get_node(@"tween").resume_all()
			button.get_node(@"m/icon/overlay").set_frame_color(Color(0.0, 0.0, 0.0, 0.75))
			button.get_node(@"m/label").hide()
	elif not $m/repair.is_visible():
		menu.save_load.show()
	if not sound_played:
		globals.play_sample("click3")
	hide()

func _on_exit_game_pressed():
	get_tree().quit()

func _on_exit_menu_pressed():
	globals.play_sample("click0")
	get_tree().set_pause(false)
	globals.set_scene("res://src/menu_ui/start_menu.tscn")
	world_quests.reset()

func _on_okay_pressed():
	globals.play_sample("click1")
	if globals.player.target:
		if globals.player.target.get("type") == "MERCHANT" and not menu.selected \
		and $m/error/label.get_text() == "Not Enough\nGold!":
			$m/error.hide()
			$m/repair.show()
			return
	hide()
	if menu.dialogue.is_visible_in_tree():
		menu.dialogue.show()
	elif not menu.selected:
		menu.hide_menu()
	else:
		menu.item_info.show()
		menu.list_of_menus.show()

func _on_yes_pressed():
	if menu.get_name() == "start_menu":
		globals.save_meta(null, menu.selected_index)
		menu.load_menu.get_node("v/s/c/g/slot_label_%s" % menu.selected_index).set_text("Slot %s" % (menu.selected_index + 1))
		Directory.new().remove(globals.SAVE_PATHS["SAVE_SLOT_%s" % menu.selected_index])
		_on_no_pressed()
	else:
		var snd_played: bool = false
		hide()
		match $m/yes_no/label.get_text():
			"Drop?":
				snd_played = globals.play_sample("inventory_drop")
				menu.selected.drop()
				if menu.item_info.get_node(@"s/h/left").is_visible():
					menu.inventory.show()
				else:
					menu.hide_menu()
			"Unequip?":
				menu.selected.unequip()
				snd_played = globals.play_sample("inventory_unequip")
				var tex: Resource = load("res://asset/img/ui/black_bg_icon.res")
				var path: NodePath = NodePath("s/v/h/%s_slot" % menu.selected.get_type().to_lower())
				menu.inventory.get_node(path).set_normal_texture(tex)
				menu.stats_menu.get_node(path).set_normal_texture(tex)
				if menu.item_info.get_node(@"s/h/v/back").is_connected("pressed", menu, "hide_menu"):
					menu.hide_menu()
				else:
					menu.inventory.show()
			"Buy?", "Learn?":
				if $m/yes_no/label.get_text() == "Learn?":
					globals.play_sample("learn_spell")
				snd_played = globals.play_sample("sell_buy")
				menu.selected.buy(globals.player)
				menu.merchant.get_node(@"s/v/label2").set_text("Gold: %s" % globals.add_comma(globals.player.gold))
				menu.merchant.show()
			"Delete?":
				globals.save_meta(null, menu.selected_index)
				menu.selected.set_text("Slot %s" % (menu.selected_index + 1))
				Directory.new().remove(globals.SAVE_PATHS["SAVE_SLOT_%s" % menu.selected_index])
				menu.save_load.show()
			"Sell?":
				snd_played = globals.play_sample("sell_buy")
				menu.merchant_bag.remove_item(menu.selected_index)
				menu.inventory_bag.remove_item(menu.selected_index)
				menu.selected.sell(globals.player)
				menu.merchant.get_node(@"s/v/label2").set_text("Gold: %s" % globals.add_comma(globals.player.gold))
				menu.merchant.show()
			"Overwrite?":
				save_game()
				menu.save_load.show()
		if not snd_played:
			globals.play_sample("click1")
		menu.selected_index = -1
		menu.selected = null

func _on_no_pressed():
	globals.play_sample("click3")
	hide()
	if menu.get_name() == "start_menu":
		menu.get_node(@"list_of_menus").show()
		menu.load_menu.show()
	else:
		match $m/yes_no/label.get_text():
			"Delete?":
				menu.selected_index = -1
				menu.selected = null
				menu.save_load.show()
			"Overwrite?":
				menu.save_load.show()
			_:
				menu.item_info.show()

func _on_save_pressed():
	globals.play_sample("click1")
	if "Slot" in menu.selected.get_text():
		hide()
		save_game()
		menu.selected = null
		menu.selected_index = -1
		menu.save_load.show()
	else:
		$m/yes_no/label.set_text("Overwrite?")
		$m/save_load.hide()
		$m/yes_no.show()

func _on_repair_pressed(what):
	var meta: Dictionary = {"amount":0,"vest":null, "weapon":null, "player":globals.player}
	if what == "all":
		meta.weapon = meta.player.weapon
		meta.vest = meta.player.vest
		meta.amount = Stats.item_repair_cost(meta.weapon.level) + Stats.item_repair_cost(meta.vest.level)
	else:
		meta[what] = meta.player.get(what)
		meta.amount = Stats.item_repair_cost(meta[what].level)
	if meta.amount > meta.player.gold:
		$m/error/label.set_text("Not Enough\nGold!")
		$m/repair.hide()
		$m/error.show()
	else:
		globals.play_sample("sell_buy")
		globals.play_sample("anvil")
		meta.player.gold -= int(round(meta.amount))
		for bag_slot in meta:
			if typeof(meta[bag_slot]) == TYPE_OBJECT and bag_slot != "player":
				meta[bag_slot].take_damage(true, 1.0)
		hide()
		menu.merchant.get_node(@"s/v/label2").set_text("Gold: %s" % globals.add_comma(meta.player.gold))
		menu.merchant.show()

func _on_load_pressed():
	globals.play_sample("click0")
	globals.load_game(globals.SAVE_PATHS["SAVE_SLOT_%s" % menu.selected_index])
	if menu.get_name() == "in_game_menu":
		menu.get_node(@"c/game_menu").hide()

func _on_slot_pressed(index):
	var amnttt: int = -1
	var selected_name: String = ""
	var bttn_f
	var bttn_t
	hide()
	globals.play_sample("click1")
	menu.get_node(@"c/controls/m/right").show()
	if menu.selected:
		selected_name = menu.selected.world_name
	elif globals.player.spell:
		selected_name = globals.player.spell.world_name
	for button in get_tree().get_nodes_in_group("HUD-shortcut"):
		button.get_node(@"m/icon/overlay").set_frame_color(Color(0.0, 0.0, 0.0, 0.75))
		button.get_node(@"m/label").hide()
		button.get_node(@"tween").set_active(true)
		button.get_node(@"tween").resume_all()
		if button.get_item():
			if button.get_item().world_name == selected_name:
				var button_stack = button.get_item(true)
				if typeof(button_stack) == TYPE_ARRAY:
					amnttt = button_stack.size()
				button.set_item(null, false, true)
		if button.get_name() == str(index):
			bttn_t = button
			if button.get_item():
				button.set_item(null, false, true)
			var weapon: Item = globals.player.weapon
			var vest: Item = globals.player.vest
			if weapon == menu.selected:
				button.set_item(weapon, false)
			elif vest == menu.selected:
				button.set_item(vest, false)
			else:
				for item_list in [menu.inventory_bag, menu.spell_book]:
					if item_list.has_item(menu.selected):
						var bag_slot: Slot = item_list.get_item_slot(menu.selected)
						var item = bag_slot.get_item(true)
						bttn_f = bag_slot
						if typeof(item) == TYPE_ARRAY:
							if amnttt == -1:
								amnttt = item.size()
							for stacked_itm in amnttt:
								button.set_item(item[stacked_itm], false)
						else:
							button.set_item(item, false)
						break
	if bttn_f and bttn_t:
		for link in bttn_f.get_signal_connection_list("sync_slot"):
			bttn_f.disconnect("sync_slot", link.target, "_on_sync_shortcut")
		bttn_f.connect("sync_slot", bttn_t, "_on_sync_shortcut")
		bttn_t.cool_down(bttn_f.get_item(), bttn_f.time, bttn_f.get_node(@"tween").tell())

func _on_clear_slot_pressed():
	for button in get_tree().get_nodes_in_group("HUD-shortcut"):
		if button.get_item():
			if button.get_item().world_name == menu.selected.world_name:
				button.set_item(null, false, true)
	if get_tree().is_paused():
		_on_back_pressed()
	if menu.item_info.get_node(@"s/h/v/back"). \
	is_connected("pressed", menu, "hide_menu"):
		menu.hide_menu()

func _on_repair_draw():
	var shown: int = 0
	for node in $m/repair.get_children():
		if node.is_visible():
			shown += 1
	if shown > 4:
		$bg.set_texture(load("res://asset/img/ui/grey2_bg.res"))

func _on_repair_hide():
	$bg.set_texture(load("res://asset/img/ui/grey3_bg.res"))

func save_load_go(index):
	if menu.get_name() == "start_menu":
		if not menu.load_menu.get_node("v/s/c/g/slot_label_%s" % index).get_text() == "Slot %s" % (index + 1):
			globals.play_sample("click2")
			menu.get_node(@"list_of_menus").hide()
			$m/save_load/save.hide()
		else:
			return
	else:
		globals.play_sample("click2")
		menu.save_load.hide()
		$m/save_load/save.show()
		menu.selected = menu.save_load.get_node("v/s/c/g/slot_label_%s" % index)
		if menu.selected.get_text() == "Slot %s" % (index + 1):
			get_node(@"m/save_load/load").hide()
			$m/save_load/delete.hide()
		else:
			$m/save_load/delete.show()
			get_node(@"m/save_load/load").show()
	menu.selected_index = index
	$m/save_load.show()
	show()

func save_game():
	var date: Dictionary = OS.get_datetime()
	var time: String = "%s-%s %s:%s" % [date.month, date.day, date.hour, date.minute]
	menu.selected.set_text(time)
	globals.save_meta(time, menu.selected_index)
	globals.save_game(globals.SAVE_PATHS["SAVE_SLOT_%s" % menu.selected_index])
	menu.selected.set_text(time)
	menu.save_load.set_labels()