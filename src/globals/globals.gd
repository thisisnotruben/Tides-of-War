"""
Singleton that houses all meta-data and support functions for the game.
"""
extends Node
class_name Globals

# for setting area collision layer/mask
const collision: Dictionary = {"WORLD": 1, "CHARACTERS": 2, \
"DEAD_CHARACTERS": 3, "COMBUSTIBLE": 8}

const combat_text = preload("res://src/misc/other/combat_text.tscn")
const quest_entry = preload("res://src/menu_ui/quest_entry.tscn")
const buff_anim = preload("res://src/misc/other/buff_anim.tscn")
const missile = preload("res://src/misc/missile/missile.tscn")
const footstep = preload("res://src/misc/other/footstep.tscn")
const grave = preload("res://src/misc/other/grave.tscn")
const item = preload("res://src/misc/loot/item.tscn")
const spell = preload("res://src/spell/spell.tscn")

const SAVE_PATHS: Dictionary = {"GAME_META":"res://meta/game_meta.json",
					"ITEM_META":"res://meta/item_meta.json",
					"UNIT_META":"res://meta/unit_meta.json",
					"QUEST_META":"res://meta/quest_meta.json",
					"SPELL_META":"res://meta/spell_meta.json",
					"SAVE_SLOT_0":"res://meta/save_slot_0.json",
					"SAVE_SLOT_1":"res://meta/save_slot_1.json",
					"SAVE_SLOT_2":"res://meta/save_slot_2.json",
					"SAVE_SLOT_3":"res://meta/save_slot_3.json",
					"SAVE_SLOT_4":"res://meta/save_slot_4.json",
					"SAVE_SLOT_5":"res://meta/save_slot_5.json",
					"SAVE_SLOT_6":"res://meta/save_slot_6.json",
					"SAVE_SLOT_7":"res://meta/save_slot_7.json"}

const weapon_type: Dictionary = {"axe":5,"club":3,"dagger":3,
"sword":8,"arrow_hit_armor":5,"bow":5}

var file: File = File.new()
var _scene_meta: Dictionary = {}
var quest_meta: Dictionary = {}
var spell_meta: Dictionary = {}
var item_meta: Dictionary = {}
var unit_meta: Dictionary = {}
var game_meta: Dictionary = {}
var snd_meta: Dictionary = {}
var day_night: bool = true
var current_scene: Object
var player: Character

func _ready() -> void:
	set_process(false)
	load_meta()
	load_snd()

func _process(delta: float) -> void:
	"""Displays loading scene"""
	match current_scene.poll():
		OK:
			$progress_bar/m/v/bar.set_value(100.0 * current_scene.get_stage() / current_scene.get_stage_count())
		ERR_FILE_EOF:
			set_process(false)
			current_scene = current_scene.get_resource().instance()
			get_tree().get_root().add_child(current_scene)
			if not _scene_meta.empty():
				for node_path in _scene_meta:
					if node_path != "scene":
						get_node(node_path).set_save_game(_scene_meta[node_path])
				_scene_meta.clear()
			world_quests.update()

func set_scene(scene: String) -> void:
	current_scene.hide()
	call_deferred("_defferred_set_scene", scene)

func _defferred_set_scene(scene: String) -> void:
	"""Deferred to allow processes in scene to complete before termination"""
	current_scene.free()
	current_scene = ResourceLoader.load_interactive(scene)
	set_process(true)

func save_meta(data, index: int) -> void:
	file.open(SAVE_PATHS["GAME_META"], file.WRITE)
	var save_dict: Dictionary = {}
	game_meta["slot_%s" % index] = data
	save_dict = game_meta
	file.store_line(to_json(save_dict))
	file.close()

func load_meta() -> void:
	for file_name in SAVE_PATHS:
		if "META" in file_name:
			file.open(SAVE_PATHS[file_name], file.READ)
			set(file_name.to_lower(), parse_json(file.get_as_text()))
			file.close()

func load_snd(path: String="res://asset/snd") -> void:
	"""Recursively searches through default directory and loads Snd-Fx"""
	var res: String
	var dir: Directory = Directory.new()
	dir.open(path)
	dir.list_dir_begin(true, true)
	while true:
		res = dir.get_next()
		if res.empty():
			break
		res = path.plus_file(res)
		if dir.current_is_dir():
			load_snd(res)
		elif dir.file_exists(res):
			if ".import" in res:
				res.erase(res.find(".import"), 7)
			snd_meta[res.get_file().get_basename()] = load(res)
	dir.list_dir_end()

func save_game(save_path: String) -> void:
	file.open(save_path, file.WRITE)
	var save_dict: Dictionary = {}
	save_dict.scene = current_scene.get_filename()
	for node in get_tree().get_nodes_in_group("save"):
		save_dict[node.get_path()] = node.get_save_game()
	file.store_line(to_json(save_dict))
	file.close()

func load_game(save_path: String) -> void:
	if file.file_exists(save_path):
		file.open(save_path, file.READ)
		_scene_meta = parse_json(file.get_as_text())
		file.close()
		set_scene(_scene_meta.scene)

static func add_comma(value) -> String:
	"""Adds comma to a number"""
	value = str(value)
	var adec: String = ""
	if '.' in value:
		adec = '.' + value.split('.')[1]
		value = value.split('.')[0]
	var vlength: int = value.length()
	for idx in vlength:
		if idx != 0 and idx % 3 == 0:
			value = value.insert(vlength - idx, ',')
	return value + adec

static func get_enum_key(keys: Dictionary, value: int) -> String:
	for v in keys:
		if keys[v] == value:
			return v
	return ""

static func merge_dict(dict1: Dictionary, dict2: Dictionary) -> Dictionary:
	var merged_dict: Dictionary = {}
	for key in dict1:
		merged_dict[key] = dict1[key]
	for key in dict2:
		merged_dict[key] = dict2[key]
	return merged_dict

func _on_speaker_finished(path) -> void:
	get_node(path).queue_free()

func play_sample(snd: String, speaker: Node=$snd) -> bool:
	if not speaker.is_playing():
		speaker.set_volume_db(-10.0)
		speaker.set_stream(snd_meta[snd])
		speaker.play()
		return true
	else:
		var new_speaker: Node = ClassDB.instance(speaker.get_class())
		speaker.get_parent().add_child(new_speaker)
		new_speaker.connect("finished", self, "_on_speaker_finished", [new_speaker.get_path()])
		play_sample(snd, new_speaker)
		return false

func drop_loot(unit: Character, spawn_pos: Vector2, gold: int, drop_table: Dictionary=Stats.drop_table):
	randomize()
	if randi() % 100 + 1 <= drop_table.drop:
		var chance: int = randi() % 100 + 1
		var sub_types: Array = ["T1", "T2"]
		var itm: Item = item.instance()
		if chance <= drop_table.misc:
			itm.set_type("MISC")
		elif chance <= drop_table.food_potion:
			chance = randi() % 100 + 1
			if chance <= 50:
				itm.set_type("FOOD")
			else:
				itm.set_type("POTION")
				sub_types = ["HEALING", "MANA", "STAMINA", \
				"INTELLECT", "AGILITY", "STRENGTH", "DEFENSE"]
		elif chance <= drop_table.weapon:
			itm.set_type("WEAPON")
			sub_types = ["SWORD", "DAGGER", "SPEAR", "AXE", \
			"CLAW", "MACE", "STAFF", "BOW"]
		elif chance <= drop_table.armor:
			itm.set_type("ARMOR")
		itm.set_sub_type(sub_types[randi() % sub_types.size()])
		itm.set_level(randi() % unit.level + 1)
		itm.gold_drop = gold
		itm.set_global_position(spawn_pos)
		unit.get_parent().add_child(itm)
		return itm