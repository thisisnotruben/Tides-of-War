extends Node
class_name Igm

onready var list_of_menus = get_node(@"c/game_menu/list_of_menus/m")
onready var menu = list_of_menus.get_node(@"main_menu")
onready var inventory = list_of_menus.get_node(@"inventory")
onready var merchant = list_of_menus.get_node(@"merchant")
onready var stats_menu = list_of_menus.get_node(@"stats")
onready var quest_log = list_of_menus.get_node(@"quest_log")
onready var save_load = list_of_menus.get_node(@"save_load")
onready var item_info = list_of_menus.get_node(@"item_info")
onready var dialogue = list_of_menus.get_node(@"dialogue")
onready var spell_menu = list_of_menus.get_node(@"spell_book")
onready var inventory_bag = inventory.get_node(@"s/v/c/item_list")
onready var merchant_bag = merchant.get_node(@"s/v/c/merchant_list")
onready var spell_book = spell_menu.get_node(@"s/v/c/spell_list")
onready var popup = get_node(@"c/game_menu/popup")
onready var hp_mana = get_node(@"c/hp_mana")

var selected = null
var selected_index: int = -1
var player: Character

func _ready() -> void:
	player = get_owner()
	for item_list in [inventory_bag, spell_book]:
		for slot in item_list.get_children():
			for hud_slot in hp_mana.get_node(@"m/h/p/h/g").get_children():
				slot.connect("cooldown", hud_slot, "cool_down")
				hud_slot.connect("cooldown", slot, "cool_down")
			for short_cut in get_tree().get_nodes_in_group("HUD-shortcut"):
				slot.connect("cooldown", short_cut, "cool_down")
				short_cut.connect("cooldown", slot, "cool_down")
	for scroller in [item_info.get_node(@"s/v/c/v/c/label"), quest_log.get_node(@"s/v/s")]:
		for node in scroller.get_children():
			if node.is_class("ScrollBar"):
				node.set_modulate(Color(1.0, 1.0, 1.0, 0.0))

func _on_resume_pressed() -> void:
	globals.play_sample("click2")
	player.set_buff()
	hide_menu()

func _on_inventory_pressed() -> void:
	globals.play_sample("click1")
	if merchant.is_visible():
		merchant_bag.clear()
		merchant.get_node(@"s/v/label").set_text("Inventory")
		merchant.get_node(@"s/v2/inventory").hide()
		merchant.get_node(@"s/v2/merchant").show()
		for item in inventory_bag.get_items(true):
			item.setup_shop()
	else:
		menu.hide()
		inventory.show()

func _on_merchant_pressed() -> void:
	globals.play_sample("click1")
	merchant_bag.clear()
	merchant.get_node(@"s/v/label").set_text(player.target.world_name)
	merchant.get_node(@"s/v2/merchant").hide()
	merchant.get_node(@"s/v2/inventory").show()
	for item in player.target.get_node(@"inventory").get_children():
		item.setup_shop(false)

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
	[player.world_name, player.hp, player.hp_max, player.mana, player.mana_max, globals.add_comma(player.xp), \
	globals.add_comma(player.level * Stats.XP_INTERVAL), player.level, globals.add_comma(player.gold), \
	player.stamina, player.intellect, player.agility, player.armor, \
	player.min_damage, player.max_damage, player.weapon_speed, player.weapon_range]
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

func _on_pause_pressed(slot_select: bool=false) -> void:
	$c/game_menu.show()
	if not slot_select:
		globals.play_sample("click5")
		menu.show()

func _on_spell_book_pressed() -> void:
	globals.play_sample("turn_page")
	spell_menu.get_node(@"s/v/m/v/label"). \
	set_text("Health: %s / %s" % [player.hp, player.hp_max])
	spell_menu.get_node(@"s/v/m/v/label2"). \
	set_text("Mana: %s / %s" % [player.mana, player.mana_max])
	menu.hide()
	$c/game_menu.show()
	spell_menu.show()

func _on_mini_map_pressed() -> void:
	globals.play_sample("click5")
	if player.spell:
		if player.spell.get_sub_type() == "CHOOSE_AREA_EFFECT":
			player.spell.unmake()
	if $c/mini_map.is_visible():
		$c/mini_map.hide()
	else:
		$c/mini_map.show()

func _on_unit_hud_pressed() -> void:
	if player.target:
		globals.play_sample("click5")
		player.set_target(null)

func _on_back_pressed() -> void:
	var sound_played: bool = false
	if inventory.is_visible():
		inventory.hide()
		menu.show()
	elif stats_menu.is_visible():
		stats_menu.hide()
		menu.show()
	elif quest_log.is_visible():
		for quest_slot in quest_log.get_node(@"s/v/s/v").get_children():
			quest_slot.show()
		quest_log.hide()
		menu.show()
	elif save_load.is_visible():
		save_load.hide()
		menu.show()
	elif spell_menu.is_visible():
		sound_played = globals.play_sample("spell_book_close")
		spell_menu.hide()
		hide_menu()
	elif item_info.is_visible():
		item_info.hide()
		if selected in spell_book.get_items():
			spell_menu.show()
		else:
			item_info.get_node(@"s/h/left").show()
			item_info.get_node(@"s/h/right").show()
			var sound_name: String = "click3"
			if selected.is_class("Area2D"):
				sound_name = snd_configure()
			if not player.get_node(@"inventory").get_children().has(selected) \
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
	elif dialogue.is_visible():
		dialogue.hide()
		if selected == quest_log:
			quest_log.show()
			selected = null
		else:
			dialogue.get_node(@"s/s/v/accept").hide()
			dialogue.get_node(@"s/s/v/finish").hide()
			hp_mana.get_node(@"m/h/u").hide()
			player.set_target(null)
			hide_menu()
	elif merchant.is_visible():
		if player.target:
			if player.target.get_type() == "TRAINER":
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
		player.set_target(null)
		hide_menu()
	if not sound_played:
		globals.play_sample("click3")

func _on_spell_selected(index: int, sifting: bool) -> void:
	if not sifting:
		globals.play_sample("spell_select")
	selected = spell_book.get_item_metadata(index)
	selected_index = index
	if spell_book.is_cooling_down(index) or player.dead:
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

func _on_bag_index_selected(index: int, sifting: bool=false) -> void:
	item_info_hide_except()
	selected_index = index
	var bag: Bag = inventory_bag
	if merchant_bag.get_item_count() == 0:
		if not sifting:
			globals.play_sample("inventory_open")
		inventory.hide()
		selected = inventory_bag.get_item_metadata(index)
		match selected.get_type():
			"WEAPON", "ARMOR":
				if not player.dead:
					item_info.get_node(@"s/h/v/equip").show()
			"FOOD", "POTION":
				item_info.get_node(@"s/h/v/use/label"). \
				set_text("%s" % "Eat" if selected.get_type() == "FOOD" else "Drink")
				if not inventory_bag.is_cooling_down(index) and not player.dead:
					item_info.get_node(@"s/h/v/use").show()
		if not player.dead:
			item_info.get_node(@"s/h/v/drop").show()
	else:
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

func _on_weapon_slot_pressed() -> void:
	item_info_go(player.weapon)

func _on_armor_slot_pressed() -> void:
	item_info_go(player.vest)

func _on_equip_pressed() -> void:
	item_info.hide()
	if inventory_bag.get_item_count() < inventory_bag.ITEM_MAX:
		match selected.get_type():
			"WEAPON":
				var weapon: Item = player.weapon
				if weapon:
					weapon.unequip()
			"ARMOR":
				var vest: Item = player.vest
				if vest:
					vest.unequip()
	elif (selected.get_type() == "WEAPON" and player.weapon) \
	or (selected.get_type() == "ARMOR" and player.vest):
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

func _on_use_pressed(slot_select: bool=false) -> void:
	match selected.get_type():
		"FOOD":
			if player.get_state(true) == "ATTACKING":
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
	selected.consume(player, 0.0)
	selected_index = -1
	selected = null
	if item_info.get_node(@"s/h/v/back").is_connected("pressed", self, "hide_menu"):
		hide_menu()
	elif not slot_select:
		item_info.hide()
		inventory.show()

func _on_accept_pressed() -> void:
	globals.play_sample("quest_accept")
	world_quests.start_focused_quest()
	var qe = globals.quest_entry.instance()
	qe.add_to_quest_log(quest_log)
	qe.set_quest(world_quests.focused_quest)
	dialogue.get_node(@"s/s/v/accept").hide()
	dialogue.get_node(@"s/s/v/finish").hide()
	dialogue.hide()
	player.set_target(null)
	hide_menu()

func _on_finish_pressed() -> void:
	var quest: Quest = world_quests.focused_quest
	if quest.get_gold() > 0:
		globals.play_sample("sell_buy")
		player.set_gold(quest.get_gold())
		var text: CombatText = globals.combat_text.instance()
		text.type = "gold"
		text.set_text("+%s" % globals.add_comma(quest.get_gold()))
		player.add_child(text)
	var reward = quest.get_reward()
	if reward:
		globals.current_scene.get_node(@"zed/z1").add_child(reward)
		var pos: Vector2 = globals.current_scene. \
		get_grid_position(player.get_global_position())
		reward.set_global_position(pos)
	world_quests.finish_focused_quest()
	if world_quests.focused_quest:
		dialogue.get_node(@"s/s/label2").set_text(world_quests.focused_quest.quest_start)
		dialogue.get_node(@"s/s/v/finish").hide()
		dialogue.get_node(@"s/s/v/accept").show()
	else:
		_on_back_pressed()

func _on_buy_pressed() -> void:
	globals.play_sample("click2")
	item_info.hide()
	if player.level < selected.level and selected.get_filename().get_file().get_basename() == "spell":
		popup.get_node(@"m/error/label").set_text("Can't Learn\nThis Yet!")
		popup.get_node(@"m/error").show()
	elif selected.gold <= player.gold:
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

func _on_repair_pressed() -> void:
	globals.play_sample("click1")
	popup.get_node(@"m/repair").show()
	var text: String = ""
	if not player.weapon:
		popup.get_node(@"m/repair/repair_weapon").hide()
		popup.get_node(@"m/repair/repair_all").hide()
	else:
		popup.get_node(@"m/repair/repair_weapon").show()

		text = "Weapon: %s" % Stats.item_repair_cost(player.weapon.get_level())
	if not player.vest:
		popup.get_node(@"m/repair/repair_armor").hide()
		popup.get_node(@"m/repair/repair_all").hide()
	else:
		popup.get_node(@"m/repair/repair_armor").show()
		if not player.weapon:
			text += "Armor: %s"
		else:
			text += "\nArmor: %s"
		text = text % Stats.item_repair_cost(player.vest.get_level())
	if player.weapon and player.vest:
		text += "\nAll %s" % Stats.item_repair_cost(player.weapon.get_level()) \
		+ Stats.item_repair_cost(player.vest.get_level())
	popup.get_node(@"m/repair/label").set_text(text)
	popup.show()

func _on_cast_pressed() -> void:
	var show_popup: bool = false
	if player.mana >= selected.mana_cost:
		if player.target:
			if selected.requires_target and not player.target.enemy:
				popup.get_node(@"m/error/label").set_text("Invalid\nTarget!")
				popup.get_node(@"m/error").show()
				show_popup = true
			elif player.unit_center_pos.distance_to(player.target.get_center_pos()) > selected.spell_range \
			and selected.spell_range > 0 and selected.requires_target:
				popup.get_node(@"m/error/label").set_text("Target Not\nIn Range!")
				popup.get_node(@"m/error").show()
				show_popup = true
		elif not player.target and selected.requires_target:
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
	spell.get_obj(player, false)
	spell.set_type(selected.get_type(true))
	spell.configure_spell()
	player.spell = spell
	spell_book.set_slot_cool_down(selected_index, spell.cooldown, 0.0)
	item_info.hide()
	hide_menu()

func _on_filter_pressed() -> void:
	globals.play_sample("click2")
	if quest_log.is_visible():
		quest_log.hide()
		popup.get_node(@"m/filter_options").show()
	else:
		spell_menu.hide()
	popup.show()

func _on_game_menu_draw() -> void:
	get_tree().set_pause(true)
	list_of_menus.show()
	if player.spell:
		if player.spell.get_sub_type() == "CHOOSE_AREA_EFFECT":
			player.spell.unmake()
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

func _on_dialogue_hide() -> void:
	dialogue.get_node(@"s/s/v/heal").hide()

func _on_merchant_draw() -> void:
	if player.target:
		if not (player.weapon and player.vest) \
		or player.target.get_type() == "TRAINER":
			merchant.get_node(@"s/v2/repair").hide()
			return
		if player.weapon:
			if player.weapon.durability < 1.0:
				merchant.get_node(@"s/v2/repair").show()
			else:
				merchant.get_node(@"s/v2/repair").hide()
		if player.vest:
			if player.vest.durability < 1.0:
				merchant.get_node(@"s/v2/repair").show()
			elif not merchant.get_node(@"s/v2/repair").is_visible() or !player.weapon:
				merchant.get_node(@"s/v2/repair").hide()

func _on_sift_configure(right: bool=true) -> void:
	globals.play_sample("click2")
	var meta: Dictionary = {"index":0, "bag":inventory_bag,"node":item_info,
				"left":"s/h/left","right":"s/h/right"}
	if merchant_bag.has_item(selected):
		meta.bag = merchant_bag
	elif spell_book.has_item(selected):
		meta.bag = spell_book
	meta.index = meta.bag.get_item_slot(selected, true) + 1
	if not right:
		meta.index -= 2
	if meta.index >= 0 and meta.index <= meta.bag.get_item_count() - 1:
		selected = meta.bag.get_item_metadata(meta.index)
		selected_index = meta.index
		selected.describe()
		if inventory_bag == meta.bag or merchant_bag == meta.bag:
			_on_bag_index_selected(meta.index, true)
		elif meta.bag.is_cooling_down(meta.index):
			item_info.get_node(@"s/h/v/cast").hide()
		elif not player.dead:
			item_info.get_node(@"s/h/v/cast").show()
	if meta.index <= 0:
		meta.node.get_node(meta.left).set_disabled(true)
	else:
		meta.node.get_node(meta.left).set_disabled(false)
	if meta.index >= meta.bag.get_item_count() - 1:
		meta.node.get_node(meta.right).set_disabled(true)
	else:
		meta.node.get_node(meta.right).set_disabled(false)

func _on_button_down(path: String) -> void:
	get_node(path).set_scale(Vector2(0.8, 0.8))

func _on_button_up(path: String) -> void:
	get_node(path).set_scale(Vector2(1.0, 1.0))

func _on_hud_button_down(path: String) -> void:
	get_node(path).get_parent().set_texture(load("res://asset/img/ui/on_screen_button_pressed.res"))
	get_node(path).set_scale(Vector2(0.8, 0.8))

func _on_hud_button_up(path: String) -> void:
	get_node(path).get_parent().set_texture(load("res://asset/img/ui/on_screen_button.res"))
	get_node(path).set_scale(Vector2(1.0, 1.0))

func _on_move_hud(player: bool=true) -> void:
	var meta: Dictionary = {"node":hp_mana.get_node(@"m/h/p/h/g"), "amount":Vector2(-34.0, 0.0)}
	if player:
		if meta.node.rect_size.x == 100:
			meta.amount.x = -86.0
		if meta.node.rect_position.x != 0:
			meta.amount.x = 0.0
	else:
		meta.node = hp_mana.get_node(@"m/h/u/h/g")
		meta.amount = Vector2(331.0, 0.0)
		if meta.node.rect_size.x == 100:
			meta.amount.x = 383.0
		if meta.node.rect_position.x != 297:
			meta.amount.x = 297.0
	$tween.interpolate_property(meta.node, @":rect_position", meta.node.rect_position, \
	meta.amount, 0.5, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	$tween.start()

func _on_heal_pressed() -> void:
	var amount: int = Stats.healer_cost(player.level)
	if player.gold >= amount:
		globals.play_sample("sell_buy")
		player.set_gold(-amount)
		player.set_hp(player.hp_max)
		_on_back_pressed()
	else:
		popup.get_node(@"m/error/label").set_text("Not Enough\nGold!")
		popup.get_node(@"m/error").show()
		popup.show()

func _on_item_info_label_draw() -> void:
	var label_node: Label = item_info.get_node(@"s/v/c/v/c/label")
	label_node.set_custom_minimum_size(label_node.get_parent().rect_size)

func _on_add_to_hud_pressed() -> void:
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
	$c/controls/right.hide()
	$c/controls.show()
	popup.get_node(@"m/add_to_slot").show()
	popup.show()

func _on_describe_object(obj: Pickable, obj_des: String) -> void:
	if merchant_bag.has_item(obj) and selected.get_filename().get_file().get_basename() == "spell":
		obj_des = obj_des.insert(obj_des.find_last("-") - 2, \
		"\n-Required Level: %s\n-Gold: %s" % [obj.level, obj.gold])
	item_info.get_node(@"s/v/label").set_text(obj.world_name.capitalize())
	item_info.get_node(@"s/v/c/v/bg/m/icon").set_texture(obj.icon)
	item_info.get_node(@"s/v/c/v/c/label").set_text(obj_des)

func _on_set_obj_in_menu(obj: Pickable, stack: bool, type: String) -> void:
	match type.to_upper():
		"MERCHANT":
			merchant_bag.add_item(obj, stack)
		"ITEM":
			inventory_bag.add_item(obj, stack)
		"SPELL":
			spell_book.add_item(obj, stack)

func _on_equip_item(obj: Item, on: bool) -> void:
	match obj.get_type():
		"WEAPON":
			player.weapon = obj if on else null
			player.min_damage += obj.min_value if on else -obj.min_value
			player.max_damage += obj.max_value if on else -obj.max_value
		"ARMOR":
			player.vest = obj if on else null
			player.armor += obj.value if on else -obj.value
	var path: NodePath = NodePath("s/v/h/%s_slot/m/icon" % obj.get_type().to_lower())
	inventory.get_node(path).set_texture(obj.icon if on else null)
	stats_menu.get_node(path).set_texture(obj.icon if on else null)
	if on:
		if selected_index == -1:
			# this is for if the item is loaded from save game
			selected_index = inventory_bag.get_item_slot(selected, true)
		inventory_bag.remove_item(selected_index)
	else:
		inventory_bag.add_item(obj)
		var slot: Slot = inventory_bag.get_item_slot(obj)
		for shortcut in get_tree().get_nodes_in_group("HUD-shortcut"):
			if shortcut.get_item() == obj and not slot.is_connected("sync_slot", shortcut, "_on_sync_shortcut"):
				slot.connect("sync_slot", shortcut, "_on_sync_shortcut")

func _on_drop_item(obj: Pickable) -> void:
	inventory_bag.remove_item(inventory_bag.get_item_slot(obj, true))
	player.get_node(@"inventory").remove_child(obj)
	globals.current_scene.get_node(@"zed/z1").add_child(obj)
	obj.set_owner(globals.current_scene)
	obj.set_global_position(player.get_global_position())

func snd_configure(bypass: bool=false, off: bool=false) -> String:
	var sound_name: String = ""
	if item_info.get_node(@"s/h/v/drop").is_visible() and not bypass:
		sound_name = "inventory_close"
	else:
		match selected.get_type():
			"ARMOR":
				sound_name = "%s_on" % \
				globals.item_meta["armor"][str(selected.get_level())] \
				[selected.get_sub_type().to_lower()][2]
			"WEAPON":
				match selected.get_sub_type():
					"STAFF", "BOW":
						sound_name = "wood_on"
					_:
						sound_name = "metal1_on"
			"POTION":
				sound_name = "glass_on"
			_:
				sound_name = "misc_on"
	if off:
		sound_name = sound_name.replace("on", "off")
	return sound_name

func update_hud(type: String, who, value1, value2) -> void:
	match type.to_upper():
		"NAME":
			if who != player:
				hp_mana.get_node(@"m/h/u/c/bg/m/v/label").set_text(value1)
				merchant.get_node(@"s/v/label").set_text(value1)
			else:
				hp_mana.get_node(@"m/h/p/c/bg/m/v/label").set_text(value1)
		"ICON":
			var path: String = "m/h/p/h/g"
			if who != player:
				path = "m/h/u/h/g"
			for slot in hp_mana.get_node(path).get_children():
				if not slot.get_item():
					value1.connect("unmake", slot, "set_item", [null, false, true])
					slot.set_item(value1)
					slot.cool_down(value1, value1.duration, value2)
					slot.show()
					break
		"ICON_HIDE":
			var path: String = "m/h/p/h/g"
			if who != player:
				path = "m/h/u/h/g"
			for slot in hp_mana.get_node(path).get_children():
				if not slot.is_class("Container"):
					slot.set_item(null, false, true)
					slot.hide()
		_:
			var bar: String = "m/h/p/c/bg/m/v/%s_bar"
			var lbl: String = "m/h/p/c/bg/m/v/%s_bar/label"
			if who != player:
				bar = "m/h/u/c/bg/m/v/%s_bar"
				lbl = "m/h/u/c/bg/m/v/%s_bar/label"
			hp_mana.get_node(bar % type).set_value(100.0 * value1 / value2)
			hp_mana.get_node(lbl % type).set_text("%s/%s" % [int(round(value1)), int(round(value2))])

func get_save_game() -> Dictionary:
	var save_dict: Dictionary = {"quest_names":[], "spells":[], "used_slots":[], "inventory":[]}
	var dict: Dictionary = {}
	var buffs: Array = player.buffs.active
	for other_buff in player.buffs.pending:
		buffs.append(other_buff)
	for quest_slot in quest_log.get_node(@"s/v/s/v").get_children():
		save_dict.quest_names.append(quest_slot.quest)
	for spell in spell_book.get_items():
		var slot: Slot = spell_book.get_item_slot(spell)
		save_dict.spells.append([spell.get_type(true), slot.time, slot.get_node(@"tween").tell()])
	var inventory: Array = inventory_bag.get_items(true)
	if player.weapon:
		inventory.append(player.weapon)
	if player.vest:
		inventory.append(player.vest)
	for item in inventory:
		save_dict.inventory.append({"type":item.get_type(true), \
		"sub_type":item.get_sub_type(true),  "level":item.get_level(),
		"gold":item.gold, "durability":item.durability, \
		"equipped": true if item == player.weapon \
		or item == player.vest else false})
	for buff in buffs:
		dict = {"type":buff.get_type(true), "sub_type":buff.get_sub_type(true), "level":buff.get_level(),
		"time":buff.get_time_left()}
		if dict.time == buff.get_initial_time():
			dict.time = 0
		save_dict.buffs.append(dict)
	for slot in get_tree().get_nodes_in_group("HUD-shortcut"):
		if slot.get_item():
			dict = {"slot":slot.get_name()}
			if inventory_bag.has_item(slot.get_item()):
				dict.index = inventory_bag.get_item_slot(slot.item, true)
				dict.bag = "inventory_bag"
			elif spell_book.has_item(slot.get_item()):
				dict.index = spell_book.get_item_slot(slot.item, true)
				dict.bag = "spell_book"
			elif player.weapon == slot.get_item():
				dict.equipped_item = "weapon"
			elif player.vest == slot.get_item():
				dict.equipped_item = "vest"
			save_dict.used_slots.append(dict)
	return save_dict

func set_save_game(data: Dictionary) -> void:
	for attribute in data:
		match attribute:
			"quest_names":
				for quest in data[attribute]:
					var q = globals.quest_entry.instance()
					q.set_quest(quest)
					quest_log.get_node(@"s/v/s/v").add_child(q)
					quest_log.get_node(@"s/v/s/v").move_child(q, 0)
					q.set_owner(self)
					for quest_type in globals.quests:
						for quest_name in globals.quests[quest_type]:
							if quest_name.capitalize() == quest.quest_name:
								globals.quests[quest_type][quest_name] = quest
			"spells":
				for spell_meta in data[attribute]:
					var spll = globals.spell.instance()
					spll.set_type(spell_meta[0])
					spll.get_obj(player, true)
					spell_book.set_slot_cool_down( \
					spell_book.get_item_slot(spll, true), spell_meta[1], spell_meta[2])
			"inventory":
				for item_dict in data[attribute]:
					var itm: Item = globals.item.instance()
					for item_attribute in item_dict:
						itm.set(item_attribute, item_dict[item_attribute])
					itm.get_obj(player, true)
					if item_dict.equipped:
						selected = itm
						selected.set_meta("loaded", true)
						_on_equip_pressed()
						inventory.hide()
	for itm in data.used_slots:
		for slot in get_tree().get_nodes_in_group("HUD-shortcut"):
			if slot.get_name() == itm.slot:
				if itm.has("bag"):
					selected = get(itm.bag).get_item_metadata(itm.index)
				else:
					selected = player.get(itm.equipped_item)
				popup._on_slot_pressed(itm.slot)
	selected = null
	selected_index = -1

func item_info_go(selected_item: Pickable) -> void:
	if selected_item:
		selected = selected_item
		item_info_hide_except()
		item_info.get_node(@"s/h/left").hide()
		item_info.get_node(@"s/h/right").hide()
		globals.play_sample(snd_configure(false, true))
		selected_item.describe()
		if stats_menu.is_visible():
			stats_menu.hide()
			selected_index = stats_menu
			item_info_hide_except()
		elif inventory.is_visible() or !selected:
			inventory.hide()
			if not player.dead:
				item_info_hide_except(["unequip"])
		item_info.show()

func hide_menu(play_snd: String="") -> void:
	if item_info.get_node(@"s/h/v/back").is_connected("pressed", self, "hide_menu"):
		if item_info.is_visible():
			if spell_book.has_item(selected):
				globals.play_sample("spell_book_close")
			else:
				globals.play_sample(snd_configure(true, true))
		item_info.get_node(@"s/h/v/back").disconnect("pressed", self, "hide_menu")
		item_info.get_node(@"s/h/v/back").connect("pressed", self, "_on_back_pressed")
		item_info.hide()
		item_info.get_node(@"s/h/left").show()
		item_info.get_node(@"s/h/right").show()
	$c/game_menu.hide()

func item_info_hide_except(list: Array=[]) -> void:
	for bttn in item_info.get_node(@"s/h/v").get_children():
		if not list.has(bttn.get_name()) and bttn.get_name() != "back":
			bttn.hide()
		else:
			bttn.show()

func _on_hud_slot_pressed(slot: Slot, itm: Pickable) -> void:
	selected = itm
	if spell_book.has_item(itm):
		selected_index = spell_book.get_item_slot(itm, true)
	elif inventory_bag.has_item(itm):
		selected_index = inventory_bag.get_item_slot(itm, true)
	if itm.get_filename().get_file().get_basename() == "item":
		if not player.dead and not slot.is_cooling_down \
		and (itm.get_type() == "FOOD" or itm.get_type() == "POTION"):
			_on_use_pressed(true)
		elif player.weapon == itm or player.vest == itm:
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
	elif slot.is_cooling_down or player.dead:
		prep_item_info()
		globals.play_sample("turn_page")
		_on_spell_selected(selected_index, true)
	else:
		_on_cast_pressed()
	selected_index = -1

func prep_item_info() -> void:
	_on_pause_pressed(true)
	menu.hide()
	item_info.get_node(@"s/h/left").hide()
	item_info.get_node(@"s/h/right").hide()
	item_info.get_node(@"s/h/v/back").disconnect("pressed", self, "_on_back_pressed")
	item_info.get_node(@"s/h/v/back").connect("pressed", self, "hide_menu")

func show_quest_text(quest: Quest) -> void:
	globals.play_sample("click2")
	selected = quest_log
	dialogue.get_node(@"s/label").set_text(quest.quest_name)
	dialogue.get_node(@"s/s/label2").set_bbcode(quest.format_with_objective_text())
	quest_log.hide()
	dialogue.show()

func _on_unit_hud_draw():
	hp_mana.set_size(Vector2(720.0, 185.0))

func _on_unit_hud_hide():
	hp_mana.set_size(Vector2(360.0, 185.0))
