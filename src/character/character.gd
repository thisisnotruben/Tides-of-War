"""
Abstract class for units in game
"""

extends Node2D
class_name Character

enum TYPES {QUEST_GIVER, QUEST_RECEIVER, MERCHANT, COMMONER, WARRIOR, HEALER, TRAINER, PLAYER}
enum WEAPON_TYPES {AXE, BOW, CLUB, DAGGER, SWORD}
enum STATES {IDLE, ATTACKING, MOVING, RETURNING, DEAD, ALIVE}
var type: int = TYPES.WARRIOR setget set_type, get_type
var weapon_type = WEAPON_TYPES.SWORD
var state: int = STATES.IDLE setget set_state, get_state
var swing_type: String = ""
export var world_name: String = ""
var origin: Vector2 = Vector2()
var path: PoolVector2Array = PoolVector2Array()
var npc: bool = true
var dead: bool = false
var target setget set_target
var spell#: Spell
var weapon_speed: float = 1.3
var weapon_range: int = 32
var anim_speed: float = 1.0
var stamina: int = 0
var agility: int = 0
var intellect: int = 0
var regen_time: int = 60
var min_damage: int = 0
var max_damage: int = 0
var armor: int = 0
var hp_max: int = 0
var mana_max: int = 0
var level: int = 5 setget set_level
var hp: int = 0 setget set_hp
var mana: int = 0 setget set_mana
var spell_queue = [] setget set_spell
var buffs: Dictionary = {"pending":[], "active":[]}
var target_list: Dictionary = {}

export var DEBUG: bool = false

signal update_hud(type, who, value1, value2)
signal died()
signal talk()

#---Start of private methods---

func _ready() -> void:
	$ray.add_exception($area)
	connect("talk", world_quests, "update_quest_unit", [self])
	connect("died", world_quests, "update_quest_unit", [self])
	randomize()


func _on_tween_completed(object: Object, key: NodePath) -> void:
	if object.get_scale() != Vector2(1.0, 1.0):
#		Reverts to original scale when unit is clicked on
		$tween.interpolate_property(object, key, object.get_scale(), \
		Vector2(1.0, 1.0), 0.5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		$tween.start()
	elif $tween.get_pause_mode() == PAUSE_MODE_PROCESS:
#		Condition when merchant/trainer are selected to let their
#		animation run through it's course when game is paused
		$tween.set_pause_mode(PAUSE_MODE_INHERIT)
	elif key == ":global_position":
#		When unit is done making a move, this allows him to move again
		set_process(true)

func _on_timer_timeout() -> void:
	if dead:
#		when NPC reaches spawn time
#		ceases all other operations for player
		if npc:
			set_state(STATES.ALIVE)
	elif state == STATES.ATTACKING:
		if target and not dead and not target.get("dead"):
#			horizontally flips sprite according to enemy position
			var missile_pos: Vector2 = $img/missile.get_position()
			if target.get_global_position().x - get_global_position().x > 0:
				$img.set_flip_h(false)
				missile_pos.x = abs(missile_pos.x)
			else:
				$img.set_flip_h(true)
				missile_pos.x = abs(missile_pos.x) * -1
			$img/missile.set_position(missile_pos)
			$anim.play("attacking", -1, anim_speed)
	else:
#		when not fighting, unit regenerates health/mana
		var regen_amount: int = Stats.hp_mana_regen(level, Stats.get_multiplier($img, npc))
		set_hp(regen_amount)
		set_mana(regen_amount)

func _on_select_pressed() -> void:
#	abstract method
	pass

#---End of private methods---
#---Start of setter/getter methods---

func set_target(value) -> void:
	target = value

func set_level(value) -> void:
	level = int(clamp(value, 0.0, Stats.MAX_LEVEL))
	var _stats: Dictionary = Stats.unit_make(level, Stats.get_multiplier($img, npc))
	for stat in _stats:
		set(stat, _stats[stat])

func set_hp(value) -> void:
	hp += int(round(value))
	if hp >= hp_max:
		hp = hp_max
		if npc and spell_queue.empty() and is_in_group("save"):
			remove_from_group("save")
	elif hp <= 0:
		hp = 0
		set_state(STATES.DEAD)
	elif npc and not is_in_group("save"):
		add_to_group("save")
	if hp > 0 and dead:
		set_state(STATES.ALIVE)
	emit_signal("update_hud", "hp", self, hp, hp_max)

func set_mana(value) -> void:
	mana += int(round(value))
	if mana >= mana_max:
		mana = mana_max
		if npc and spell_queue.empty() and is_in_group("save"):
			remove_from_group("save")
	elif npc and not is_in_group("save"):
		add_to_group("save")
	if mana < 0:
		mana = 0
	emit_signal("update_hud", "mana", self, mana, mana_max)

func set_spell(value, seek: float=0.0) -> void:
	"""Sets unit with a spell casted and removes duplicate spells"""
	for spll in spell_queue:
#		Remove duplicate spells unit has, and replace with freshest one
		if spll.world_name == value.world_name:
			spll._on_timer_timeout()
	spell_queue.append(value)
	emit_signal("update_hud", "icon", self, value, seek)

func set_dead(value: bool) -> void:
	dead = value
	$area.set_collision_layer_bit(globals.collision.CHARACTERS, not dead)
	$area.set_collision_layer_bit(globals.collision.DEAD_CHARACTERS, dead)
	if dead:
#		play death animation
		emit_signal("died")
		set_process(false)
		set_target(null)
		$tween.remove_all()
		$timer.stop()
		$anim.play("dying")
		set_process_unhandled_input(false)
		path = PoolVector2Array()
		yield($anim, "animation_finished")
#		reset sprite and turn into a 'ghost' once animation is finished
		$img.set_frame(0)
		$img.set_flip_h(false)
		$img.set_modulate(Color(1.0, 1.0, 1.0, 1.0))
		set_modulate(Color(1.0, 1.0, 1.0, 0.8))
#		set hp and mana to 0
		if hp > 0:
			set_hp(-hp_max)
		set_mana(-mana_max)
#		clear all current spells and combat texts
		for spll in spell_queue:
			spll._on_timer_timeout()
		for node in get_children():
			if node.is_in_group("combat_text"):
				node.queue_free()
	else:
#		$area/body.set_disabled(true)
#		$area/body.set_disabled(false)
		set_modulate(Color(1.0, 1.0, 1.0, 1.0))
		set_time(regen_time)
		for area in $sight.get_overlapping_areas():
			var world_object = area.get_owner()
			if world_object.get("npc"):
				world_object.check_sight($area)

func set_time(value: float=0.0, one_shot: bool=false) -> void:
	"""One method to reset and start timer"""
	if value > 0.0:
		$timer.stop()
		$timer.set_wait_time(value)
		$timer.set_one_shot(one_shot)
		$timer.start()

func set_buff(buff_pool: Array=buffs.pending, seek: float=0.0) -> void:
	for buff in buff_pool:
		if seek == 0.0:
#			Add buff animation if buff is just consumed (not loaded)
			var buff_anim: BuffAnim = globals.buff_anim.instance()
			buff_anim.item = buff
			buff_anim.set_name(str(buff.get_instance_id()))
			buff.connect("unmake", buff_anim, "queue_free")
			$img.add_child(buff_anim)
#		start buff duration
		buff.get_node(@"timer").start()
		for current_buff in buffs.active:
#			remove duplicate elixirs and use the most current one
			if current_buff.get_sub_type(true) == buff.get_sub_type(true) \
			and not "potion" in buff.world_name.to_lower():
				current_buff.configure_buff(self, true)
		if buff.get_sub_type() != "HEALING" and buff.get_sub_type() != "MANA":
#			add cooldown icon to HUD
			emit_signal("update_hud", "icon", self, buff, seek)
		buffs.active.append(buff)
		buff_pool.erase(buff)

func set_type(value) -> void:
	if typeof(value) == TYPE_STRING:
		type = TYPES[value.to_upper()]
	else:
		type = int(value)

func get_type(get_int: bool=false):
	if get_int:
		return type
	return globals.get_enum_key(TYPES, type)

func set_state(value):
	if typeof(value) == TYPE_STRING:
		state = STATES[value.to_upper()]
	else:
		state = int(value)

func get_state(get_str: bool=false):
	if get_str:
		return globals.get_enum_key(STATES, state)
	return state

#---End of setter/getter methods---

func get_center_pos() -> Vector2:
	"""Returns the center of the img position"""
	return $img.get_global_position()

func on_foot_step(value: bool) -> void:
	"""Places footstep markings on map"""
	if not dead:
		var footprint: FootStep = globals.footstep.instance()
		var step: Vector2 = get_global_position()
		step.y -= 3
		if value:
			step.x += 1
		else:
			step.x -= 4
		footprint.pos = step
		globals.current_scene.get_node(@"ground").add_child(footprint)

func move_to(target_position: Vector2) -> void:
	"""main method for unit movement"""
	$tween.stop_all()
	set_process(false)
	$tween.interpolate_property(self, @":global_position", get_global_position(), target_position, \
	get_global_position().distance_to(target_position) / 16 * 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$tween.start()

func get_direction(pos: Vector2) -> Vector2:
	"""return (inter)cardinal direction from unit to arguement"""
	var self_pos: Vector2 = globals.current_scene.get_grid_position(get_global_position())
	pos = globals.current_scene.get_grid_position(pos)
	var direction: Vector2 = Vector2()
	if self_pos.x > pos.x:
		direction.x = -1
	elif self_pos.x < pos.x:
		direction.x = 1
	if self_pos.y > pos.y:
		direction.y = -1
	elif self_pos.y < pos.y:
		direction.y = 1
	return direction

func bump(direction: Vector2) -> void:
	"""Animation when being strucked"""
	set_process(false)
	$tween.interpolate_property(self, @":global_position", get_global_position(), get_global_position() + direction, \
	get_global_position().distance_to(get_global_position() + direction) / 10, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	$tween.start()
	yield($tween, "tween_completed")
	var grid_pos: Vector2 = globals.current_scene.get_grid_position(get_global_position())
	$tween.interpolate_property(self, @":global_position", get_global_position(), \
	grid_pos, grid_pos.distance_to(get_global_position()) / 10, Tween.TRANS_ELASTIC, Tween.EASE_IN)
	$tween.start()
	yield($tween, "tween_completed")
	set_process(true)

func cast() -> void:
	"""cast animation calls this method"""
	if spell:
		path = PoolVector2Array()
		set_process(false)
		spell.cast()
		yield($anim, "animation_finished")
		$img.set_frame(0)
		set_process(true)

func attack(attack_table: Dictionary=Stats.attack_table.melee, ignore_armor: bool=false) -> void:
	if target and not dead and not target.get("dead"):
		var snd_idx: int = randi() % globals.weapon_type[weapon_type]
		var play_sound: bool = true
		if weapon_type == "bow" or weapon_type == "magic":
			var missile = globals.missile.instance() ###: Missile
			get_parent().add_child(missile)
			missile.set_global_position($img/missile.get_global_position())
			missile.user = self
			if spell:
				if not spell.casted:
					spell.configure_snd()
					missile.spell = spell
					set_mana(-spell.mana_cost)
					spell.mana_cost = 0
			missile.make()
			if spell:
				if missile.has_node(spell.get_name()):
					play_sound = missile.get_node(spell.get_name()).play_sound
			missile.add_to_group(str(get_instance_id()) + "-m")
			missile.set_target(target)
			if play_sound:
				globals.play_sample("%s%s" % [weapon_type, snd_idx])
		else:
			var dice_roll: int = randi() % 100 + 1
			var damage: float = rand_range(min_damage, max_damage)
			var snd: String = ""
			if spell:
				if not spell.casted:
					if dice_roll <= attack_table.critical:
						target.set_spell(spell)
						ignore_armor = spell.ignore_armor
						damage *= spell.cast()
						if has_node(spell.spell_name):
							play_sound = get_node(spell.spell_name).play_sound
					else:
						set_mana(-spell.mana_cost)
						spell.unmake()
			if dice_roll <= attack_table.hit:
				target.take_damage(damage, "hit", self, ignore_armor)
				snd = weapon_type + str(snd_idx)
			elif dice_roll <= attack_table.critical:
				target.take_damage(damage * 2, "critical", self, ignore_armor)
				snd = weapon_type + str(snd_idx)
			elif dice_roll <= attack_table.dodge and not target.is_class("StaticBody2D"):
				target.take_damage(0, "dodge", self)
				snd = swing_type + str(randi() % 3)
			elif dice_roll <= attack_table.parry and target.weapon_type != "bow" \
			and not target.is_class("StaticBody2D"):
				target.take_damage(0, "parry", self)
				var materials: Array = [["sword", "axe", "dagger"], ["club", "staff", "claw"]]
				if materials[0].has(target.weapon_type) and materials[0].has(weapon_type):
					snd = "block_metal_metal" + str(randi() % 5)
				elif materials[1].has(target.weapon_type) and materials[1].has(weapon_type):
					snd = "block_wood_wood" + str(randi() % 3)
				else:
					snd = "block_metal_wood" + str(randi() % 3)
			else:
				target.take_damage(0, "miss", self)
				snd = swing_type + str(randi() % 3)
			if play_sound:
				globals.play_sample(snd)
		$timer.start()
	$img.set_frame(0)

func take_damage(amount, type: String, foe, ignore_armor: bool=false) -> void:
	amount = int(round(clamp(amount, 0.0, abs(amount))))
	if not ignore_armor:
		amount -= armor
	if state != STATES.ATTACKING:
#		this is to stop regeneration when being attacked
		$timer.stop()
	if not foe.get("npc"):
		if target_list.keys().has(foe):
			target_list[foe] += amount
		else:
			target_list[foe] = amount
	if npc and not foe.npc or !npc:
		var text: CombatText = globals.combat_text.instance()
		if amount > 0:
			text.set_text("-%s" % amount)
			text.type = type
		else:
			match type:
				"dodge", "miss", "parry":
					text.set_text(type.capitalize())
		add_child(text)
	set_hp(-amount)
	if not dead and amount > 0 and (state == STATES.ATTACKING or state == STATES.IDLE):
		bump(get_direction(foe.get_global_position()).rotated(PI) / 4)

func get_save_game() -> Dictionary:
	var save_dict: Dictionary = {
		"hp" : -(hp_max - hp),
		"mana" : -(mana_max - mana),
		"state" : state,
		"dead" : dead,
		"path" : Array(path),
		"anim_pos" : 0.0,
		"missiles" : [],
		"land_mines":[],
		"cspells" : [],
		"timer" : $timer.get_time_left(),
		"img_flip_h" : $img.is_flipped_h(),
		"current_anim" : $anim.get_current_animation(),
		"global_pos":{
			"x" : get_global_position().x,
			"y" : get_global_position().y}
	}
	for missile in get_tree().get_nodes_in_group(str(get_instance_id()) + "-m"):
		var dict: Dictionary = {"spell":missile.spell, "target":missile.target.get_path(),
		"global_pos":{
			"x" : missile.get_global_position().x,
			"y" : missile.get_global_position().y}}
		if missile.spell:
			dict["spell"] = missile.spell.get_type(true)
		save_dict["missiles"].append(dict)
	for land_mine in get_tree().get_nodes_in_group(str(get_instance_id()) + "-lm"):
		save_dict["land_mines"].append({"excluded_unit":land_mine.excluded_unit.get_path(),
		"time_left":land_mine.get_node(@"timer").get_time_left(),
		"global_pos":{
			"x":land_mine.get_global_position().x,
			"y":land_mine.get_global_position().y}})
	for cspell in spell_queue:
		save_dict["cspells"].append({"time":cspell.get_time_left(),
		"data":cspell.get_data(),"type":cspell.get_type(true),"count":cspell.count})
	for buff_status in buffs:
		for buff in buffs[buff_status]:
			var dict: Dictionary = {"type":buff.get_type(true), "sub_type":buff.get_sub_type(true),
			"level":buff.get_level(),"time":buff.get_time_left(),"buff_status":buff_status}
			if dict.time == buff.get_initial_time():
				dict.time = 0
			save_dict.buffs.append(dict)
	if $anim.is_playing():
		save_dict["anim_pos"] = $anim.get_current_animation_position()
	if target:
		save_dict["target"] = target.get_path()
	return save_dict

func set_save_game(data: Dictionary) -> void:
	for attribute in data:
		match attribute:
			"global_pos":
				set_global_position(Vector2(data[attribute].x, data[attribute].y))
			"path":
				set(attribute, PoolVector2Array(data[attribute]))
			"img_flip_h":
				$img.set_flip_h(data[attribute])
			"missiles":
				for missile_dict in data[attribute]:
					var missile = globals.missile.instance() ### :Missile
					get_parent().add_child(missile)
					missile.set_global_position(Vector2(missile_dict["global_pos"].x, missile_dict["global_pos"].y))
					missile.user = self
					var mspell#####: Spell
					if missile_dict["spell"]:
						mspell = globals.spell.instance()
						mspell.loaded = true
						mspell.set_type(missile_dict["spell"])
						mspell.get_obj(self, false)
					missile.set_spell(mspell)
					missile.add_to_group(str(get_instance_id()) + "-m")
					missile.set_target(globals.get_node(missile_dict["target"]))
			"land_mines":
				for lm_dict in data[attribute]:
					var loaded_mine: Resource = load("res://src/misc/missile/land_mine.tscn")
					var land_mine: LandMine = loaded_mine.instance()
					land_mine.set_global_position(Vector2(lm_dict["global_pos"].x, lm_dict["global_pos"].y))
					land_mine.excluded_unit = globals.get_node(NodePath(lm_dict["excluded_unit"]))
					land_mine.get_node(@"timer").set_wait_time(lm_dict["time_left"])
					land_mine.add_to_group(str(get_instance_id()) + "-lm")
					get_parent().add_child(land_mine)
			"cspells":
				for cspell in data[attribute]:
					var spll = globals.spell.instance ### : Spell
					spll.loaded = true
					spll.set_type(cspell.type)
					spll.count = cspell.count
					spll.set_data(cspell.data)
					spll.get_obj(self, false)
					spll.get_node(@"timer").set_wait_time(cspell.time)
					spll.cast()
					set_spell(spll, spll.duration - cspell.time)
			"state":
				if data["current_anim"] == "dying":
					$anim.play("dying")
					$anim.seek(data["anim_pos"], true)
				elif data.has("target"):
					set_target(globals.get_node(NodePath(data["target"])))
					set_state(data[attribute])
					if state == STATES.ATTACKING and data["current_anim"] == "attacking":
						$anim.seek(data["anim_pos"], true)
					elif state == STATES.IDLE:
						$timer.set_wait_time(data["timer"])
			"buffs":
				for buff in data[attribute]:
					var _buff: Item = globals.item.instance()
					_buff.set_type(buff.type)
					_buff.set_sub_type(buff.sub_type)
					_buff.set_level(buff.level)
					_buff.get_obj(get_owner(), false)
					_buff.consume(get_owner(), buff.time)
			"target":
				if not npc:
					set_target(globals.get_node(NodePath(data[attribute])))

func set_img(value: String, loaded: bool=false) -> void:
	var race: String = value.get_base_dir().get_file()
	if not $img.get_texture() or value != $img.get_texture().get_path():
		$img.set_texture(load(value))
	var parsed_img: PoolStringArray = value.get_file().get_basename().split('-')
	if parsed_img[0] == "comm":
		$img.set_hframes(int(parsed_img[2]))
		type = TYPES.COMMONER
	else:
		var idx: int = 0
		if race == "critter":
			idx = 1
		if parsed_img[idx] != "null":
			weapon_type = parsed_img[idx].to_lower()
			match weapon_type:
				"sickle", "magic":
					weapon_type = "dagger"
				"hatchet", "spear":
					weapon_type = "sword"
				"staff", "mace", "rock":
					weapon_type = "club"
				"bow":
					weapon_range = 64
#				"flail", "rock":
#					pass
		swing_type = parsed_img[idx + 1]
		$img.set_hframes(int(parsed_img[idx + 2]))
		if $img.get_hframes() != 17:
			$anim.remove_animation("attacking")
			$anim.add_animation("attacking", \
			load("res://asset/img/character/resource/attacking_%sf.res" % parsed_img[idx + 2]))
	value = value.get_file().get_basename()
	var body_type: String = race
	if race == "human":
		match $img.get_hframes():
			20, 16, 10:
				body_type += "_unarmored"
			_:
				body_type += "_armored"
	elif race == "critter":
		body_type = value.split('-')[0]
	if not npc:
		type = TYPES.PLAYER
	var tex: Resource = load("res://asset/img/character/resource/%s_body.res" % body_type)
	$select.set_texture(tex)
	var target_bttn: Vector2 = tex.get_region().size
	$img.set_position(Vector2(0.0, -$img.get_texture().get_height() / 2.0))
	$head.set_position(Vector2(0.0, -$select.get_texture().get_height()))
	$select.set_position(Vector2(-target_bttn.x / 2.0, -target_bttn.y))
	$area/body.set_position(Vector2(-0.5, -target_bttn.y / 2.0))
	$sight/distance.set_position($area/body.get_position())
	var _stats: Dictionary = Stats.unit_make(level, Stats.get_multiplier($img, npc))
	for stat in _stats:
		set(stat, _stats[stat])
	set_time(regen_time)
	if not loaded:
		set_hp(hp_max)
		set_mana(mana_max)
