"""
Contains all the formulas and stats in the game. Refer to spreadsheet 'stats'.
"""
extends Node
class_name Stats

const attack_table = {"ranged":{"hit":74,"critical":78,"dodge":84,"parry":89},
"melee":{"hit":74,"critical":78,"dodge":84,"parry":89}}

const drop_table = {"drop":60,"quest_item":50,
"misc":50,"food_potion":70,"weapon":85,"armor":100}

const MULTIPLIER: float = 2.6
const MAX_LEVEL: int = 10
const XP_INTERVAL: int = 1000
const MAX_XP: int = MAX_LEVEL * XP_INTERVAL
const HP_MANA_RESPAWN_LOWER_LIMIT: float = 0.3
const FLEE_DISTANCE: int = 128

static func unit_make(level, unit_multiplier, int_stats=true):
	var _stamina = (3 + level) * unit_multiplier
	var _agility = (1 + level) * unit_multiplier
	var _intellect = (2 + level) * unit_multiplier
	var _hp_max = (6.0 * level + 24 + _stamina) * unit_multiplier
	var _mana_max = (6.0 * level + 16 + _intellect) * unit_multiplier
	var _max_damage = ((_hp_max * 0.225) - (_hp_max * 0.225 / 2.0)) / 2.0
	var _min_damage =  _max_damage / 2.0
	var _regen_time = 60 - 60 * _agility * 0.01
	var _armor = ((_stamina + _agility) / 2.0) * ((_min_damage + _max_damage) / 2.0) * 0.01
	var dict = {"stamina":_stamina,"agility":_agility,"intellect":_intellect,
	"hp_max":_hp_max,"mana_max":_mana_max,"max_damage":_max_damage,
	"min_damage":_min_damage,"regen_time":_regen_time,"armor":_armor}
	if int_stats:
		for value in dict:
			dict[value] = _make_int(dict[value])
	return dict

static func hp_mana_regen(level, unit_multiplier):
	return _make_int((6.0 * level + 24 + ((3 + level) * unit_multiplier)) * unit_multiplier * 0.05)

static func unit_death_xp(level, unit_multiplier, winner_level):
	return _make_int(20 + (level - winner_level) * unit_multiplier)

static func healer_cost(level):
	return _make_int((3 * level + 2) * 4)

static func item_repair_cost(item_level):
	return _make_int((3 * item_level + 1) * 3)

static func get_modified_regen(level, unit_multiplier, value):
	var _agility = (1 + level) * unit_multiplier + value
	var _regen_time = 60 - 60 * _agility * 0.01
	return _make_int(_regen_time)

static func get_item_gold(level, item_type, durability):
	var gold = 3 * level + 4
	match item_type:
		"FOOD":
			gold *= 2
		"HEALING", "MANA":
			gold *= 3
		"STAMINA", "INTELLECT", "AGILITY", "STRENGTH", "DEFENSE":
			gold *= 4
		"WEAPON":
			gold *= 5
		"ARMOR":
			gold *= 6
	return _make_int(gold * durability)

static func damage_item(item_type, item_stats):
	var min_value = -1
	var max_value = -1
	match item_type:
		"WEAPON":
			var _stats = unit_make(item_stats.level, MULTIPLIER, false)
			max_value = _stats.hp_max * item_stats.durability * 0.225
			min_value = max_value / 2.0
		"ARMOR":
			min_value = item_stats.value * item_stats.durability
	return [_make_int(min_value), _make_int(max_value)]

static func get_item_stats(level, item_type):
	var _stats = unit_make(level, MULTIPLIER, false)
	var min_value = -1
	var max_value = -1
	match item_type:
		"HEALING":
			min_value = _stats.hp_max * 0.3
			max_value = min_value * 1.25
		"MANA":
			min_value = _stats.mana_max * 0.3
			max_value = min_value * 1.25
		"STAMINA":
			min_value = _stats.stamina / 2.0
		"INTELLECT":
			min_value = _stats.intellect / 2.0
		"AGILITY":
			min_value = _stats.agility / 2.0
		"STRENGTH":
			min_value = (_stats.min_damage + _stats.max_damage) / 2.0
		"DEFENSE":
			min_value = level
		"WEAPON":
			min_value = _stats.min_damage
			max_value = _stats.max_damage
		"ARMOR":
			min_value = level
		"FOOD":
			max_value = _stats.hp_max * 0.09375
			min_value = max_value / 2.0
	return [_make_int(min_value), _make_int(max_value)]

static func get_multiplier(unit_sprite, npc):
	var _multiplier: float = 1.0
	if npc:
		match unit_sprite.get_texture().get_path().get_base_dir().get_file():
			"minotaur", "oliphant":
				_multiplier = 2.4
			"human", "orc":
				_multiplier = 2.2
			"gnoll", "goblin", "warthog":
				_multiplier = 2.0
			"critter":
				_multiplier = 1.8
	else:
		_multiplier = MULTIPLIER
	return _multiplier

static func level_check(xp):
	return _make_int((xp + XP_INTERVAL) / XP_INTERVAL - 1)

static func _make_int(num):
	return int(round(num))
