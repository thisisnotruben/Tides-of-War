extends "res://src/menu_ui/in_game_menu.gd"


func _on_resume_pressed() -> void:
	globals.play_sample("click2")
	get_owner().set_buff()
	hide_menu()

func _on_inventory_pressed() -> void:
	menu.hide()
	inventory.show()

func _on_stats_pressed() -> void:
	globals.play_sample("click1")
	var bbcode: String = """Name: %s
Health: %s / %s
Mana: %s / %s
XP: %s / %s
Level: %s\nGold: %s
Strength: %s
Intellect: %s
Agility: %s
Armor: %s
Damage: %s - %s
Attack speed: %s
Attack range: %s""" % \
	[get_owner().world_name, get_owner().hp, get_owner().hp_max, get_owner().mana, get_owner().mana_max, globals.add_comma(get_owner().xp), \
	globals.add_comma(get_owner().level * stats.XP_INTERVAL), get_owner().level, globals.add_comma(get_owner().gold), \
	get_owner().stamina, get_owner().intellect, get_owner().agility, get_owner().armor, \
	get_owner().min_damage, get_owner().max_damage, get_owner().weapon_speed, get_owner().weapon_range]
	stats_menu.get_node(@"s/v/c/label").set_bbcode(bbcode)
	menu.hide()
	stats_menu.show()

func _on_quest_log_pressed() -> void:
	globals.play_sample("click1")
	menu.hide()
	quest_log.show()

func _on_about_pressed() -> void:
	globals.play_sample("click1")
	menu.hide()
	list_of_menus.get_node(@"about").show()

func _on_save_load_pressed() -> void:
	globals.play_sample("click1")
	menu.hide()
	save_load.show()

func _on_exit_pressed() -> void:
	globals.play_sample("click1")
	menu.hide()
	popup.get_node(@"m/exit").show()
	popup.show()