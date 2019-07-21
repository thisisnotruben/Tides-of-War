extends "res://src/character/character.gd"

var patrol_path: PoolVector2Array = PoolVector2Array()
var patroller: bool = false
var engaging: bool = false
export var enemy: bool = true
var bbcode: String = ""  setget set_text

signal drop_loot(unit, spawn_pos, gold)

func _ready():
	set_process(false)

func _process(delta):
	if engaging and target:
		if get_center_pos().distance_to(target.get_center_pos()) > 96 or target.dead:
			set_state(STATES.RETURNING)
			if patroller:
				if get_global_position() != patrol_path[-1]:
					move_to(patrol_path) # find a way to inrigate this
					return
			elif get_global_position() != origin:
				move_to(origin)
				return
			set_state(STATES.IDLE)
		elif not $anim.has_animation("attacking"):
			set_state(STATES.MOVING) # flee
		elif get_center_pos().distance_to(target.get_center_pos()) > weapon_range:
			set_state(STATES.MOVING)
			move_to(target.get_global_position())
		else:
			set_state(STATES.ATTACKING)
	elif patroller:
		set_state(STATES.MOVING)
		move_to(patrol_path)
	else:
		set_state(STATES.IDLE)

func _on_sight_area_entered(area):
	area = area.get_owner()
	if not dead and (not target or area.dead):
		if not engaging and not area.npc and not enemy:
			$select.show()
		elif enemy != area.get("enemy"):
			if not enemy and not area.npc:
				return
			set_target(area)
			engaging = true
			set_process(true)

func _on_sight_area_exited(area):
	area = area.get_owner()
	if not engaging:
		set_target(null)
		if not area.npc:
			$select.hide()

func _on_area_mouse_entered():
	globals.player.set_process_unhandled_input(false)

func _on_area_mouse_exited():
	globals.player.set_process_unhandled_input(true)

func _on_select_pressed() -> void:
	if globals.player.target == self:
		globals.player.set_target(null)
	elif not globals.player.dead:
		$tween.interpolate_property($img, @":scale", $img.get_scale(), \
		Vector2(1.03, 1.03), 0.5, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
		$tween.start()
		globals.player.set_target(self)
		update_hud()
		if not enemy and not engaging:
			if type == TYPES.MERCHANT or type == TYPES.TRAINER:
				$tween.set_pause_mode(PAUSE_MODE_PROCESS)
				if type == TYPES.MERCHANT:
					globals.play_sample("merchant_open")
					globals.player.igm.merchant.get_node(@"s/v2/inventory").show()
					for item in $inventory.get_children():
						item.setup_shop(false)
				else:
					globals.play_sample("turn_page")
					globals.player.igm.merchant.get_node(@"s/v2/inventory").hide()
					for item in $spells.get_children():
						item.setup_shop(false)
				globals.player.igm.item_info.get_node(@"s/v/c/v/bg").set_disabled(true)
				globals.player.igm.merchant.get_node(@"s/v/label").set_text(world_name)
				globals.player.igm.merchant.get_node(@"s/v/label2").set_text("Gold: %s" % globals.add_comma(globals.player.gold))
				globals.player.igm.menu.hide()
				globals.player.igm.merchant.show()
				globals.player.igm.get_node(@"c/game_menu").show()
			else:
				emit_signal("talk")
				if bbcode.empty():
					return
				globals.play_sample("turn_page")
				globals.player.igm.menu.hide()
				if type == TYPES.HEALER:
					globals.player.igm.dialogue.get_node(@"s/s/v/heal").show()
				else:
					globals.player.igm.dialogue.get_node(@"s/s/label2").set_text(bbcode)
				globals.player.igm.dialogue.get_node(@"s/label").set_text(world_name)
				globals.player.igm.dialogue.show()
				globals.player.igm.get_node(@"c/game_menu").show()
			globals.player.path = PoolVector2Array()
			return
		globals.play_sample("click4")

func move_to(target_position):
	if not path or path[-1].distance_to(target_position) > weapon_range:
		path = globals.current_scene.get_apath(get_global_position(), target_position)
	else:
		var direction = get_direction(path[0])
		if direction:
			target_position = globals.current_scene.request_move(get_global_position(), direction)
			if target_position:
				.move_to(target_position)
				path.remove(0)
				set_process(false)
			else:
				path = PoolVector2Array()
		else:
			path.remove(0)

func take_damage(amount, type, foe, ignore_armor=false):
	if not target:
		set_target(foe)
	.take_damage(amount, type, foe, ignore_armor)
	if dead and not target_list.empty():
		var most_dam = target_list[target_list.keys()[0]]
		for unit in target_list:
			if target_list[unit] > most_dam:
				most_dam = target_list[unit]
		for unit in target_list:
			if target_list[unit] == most_dam and not unit.npc:
				var _xp = stats.unit_death_xp(level, stats.get_multiplier($img, npc), foe.level)
				if _xp > 0:
					unit.set_xp(_xp)

func update_hud():
	emit_signal("update_hud", "name", self, world_name, null)
	emit_signal("update_hud", "hp", self, hp, hp_max)
	emit_signal("update_hud", "mana", self, mana, mana_max)
	emit_signal("update_hud", "icon_hide", self, null, null)
	for spell in spell_queue:
		emit_signal("update_hud", "icon", self, spell, spell.get_time_left())

func set_dead(value: bool) -> void:
	if dead == value:
		return
	.set_dead(value)
	yield($anim, "animation_finished")
	$sight/distance.set_disabled(value)
	if dead:
		emit_signal("drop_loot", self, get_global_position(), 0)
		hide()
		set_process(false)
		set_time(rand_range(60.0, 240.0), true)
		if not is_in_group("save"):
			add_to_group("save")
		set_global_position(origin)
	else:
		set_hp(hp_max)
		set_mana(mana_max)
		set_process(true)
		if is_in_group("save"):
			remove_from_group("save")
		show()
		$tween.interpolate_property($img, @":scale", $img.get_scale(), \
		Vector2(1.03, 1.03), 0.5, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
		$tween.start()

func check_sight(area: Area2D) -> void:
	_on_sight_area_entered(area)

func set_state(value, bypass: bool=false) -> void:
	if value == state and not bypass:
		return
	match value:
		STATES.IDLE:
			set_process(false)
			$anim.stop()
			set_target(null)
			$img.set_flip_h(false)
			$img.set_frame(0)
			set_time(regen_time)
			$sight/distance.set_disabled(true)
			$sight/distance.set_disabled(false)
			engaging = false
		STATES.ATTACKING:
			set_time(weapon_speed / 2.0, true)
		STATES.MOVING:
			$img.set_flip_h(false)
			$anim.play("moving", -1, anim_speed)
			$anim.seek(0.3, true)
		STATES.RETURNING:
			set_state(STATES.MOVING, true)
			set_time(regen_time)
		STATES.DEAD:
			if target and not target.npc:
				target.set_target(null)
			set_state(STATES.IDLE, true)
			set_dead(true)
	.set_state(value)

func set_text(text: String) -> void:
	if "%s" in text and type == TYPES.HEALER:
		bbcode = bbcode % stats.healer_cost(globals.player.level)
	else:
		bbcode = text

func prep_items(player_menu, connect, trainer):
	var node = $inventory
	if trainer:
		node = $spells
	for itm in node.get_children():
		if connect:
			itm.connect('set_in_menu', player_menu, '_on_set_obj_in_menu')
			itm.connect('describe_object', player_menu, '_on_describe_object')
		else:
			itm.disconnect('set_in_menu', player_menu, '_on_set_obj_in_menu')
			itm.disconnect('describe_object', player_menu, '_on_describe_object')

func get_save_game() -> Dictionary:
	var save_dict = {
	"patrol_path" : Array(patrol_path),
	"target_list" : {}
	}
	for unit in target_list:
		save_dict["target_list"][unit.get_path()] = target_list[unit]
	return globals.merge_dict(.get_save_game(), save_dict)

func set_save_game(data: Dictionary) -> void:
	if data.dead and data.timer > 0.0:
		set_state(STATES.DEAD)
		set_time(data.timer, true)
	else:
		.set_save_game(data)
		for attribute in data:
			match attribute:
				"patrol_path":
					set(attribute, PoolVector2Array(data[attribute]))
				"target_list":
					for unit in data[attribute]:
						target_list[globals.get_node(NodePath(unit))] = data[attribute][unit]
				"state":
					set_state(data[attribute])
				"target":
					set_target(globals.get_node(data[attribute]))
				_:
					set(attribute, data[attribute])