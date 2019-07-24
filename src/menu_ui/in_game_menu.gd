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

func _ready() -> void:
	for item_list in [inventory_bag, spell_book]:
		for slot in item_list.get_children():
			for hud_slot in hp_mana.get_node(@"h/p/h/g").get_children():
				slot.connect("cooldown", hud_slot, "cool_down")
				hud_slot.connect("cooldown", slot, "cool_down")
			for short_cut in get_tree().get_nodes_in_group("HUD-shortcut"):
				slot.connect("cooldown", short_cut, "cool_down")
				short_cut.connect("cooldown", slot, "cool_down")
	for scroller in [item_info.get_node(@"s/v/c/v/c/label"), quest_log.get_node(@"s/v/s")]:
		for node in scroller.get_children():
			if node.is_class("ScrollBar"):
				node.set_modulate(Color(1.0, 1.0, 1.0, 0.0))

func _on_back_pressed() -> void:
	var sound_played: bool = false
	if save_load.is_visible():
		save_load.hide()
		menu.show()
	if not sound_played:
		globals.play_sample("click3")

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
		elif not get_owner().dead:
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
			get_owner().weapon = obj if on else null
			get_owner().min_damage += obj.min_value if on else -obj.min_value
			get_owner().max_damage += obj.max_value if on else -obj.max_value
		"ARMOR":
			get_owner().vest = obj if on else null
			get_owner().armor += obj.value if on else -obj.value
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
	get_owner().get_node(@"inventory").remove_child(obj)
	globals.current_scene.get_node(@"zed/z1").add_child(obj)
	obj.set_owner(globals.current_scene)
	obj.set_global_position(get_owner().get_global_position())

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
			if who != get_owner():
				hp_mana.get_node(@"h/u/c/bg/m/v/label").set_text(value1)
				merchant.get_node(@"s/v/label").set_text(value1)
			else:
				hp_mana.get_node(@"h/p/c/bg/m/v/label").set_text(value1)
		"ICON":
			var path: String = "h/p/h/g"
			if who != get_owner():
				path = "h/u/h/g"
			for slot in hp_mana.get_node(path).get_children():
				if not slot.get_item():
					value1.connect("unmake", slot, "set_item", [null, false, true])
					slot.set_item(value1)
					slot.cool_down(value1, value1.duration, value2)
					slot.show()
					break
		"ICON_HIDE":
			var path: String = "h/p/h/g"
			if who != get_owner():
				path = "h/u/h/g"
			for slot in hp_mana.get_node(path).get_children():
				if not slot.is_class("Container"):
					slot.set_item(null, false, true)
					slot.hide()
		_:
			var bar: String = "h/p/c/bg/m/v/%s_bar"
			var lbl: String = "h/p/c/bg/m/v/%s_bar/label"
			if who != get_owner():
				bar = "h/u/c/bg/m/v/%s_bar"
				lbl = "h/u/c/bg/m/v/%s_bar/label"
			hp_mana.get_node(bar % type).set_value(100.0 * value1 / value2)
			hp_mana.get_node(lbl % type).set_text("%s/%s" % [int(round(value1)), int(round(value2))])

func get_save_game() -> Dictionary:
	var save_dict: Dictionary = {"quest_names":[], "spells":[], "used_slots":[], "inventory":[]}
	var dict: Dictionary = {}
	var buffs: Array = get_owner().buffs.active
	for other_buff in get_owner().buffs.pending:
		buffs.append(other_buff)
	for quest_slot in quest_log.get_node(@"s/v/s/v").get_children():
		save_dict.quest_names.append(quest_slot.quest)
	for spell in spell_book.get_items():
		var slot: Slot = spell_book.get_item_slot(spell)
		save_dict.spells.append([spell.get_type(true), slot.time, slot.get_node(@"tween").tell()])
	var inventory: Array = inventory_bag.get_items(true)
	if get_owner().weapon:
		inventory.append(get_owner().weapon)
	if get_owner().vest:
		inventory.append(get_owner().vest)
	for item in inventory:
		save_dict.inventory.append({"type":item.get_type(true), \
		"sub_type":item.get_sub_type(true),  "level":item.get_level(),
		"gold":item.gold, "durability":item.durability, \
		"equipped": true if item == get_owner().weapon \
		or item == get_owner().vest else false})
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
			elif get_owner().weapon == slot.get_item():
				dict.equipped_item = "weapon"
			elif get_owner().vest == slot.get_item():
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
					spll.get_obj(get_owner(), true)
					spell_book.set_slot_cool_down( \
					spell_book.get_item_slot(spll, true), spell_meta[1], spell_meta[2])
			"inventory":
				for item_dict in data[attribute]:
					var itm: Item = globals.item.instance()
					for item_attribute in item_dict:
						itm.set(item_attribute, item_dict[item_attribute])
					itm.get_obj(get_owner(), true)
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
					selected = get_owner().get(itm.equipped_item)
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
			if not get_owner().dead:
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
