extends "res://src/character/character.gd"

signal pos_changed

onready var igm = $in_game_menu
onready var move_cursor = preload("res://src/menu_ui/move_cursor.tscn")

var _reserved_path = PoolVector2Array()
var weapon = null
var vest = null
var gold = 5000 setget set_gold, get_gold
var xp = 0 setget set_xp

func _init():
	npc = false

func _ready() -> void:
	globals.player = self
	set_img("res://asset/img/character/human/spear-swing_medium-17.png")
	emit_signal("update_hud", "name", self, world_name, null)
	emit_signal("update_hud", "hp", self, hp, hp_max)
	emit_signal("update_hud", "mana", self, mana, mana_max)

func _unhandled_input(event) -> void:
	if event is InputEventScreenTouch or Input.is_action_just_pressed("ui_click"):
		if not event.is_pressed() or event.is_echo():
			return
		event = get_global_mouse_position()
		if globals.current_scene.is_valid_move(event):
			if state == STATES.MOVING and path and $tween.is_active():
				var _path = globals.current_scene.get_apath(get_global_position(), event)
				if _path[0] != path[0]:
					$tween.remove(self, "global_position")
				else:
					_path.remove(0)
				path = _path
				_reserved_path = globals.current_scene.reset_path(_reserved_path)
				set_process(true)
			else:
				path = globals.current_scene.get_apath(get_global_position(), event)
			emit_signal("pos_changed")
			var cursor = move_cursor.instance()
			cursor.add_to_map(self, event)

func _process(delta: float) -> void:
	if path:
		set_state(STATES.MOVING)
		move_to(path[0])
		return
	elif target:
		if target.enemy and get_center_pos().distance_to(target.get_center_pos()) <= weapon_range:
			set_state(STATES.ATTACKING)
			return
	set_state(STATES.IDLE)

func _on_anim_finished(anim_name: String) -> void:
	if anim_name == "attacking" and spell:
		match weapon_type:
			"bow", "magic":
				weapon_range = 64
			_:
				weapon_range = 32
	elif anim_name == "cast":
		set_process(true)

func move_to(target_position: Vector2) -> void:
	var direction = get_direction(target_position)
	if direction:
		target_position = globals.current_scene.request_move(get_global_position(), direction)
		$ray.look_at(target_position)
		if target_position:
			_reserved_path.append(target_position)
			.move_to(target_position)
			path.remove(0)
		elif $ray.is_colliding():
#			path = globals.current_scene.get_apath(get_global_position(), target_position)
			path = PoolVector2Array()
	else:
		path.remove(0)

func attack(attack_table: Dictionary=Stats.attack_table.melee, ignore_armor: bool=false) -> void:
	.attack(attack_table, ignore_armor)
	if weapon:
		weapon.take_damage()

func take_damage(amount, type, foe, ignore_armor=false) -> void:
	.take_damage(amount, type, foe, ignore_armor)
	if vest:
		vest.take_damage()
	if dead:
		if vest:
			vest.take_damage(true)
		if weapon:
			weapon.take_damage(true)

func set_state(value) -> void:
	if state == value:
		return
	match value:
		STATES.IDLE:
			$anim.stop()
			$img.set_frame(0)
			$img.set_flip_h(false)
			set_time(regen_time)
		STATES.MOVING:
			$img.set_flip_h(false)
			$anim.play("moving", -1, anim_speed)
			$anim.seek(0.3, true)
		STATES.ATTACKING:
			set_state(STATES.IDLE)
			set_time(weapon_speed, true)
		STATES.DEAD:
			set_dead(true)
		STATES.ALIVE:
			set_dead(false)
	.set_state(value)

func set_target(value):
	if target:
		target.disconnect("update_hud", igm, "update_hud")
		match target.get_type():
			"TRAINER":
				target.prep_items(igm, false, true)
			"MERCHANT":
				target.prep_items(igm, false, false)
	if value:
		igm.hp_mana.get_node(@"h/u").show()
		value.connect("update_hud", igm, "update_hud")
		value.update_hud()
		match value.get_type():
			"TRAINER":
				value.prep_items(igm, true, true)
			"MERCHANT":
				value.prep_items(igm, true, false)
	else:
		igm.hp_mana.get_node(@"h/u").hide()
	target = value

func set_xp(value, show_label=true, loaded=false):
	xp += int(round(value))
	if xp > Stats.MAX_XP:
		xp = Stats.MAX_XP
	elif xp > 0 and xp != Stats.MAX_XP and show_label:
		var text = globals.combat_text.instance()
		text.type = "xp"
		text.set_text("+%s" % globals.add_comma(value))
		add_child(text)
	var _level = Stats.level_check(xp)
	if level != _level and level < Stats.MAX_LEVEL:
		level = _level
		if not loaded:
			globals.play_sample("level_up")
		if level > Stats.MAX_LEVEL:
			level = Stats.MAX_LEVEL
		var _stats = Stats.unit_make(level, Stats.get_multiplier($img, npc))
		for stat in _stats:
			set(stat, _stats[stat])

func set_gold(value):
	gold += int(value)

func get_gold():
	return gold

func set_dead(value: bool) -> void:
	if dead == value:
		return
	.set_dead(value)
	if dead:
		yield($anim, "animation_finished")
#		spawn a grave to where you died and set the map veil
		var grve = globals.grave.instance()
		grve.set_grave(self, world_name, get_instance_id())
		origin = grve.get_global_position()
		globals.current_scene.set_veil()
		path = PoolVector2Array()
		if get_tree().has_group("gravesite"):
#			search the nearest gravesite in map and spawn to it
			var gravesites: Dictionary = {}
			for grave in get_tree().get_nodes_in_group("gravesite"):
				gravesites[get_global_position().distance_to(grave.get_global_position())] = grave.get_global_position()
			var min_val: float = gravesites.keys()[0]
			for grave in range(1, gravesites.size()):
				min_val = min(min_val, gravesites.keys()[grave])
			set_global_position(globals.current_scene.get_grid_position(gravesites[min_val]))
		set_process_unhandled_input(true)
		set_process(true)
	else:
		set_hp(hp_max * rand_range(Stats.HP_MANA_RESPAWN_LOWER_LIMIT, 1.0))
		set_mana(mana_max * rand_range(Stats.HP_MANA_RESPAWN_LOWER_LIMIT, 1.0))
		origin = Vector2()

func get_save_game():
	var save_dict = {
		"world_name" : world_name,
		"xp" : xp,
		"gold" : gold
#		"light" : $img/light.is_visible()
	}
	if dead:
		save_dict["origin"] = {"x": origin.x, "y": origin.y}
	return globals.merge_dict(.get_save_game(), save_dict)

func set_save_game(data):
	.set_save_game(data)
	for attribute in data:
		match attribute:
			"xp":
				set_xp(data[attribute], false, true)
			"light":
				if data[attribute]:
					$img/light.show()
			"origin":
				set_state(STATES.DEAD)
				get_parent().get_node("%s-%s" % [world_name, get_instance_id()]) \
				.set_global_position(Vector2(data[attribute].x, data[attribute].y))
			"state":
				pass
			"target":
				set_target(globals.get_node(data[attribute]))
			_:
				set(attribute, data[attribute])
