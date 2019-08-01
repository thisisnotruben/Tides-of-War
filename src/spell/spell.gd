"""
Handles the spells, each method is a particular spell
"""

extends "res://src/misc/pickable.gd"
class_name Spell

var spell_range: int = 0
var mana_cost: int = 0
var count: int = 0
var effect_on_target: bool = false
var requires_target: bool = true
var ignore_armor: bool = false
var loaded: bool = false
var casted: bool = false
var attack_table: Dictionary = {}

var caster: Character

func _ready() -> void:
	set_process(false)

func get_obj(unit: Character, add_to_bag: bool=true) -> void:
	"""polymorphed method"""
	.get_obj(unit, add_to_bag)
	caster = unit

#---osb type spells---

func _on_spell_area_pressed() -> void:
	"""When clicking selection, you are allowed to move selection"""
	set_process(true)

func _on_spell_area_released() -> void:
	"""When releasing selection, it stays put"""
	set_process(false)

func _process(delta: float) -> void:
	"""This moves highlight selection, and orientates
	OSB based where selection is on screen"""
	set_global_position(caster.get_center_pos() + (get_global_mouse_position() - caster.get_center_pos()).clamped(spell_range))
	if caster.get_center_pos().y > get_global_position().y:
		caster.igm.get_node(@"c/osb").set_position(Vector2(0.0, 666.0))
	else:
		caster.igm.get_node(@"c/osb").set_position(Vector2(0.0, 180.0))

func unmake_if_caster_moved(caster: Object, state: String) -> void:
	"""Deletes queued spell and hides OSB if caster moves,
	connected from unit tween"""
	if state ==":global_position" and caster.get_state(true) == "MOVING":
		caster.igm.get_node(@"c/osb").hide()
		unmake()

func _on_spell_area_cast() -> void:
	"""Casts spell and a little house cleaning"""
#	you cannot move selection anymore
	set_process(false)
	caster.igm.get_node(@"c/osb").hide()
#	disconnecting avoids double-clicking and clean-up
	caster.get_node(@"tween").disconnect("tween_started", self, "unmake_if_caster_moved")
	caster.igm.get_node(@"c/osb/m/cast").disconnect("pressed", self, "_on_spell_area_cast")
	remove_from_group(str(caster.igm.get_node(@"c/osb").get_instance_id()))
	globals.play_sample("click2")
	hide()
	cast()
	for body in data:
		body.set_modulate(Color(1.0, 1.0, 1.0))
		body.set_z_index(0)

func _on_sight_body_entered(body: PhysicsBody2D) -> void:
	"""When selecting an area effect, this highlights
	all units that will be affected and selects them"""
	if not body.dead:
		data.append(body)
		if is_visible():
			body.set_modulate(Color(0.0, 1.0, 0.0))
			body.set_z_index(1)

func _on_sight_body_exited(body: PhysicsBody2D) -> void:
	"""Removes highlight and selection of units
	in area effect when moved away"""
	body.set_modulate(Color(1.0, 1.0, 1.0))
	body.set_z_index(0)
	data.erase(body)

#---end osb type spells---

#---main methods---

func cast(from_missile: bool=false):
	casted = true
#	damage is returned as a percentage
	var damage = call(world_name)
	if not loaded:
		caster.set_mana(-mana_cost)
#		Determines which effect to instance based on spell type
		if (sub_type == SUB_TYPES.CASTING or sub_type == SUB_TYPES.DAMAGE_MODIFIER) \
		and type != TYPES.EXPLOSIVE_TRAP and not from_missile:
			var load_effect: Resource = load("res://src/spell/effects/%s.tscn" % world_name)
			var effect: SpellEffect = load_effect.instance()
			effect.effect = world_name
			if effect_on_target:
				data.add_child(effect)
				effect.set_owner(data)
			else:
				caster.add_child(effect)
				effect.set_owner(caster)
			if type == TYPES.FRENZY or type == TYPES.BASH:
#				spell duration determines when effect will end
				connect("unmake", effect, "_on_timer_timeout")
			effect.on_hit(self)

	if duration == 0 and sub_type != SUB_TYPES.CHOOSE_AREA_EFFECT:
		set_name(str(get_instance_id()))
		set_time(2.5, false)
	return damage

func _on_timer_timeout() -> void:
	match type:
		TYPES.BASH:
			data.set_process(true)
		TYPES.HEMORRHAGE, TYPES.STINGING_SHOT, TYPES.SEARING_ARROW, TYPES.FIREBALL:
			data.take_damage(5, "hit", caster)
			count -= 1
			if count > 0:
				$timer.start()
				return
		TYPES.FRENZY:
			caster.max_vel -= data[0]
			caster.weapon_speed -= data[1]
		TYPES.STOMP:
			for unit in data:
				unit.set_process(true)
		TYPES.INTIMIDATING_SHOUT:
			for unit in data:
				unit = get_node(unit)
				unit.min_damage += data[unit][0]
				unit.max_damage += data[unit][1]
		TYPES.HASTE:
			caster.max_vel -= data[0]
			caster.anim_speed -= data[1]
		TYPES.FORTIFY:
			caster.armor -= data
		TYPES.CONCUSSIVE_SHOT, TYPES.FROST_BOLT, TYPES.SLOW:
			data[0].max_vel += data[1]
			data[0].weapon_speed += data[2]
	unmake()

func make() -> void:
	set_obj_name(globals.get_enum_key(TYPES, type).to_lower())
	level = int(globals.spell_meta[world_name].level)
	gold = int((3 * level + 10) * 6)
	mana_cost = (6 * level + 16 + (level + 2) * \
	Stats.MULTIPLIER) * Stats.MULTIPLIER * 0.3
	mana_cost = int(round((mana_cost + mana_cost * 1.25) / 2 - 9))
	spell_range = int(globals.spell_meta[world_name]["range"])
	var cooldown_text: String = globals.spell_meta[world_name].cooldown
	if "." in cooldown_text:
		if cooldown_text[0] == "0":
			cooldown = float(cooldown_text)
			cooldown_text = "%s sec." % cooldown_text
		else:
			var rational: PoolStringArray = cooldown_text.split(".")
			cooldown = float(int(rational[0]) * 60 + int(rational[1]) * 0.6)
			cooldown_text = "%s min." % cooldown_text
	else:
		cooldown = float(cooldown_text) * 60
		cooldown_text = "%s min." % cooldown_text
	icon = load("res://asset/img/icon/spell/%s_icon.res" % globals.spell_meta[world_name].icon)
	obj_des = "-Mana Cost: %s" % mana_cost
	if spell_range > 0:
		obj_des += "\n-Range: %s" % spell_range
	obj_des += "\n-Cooldown: %s\n\n-%s" % [cooldown_text, globals.spell_meta[world_name].des]
	match type:
		TYPES.INTIMIDATING_SHOUT, TYPES.FRENZY, TYPES.STOMP, TYPES.FORTIFY, TYPES.EXPLOSIVE_TRAP, TYPES.REJUVENATE, TYPES.HASTE, TYPES.METEOR:
			sub_type = SUB_TYPES.CASTING
			requires_target = false
			if type == TYPES.METEOR:
				set_data([])
				sub_type = SUB_TYPES.CHOOSE_AREA_EFFECT
				var spell_radius: int = 24
				$spell_area.set_scale(Vector2(spell_radius, spell_radius) * 2.0 / $spell_area.normal.get_size())
				$spell_area.set_position($spell_area.normal.get_size() * $spell_area.scale / -2.0)
				$sight/distance.shape.set_radius(spell_radius)
		TYPES.BASH, TYPES.CLEAVE, TYPES.HEMORRHAGE, TYPES.OVERPOWER, TYPES.DEVASTATE:
			effect_on_target = true
			if type == TYPES.OVERPOWER:
				attack_table = {"hit":90,"critical":100,"dodge":100, "parry":100}
		TYPES.PIERCING_SHOT:
			ignore_armor = true
		TYPES.PRECISE_SHOT:
			attack_table = {"hit":90,"critical":100,"dodge":100, "parry":100}
	if spell_range > 32:
		attack_table = Stats.attack_table.ranged
	else:
		attack_table = Stats.attack_table.melee
	.make()

func unmake() -> void:
	set_process(false)
	if not caster.npc:
		caster.spell_queue.erase(self)
		var osb: TextureRect = caster.igm.get_node(@"c/osb")
		if is_in_group(str(osb.get_instance_id())):
			remove_from_group(str(osb.get_instance_id()))
		if osb.get_node(@"m/cast").is_connected("pressed", self, "_on_spell_area_cast"):
			osb.get_node(@"m/cast").disconnect("pressed", self, "_on_spell_area_cast")
		if caster.spell == self:
			caster.spell = null
	.unmake()

func configure_spell() -> void:
	caster.set_state(caster.STATES.IDLE)
	if type == TYPES.VOLLEY:
		caster.set_process(false)
		caster.get_node(@"timer").set_block_signals(true)
		caster.get_node(@"anim").connect("animation_finished", self, "volley")
		caster.get_node(@"anim").play("attacking", -1, 1.5)
	else:
		match sub_type:
			SUB_TYPES.DAMAGE_MODIFIER:
				caster.weapon_range = spell_range
			SUB_TYPES.CASTING:
				caster.get_node(@"anim").play("cast")
			SUB_TYPES.CHOOSE_AREA_EFFECT:
				var osb: TextureRect = caster.igm.get_node(@"c/osb")
				osb.set_position(Vector2(0.0, 180.0))
				$sight/distance.set_disabled(false)
				for other_spell in get_tree().get_nodes_in_group(str(osb.get_instance_id())):
					other_spell.unmake()
				add_to_group(str(osb.get_instance_id()))
				caster.get_node(@"tween").connect("tween_started", self, "unmake_if_caster_moved")
				osb.get_node(@"m/cast").connect("pressed", self, "_on_spell_area_cast")
				osb.get_node(@"m/cast/label").set_text("Cast")
				osb.show()
				set_global_position(caster.get_global_position())
				$spell_area.show()
				set_process(true)

func configure_snd() -> void:
	match type:
		TYPES.FIREBALL, TYPES.SHADOW_BOLT, TYPES.FROST_BOLT:
			globals.play_sample("%s_cast" % world_name, caster.get_node(@"snd"))

#---End main methods---
#---Support Functions---

func set_time(time: float, set_duration: bool=true) -> void:
	if not loaded:
		$timer.set_wait_time(time)
	if set_duration:
		duration = time
	$timer.start()

func set_type(value):
	.set_type(value)
	make()

func set_count(value):
	if not loaded:
		count = value

func set_data(value):
	if not data:
		if loaded:
			if typeof(value) == TYPE_ARRAY:
				for v in value:
					if typeof(v) == TYPE_STRING:
						value.insert(value.find(v), get_node(v))
						value.erase(v)
				data = value
			elif typeof(value) == TYPE_STRING:
				data = globals.get_node(value)
			elif typeof(value) == TYPE_DICTIONARY:
				if value.has("x") and value.has("y"):
					data = Vector2(value.x, value.y)
					set_global_position(data)
				else:
					data = value
			else:
				data = value
		else:
			data = value

func get_data():
	if typeof(data) == TYPE_ARRAY:
		var ddata: Array = data.duplicate()
		for m in ddata:
			if typeof(m) == TYPE_OBJECT:
				ddata.insert(ddata.find(m), m.get_path())
				ddata.erase(m)
		return ddata
	elif typeof(data) == TYPE_OBJECT:
		return data.get_path()
	elif typeof(data) == TYPE_VECTOR2:
		return {"x":data.x, "y":data.y}
	else:
		return data

#---End Support Functions---

#---Melee---

func devastate() -> float:
	set_data(caster.target)
	return 1.1

func intimidating_shout() -> float:
	if loaded:
		for unit in data:
			globals.get_node(unit).min_damage -= data[unit][0]
			globals.get_node(unit).max_damage -= data[unit][1]
	else:
		set_data({})
#		for unit in $choose_area_effect.get_overlapping_areas():
#			unit = unit.caster
#			if unit != null:
#				if unit.get_class() == "KinematicBody2D" and not unit.get("dead") and ((not caster.get("npc") and unit.get("enemy")) or (caster.get("enemy") != unit.get("enemy"))):
#					var modified = [int(round(unit.min_damage * 0.20)), int(round(unit.max_damage * 0.20))]
#					data[unit.get_path()] = modified
#					unit.min_damage -= modified[0]
#					unit.max_damage -= modified[1]
	set_time(3.0)
	return 1.0

func cleave() -> float:
	set_data(caster.target)
	return 1.15

func fortify() -> float:
	set_data(int(round(caster.armor * 0.25)))
	caster.armor += data
	set_time(60.0)
	if loaded:
		caster.set_spell(self, duration - $timer.wait_time)
	else:
		caster.set_spell(self, 0.0)
	return 1.0

func bash() -> float:
	set_data(caster.target)
	data.set_process(false)
	data.get_node(@"timer").stop()
	data.get_node(@"img").set_frame(0)
	set_time(5.0)
	return 1.1

func hemorrhage() -> float:
	set_count(5)
	set_data(caster.target)
	set_time(12.0)
	return 1.05

func stomp() -> float:
	if loaded:
		for unit in data:
			unit = globals.get_node(unit)
			unit.set_process(false)
			unit.get_node(@"timer").stop()
			unit.get_node(@"img").set_frame(0)
	else:
		## this here because code below gives error that I don't want to fix yet.
		set_data([])
		for unit in $choose_area_effect.get_overlapping_areas():
			unit = unit.caster
			if unit == null:
				continue
			elif not unit.get("dead") and \
			((not caster.get("npc") and unit.get("enemy")) or (caster.get("enemy") != unit.get("enemy"))):
				unit.take_damage(10, "hit", caster)
				if randi() % 100 + 1 > 50:
					unit.set_process(false)
					unit.get_node(@"timer").stop()
					unit.get_node(@"img").set_frame(0)
					data.append(unit)
	set_time(3.0)
	return 1.0

func overpower() -> float:
	set_data(caster.target)
	return 1.15

func frenzy() -> float:
	set_data([int(round(caster.max_vel * 0.1)),
			int(round(caster.weapon_speed * 0.1)),
			caster.anim_speed * 0.2])
	caster.max_vel += data[0]
	caster.weapon_speed += data[1]
	caster.anim_speed += data[2]
	set_time(30.0)
	return 1.0

#---Ranged---

func searing_arrow() -> float:
	set_count(2)
	set_data(caster.target)
	set_time(12.0)
	return 1.05

func concussive_shot() -> float:
	set_data([caster.target,
	int(round(caster.target.max_vel * 0.5)),
	int(round(caster.target.weapon_speed * 0.5))])
	data[0].max_vel -= data[1]
	data[0].weapon_speed -= data[2]
	set_time(10.0)
	return 1.1

func piercing_shot() -> float:
	return 1.05

func stinging_shot() -> float:
	set_count(5)
	set_data(caster.target)
	set_time(3.0)
	return 1.2

func explosive_arrow() -> float:
	# make area damage here
	return 1.1

func precise_shot() -> float:
	return 1.1

func sniper_shot() -> float:
	return 1.15

func explosive_trap() -> float:
	var loaded_mine: Resource = load("res://src/misc/missile/land_mine.scn")
	var land_mine: LandMine = loaded_mine.instance()
	land_mine.excluded_unit = caster
	land_mine.set_global_position(caster.get_global_position())
	land_mine.add_to_group(str(caster.get_instance_id()) + "-lm")
	caster.get_parent().add_child(land_mine)
	return 1.0

func volley(anim_name: String = "") -> float:
	var anim: AnimationPlayer = caster.get_node(@"anim")
	if data != null:
		if caster.get_center_pos().distance_to(data.get_center_pos()) <= caster.weapon_range:
			count -= 1
			if count > 0:
				anim.play("attacking", -1, 1.50)
				return 1.0
		caster.get_node(@"timer").set_block_signals(false)
		caster.set_process(true)
		unmake()
	else:
		if not loaded:
			caster.mana -= mana_cost
		set_count(3)
		set_data(caster.target)
		anim.play("attacking", -1, 1.5)
	return 1.0

#---Magic---

func fireball() -> float:
	set_count(2)
	set_data(caster.target)
	set_time(12.0)
	return 1.05

func shadow_bolt() -> float:
	return 1.12

func frost_bolt() -> float:
	set_data([caster.target,
	int(round(caster.target.max_vel * 0.5)),
	int(round(caster.target.weapon_speed * 0.5))])
	data[0].max_vel -= data[1]
	data[0].weapon_speed -= data[2]
	set_time(10.0)
	return 1.1

func rejuvenate() -> float:
	caster.set_hp(caster.hp * rand_range(1.1, 1.3))
	return 1.0

func siphon_mana() -> float:
	var mana: int = int(round(caster.target.mana * 0.2))
	caster.target.set_mana(-mana)
	caster.set_mana(mana)
	var txt: CombatText = globals.combat_text.instance()
	txt.type = "mana"
	if mana + caster.mana > caster.mana_max:
		mana -= mana + caster.mana - caster.mana_max
	txt.set_text("+%s" % mana)
	caster.add_child(txt)
	return 1.0

func haste() -> float:
	set_data([int(round(caster.max_vel * 0.10)), caster.anim_speed * 0.20])
	caster.max_vel += data[0]
	caster.anim_speed += data[1]
	set_time(30.0)
	return 1.0

func slow() -> float:
	set_data([caster.target,
	int(round(caster.target.max_vel * 0.50)),
	int(round(caster.target.weapon_speed * 0.50))])
	data[0].max_vel -= data[1]
	data[0].weapon_speed -= data[2]
	set_time(10.0)
	return 1.0

func lightning_bolt() -> float:
	return 1.0

func mind_blast() -> float:
	return 1.2

func meteor(hit: bool=false) -> float:
	if not hit:
		var ctrans: Transform2D = get_canvas_transform()
		var min_pos: Vector2 = -ctrans.get_origin() / ctrans.get_scale()
		var max_pos: Vector2 = min_pos + get_viewport_rect().size / ctrans.get_scale()
		var side: float = 0.75
		var loaded_effect: Resource = load("res://src/spell/effects/meteor.tscn")
		var effect = loaded_effect.instance()
		effect.seek_pos = get_global_position()
		if effect.seek_pos.x > 0.50 * (max_pos.x - min_pos.x) + min_pos.x:
			side = 0.25
		effect.set_global_position(Vector2(side * (max_pos.x - min_pos.x) + min_pos.x, min_pos.y))
		effect.connect("renamed", self, "meteor")
		caster.get_parent().add_child(effect)
		effect.set_owner(caster.get_parent())
	else:
		var damage: float = rand_range(caster.min_damage, caster.max_damage) * 1.2
		for body in data:
			body.take_damage(damage, "hit", caster)
		unmake()
	return 1.0
