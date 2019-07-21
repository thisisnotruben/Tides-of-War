extends "res://src/misc/pickable.gd"
class_name Item

var durability: float = 1.0
var min_value = 0
var max_value = 0
var value = 0

signal equip_self(obj, on)

func _ready():
	make()

func _on_timer_timeout():
	configure_buff(owner, true)

func equip():
	emit_signal("equip_self", self, true)

func unequip():
	emit_signal("equip_self", self, false)

func consume(whos_consuming, seek):
	emit_signal("exchanged", self, false)
	if sub_type == SUB_TYPES.HEALING or sub_type == SUB_TYPES.MANA or type == TYPES.FOOD:
		var amount: float = rand_range(min_value, max_value)
		if sub_type == SUB_TYPES.MANA:
			whos_consuming.set_mana(amount)
		elif sub_type == SUB_TYPES.HEALING:
			whos_consuming.set_hp(amount)
		else:
			unmake()
			return
	configure_buff(whos_consuming, false)
	if get_tree().is_paused():
		whos_consuming.buffs.pending.append(self)
	else:
		whos_consuming.set_buff([self], seek)

func configure_buff(consumer, expire=false):
	"""Sets the stats of the item to the consumer"""
	if is_connected("set_in_menu", consumer.igm, "_on_set_obj_in_menu"):
		disconnect("set_in_menu", consumer.igm, "_on_set_obj_in_menu")
	if expire:
		value *= -1
	match sub_type:
		SUB_TYPES.STAMINA:
			var percent: float = consumer.hp / consumer.hp_max
			consumer.hp_max += value
			consumer.set_hp(consumer.hp_max * percent)
		SUB_TYPES.INTELLECT:
			var percent: float = consumer.mana / consumer.mana_max
			consumer.mana_max += value
			consumer.set_mana(consumer.mana_max * percent)
		SUB_TYPES.AGILITY:
			var regen_amount: float = stats.get_modified_regen(consumer.level, \
			stats.get_multiplier(consumer.get_node(@"img"), consumer.npc), value)
			consumer.regen_time = regen_amount
			if not consumer.attacking:
				consumer.set_time(consumer.regen_time, false)
			consumer.max_vel += value
		SUB_TYPES.STRENGTH:
			consumer.min_damage += value
			consumer.max_damage += value
		SUB_TYPES.DEFENSE:
			consumer.armor += value
	if expire:
		consumer.buffs.active.erase(self)
		unmake()

func take_damage(bypass=false, amount=-0.10):
	"""If the item is a weapon, its takes possible damage if being used.
	if the item is a vest, it takes possible damage is strucken upon"""
	if randi() % 100 + 1 <= 10 or bypass:
		var old_dur: float = durability
		durability += amount
		if durability > 1.0:
			durability = 1.0
		obj_des = obj_des.replace(str(int(round(old_dur * 100))) + "%", str(int(round(durability * 100))) + "%")
		if durability >= 0.5:
			var old_str = {"min":str(min_value),"max":str(max_value),"value":str(value),"gold":str(gold)}
			gold = stats.get_item_gold(level, get_type(), durability)
			if type == TYPES.WEAPON:
				var _stats = stats.damage_item(get_type(), {"level":level,"durability":durability})
				min_value = _stats[0]
				max_value = _stats[1]
				obj_des = obj_des.replace(old_str["min"], str(min_value))
				obj_des = obj_des.replace(old_str["max"], str(max_value))
			elif type == TYPES.ARMOR:
				value = stats.damage_item(get_type(), {"value":value, "durability":durability})
				obj_des = obj_des.replace(old_str["value"], str(value))
			obj_des = obj_des.replace(old_str["gold"], str(gold))

func make():
	var path: String = "res://asset/img/icon"
	var key: String = get_type().to_lower()
	var sub_key: String = get_sub_type().to_lower()
	if type == TYPES.POTION:
		path = path.plus_file("/%s/%s_icon.res" % [key, globals.item_meta[key][str(level)][sub_key]])
		if sub_type == SUB_TYPES.HEALING or sub_type == SUB_TYPES.MANA:
			set_obj_name("%s %s %s" % [globals.item_meta[key][str(level)]["name"], sub_key, "Potion"])
		else:
			set_obj_name("Elixir Of %s %s" % [globals.item_meta[key][str(level)]["name"], sub_key])
	else:
		path = path.plus_file("/%s/%s_icon.res" % [key, globals.item_meta[key][str(level)][sub_key][1]])
		set_obj_name(globals.item_meta[key][str(level)][sub_key][0])
	icon = load(path)
	if type == TYPES.POTION:
		var _stats = stats.get_item_stats(level, get_sub_type())
		gold = stats.get_item_gold(level, get_sub_type(), durability)
		set_duration(120.0)
		stack_size = 5
		match sub_type:
			SUB_TYPES.HEALING, SUB_TYPES.MANA:
				min_value = _stats[0]
				max_value = _stats[1]
			_:
				value = _stats[0]
	else:
		var _stats = stats.get_item_stats(level, get_type())
		gold = stats.get_item_gold(level, get_type(), durability)
		match type:
			TYPES.WEAPON, TYPES.FOOD:
				min_value = _stats[0]
				max_value = _stats[1]
				if type == TYPES.FOOD:
					set_duration(1.0)
					stack_size = 5
			TYPES.ARMOR:
				value = _stats[0]
	if type == TYPES.WEAPON:
		obj_des = "-Damage: %s - %s" % [min_value, max_value]
	elif type == TYPES.ARMOR:
		obj_des = "-Armor: %s" % value
	elif type == TYPES.FOOD or sub_type == SUB_TYPES.HEALING:
		obj_des = "-Restores %s - %s health" % [min_value, max_value]
	elif sub_type == SUB_TYPES.MANA:
		obj_des = "-Restores %s - %s Mana" % [min_value, max_value]
	elif type != TYPES.MISC:
		obj_des = "-Grants %s %s\nfor 120 seconds." % [value, sub_key]
	obj_des += "\n-Gold: %s" % gold
	if type == TYPES.WEAPON or type == TYPES.ARMOR:
		obj_des += "\n-Durability: %s%%" % int(round(durability * 100))
	.make()
