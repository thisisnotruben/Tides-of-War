extends Node2D
class_name Pickable

enum TYPES {CLEAVE, BASH, HEMORRHAGE, INTIMIDATING_SHOUT, FRENZY, STOMP, FORTIFY, OVERPOWER,
DEVASTATE, SEARING_ARROW, CONCUSSIVE_SHOT, SNIPER_SHOT, EXPLOSIVE_ARROW, PRECISE_SHOT,
PIERCING_SHOT, VOLLEY, STINGING_SHOT, EXPLOSIVE_TRAP, FIREBALL, SHADOW_BOLT, FROST_BOLT,
DIVINE_HEAL, SIPHON_MANA, HASTE, SLOW, LIGHTNING_BOLT, MIND_BLAST, METEOR,

WEAPON, ARMOR, POTION, FOOD, MISC}

enum SUB_TYPES {CASTING, DAMAGE_MODIFIER, CHOOSE_AREA_EFFECT,

T1, T2, HEALING, MANA, STAMINA, INTELLECT, AGILITY, STRENGTH, DEFENSE,

SWORD, DAGGER, SPEAR, AXE, CLAW, MACE, STAFF, BOW}

var type = TYPES.POTION setget set_type, get_type
var sub_type = SUB_TYPES.HEALING setget set_sub_type, get_sub_type
var stack_size: int = 0
var cooldown: float = 0.0
var duration: int = 0 setget set_duration, get_duration
var gold_drop: int = 0
var level: int = 1 setget set_level, get_level
var gold: int = 0
var world_name: String = "" setget set_obj_name, get_obj_name
var obj_des: String = ""
var icon
var data setget set_data, get_data

signal describe_object(obj, obj_des)
signal set_in_menu(obj, stack)
signal unmake()
signal drop(world_object)
signal exchanged(world_object, add)

func _ready():
	connect("exchanged", world_quests, "update_quest_item")

func _on_sight_area_entered(area) -> void:
	area = area.get_owner()
	if not area:
		return
	elif not area.get("dead") and not area.get("npc"):
		$tween.interpolate_property(self, @":scale", get_scale(), \
		Vector2(1.05, 1.05), 0.5, Tween.TRANS_BOUNCE, Tween.EASE_IN)
		$snd.set_stream(globals.snd_meta.chest_open)
		$select.show()
		$tween.start()
		if $anim.is_playing() and $anim.get_current_animation() == "close_chest":
			$anim.queue("open_chest")
		else:
			$anim.play("open_chest")

func _on_sight_area_exited(area) -> void:
	area = area.get_owner()
	if not area:
		return
	elif not area.get("dead") and not area.get("npc"):
		$snd.set_stream(globals.snd_meta.chest_open)
		$select.hide()
		if $anim.is_playing() and $anim.get_current_animation() == "open_chest":
			$anim.queue("close_chest")
		else:
			$anim.play("close_chest")

func _on_select_pressed() -> void:
	if "item" in get_filename() and globals.player.igm.inventory_bag.get_item_count() == globals.player.igm.inventory_bag.ITEM_MAX:
		get_tree().set_pause(true)
		globals.player.igm.popup.get_node(@"m/error/label").set_text("Inventory\nFull!")
		globals.player.igm.popup.get_node(@"m/error").show()
		globals.player.igm.get_node(@"c/game_menu").show()
		globals.player.igm.popup.show()
	elif not $anim.is_playing():
		$select.set_block_signals(true)
		$sight.set_block_signals(true)
		emit_signal("exchanged", self, true)
		$snd.set_stream(globals.snd_meta.chest_collect)
		$anim.play("select")
		get_obj(globals.player, true)
		if gold_drop > 0:
			var text: CombatText = globals.combat_text.instance()
			text.type = "gold"
			text.set_text("+%s" % globals.add_comma(gold_drop))
			globals.player.add_child(text)
			globals.player.set_gold(gold_drop)
			gold_drop = 0

func _on_tween_completed(object: Object, key: NodePath) -> void:
	if not object.get_scale() == Vector2(1.0, 1.0):
		$tween.interpolate_property(object, key, object.get_scale(), \
		Vector2(1.0, 1.0), 0.5, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
		$tween.start()

func _on_anim_finished(anim_name: String) -> void:
	if anim_name == "select":
		$img.hide()
		set_modulate(Color(1.0, 1.0, 1.0, 1.0))

func _on_snd_finished() -> void:
	if get_pause_mode() == PAUSE_MODE_PROCESS:
		call_deferred("get_obj", get_signal_connection_list("set_in_menu")[0]["target"].get_owner(), false)
		set_pause_mode(PAUSE_MODE_INHERIT)

func _on_timer_timeout():
	pass

func describe() -> void:
	emit_signal("describe_object", self, obj_des)

func setup_shop(stack: bool=true) -> void:
	emit_signal("set_in_menu", self, stack, "merchant")

func get_obj(unit, add_to_bag: bool=true) -> void:
	if not unit.npc and not is_connected("describe_object", unit.get("igm"), "_on_describe_object"):
		connect("describe_object", unit.igm, "_on_describe_object")
		connect("set_in_menu", unit.igm, "_on_set_obj_in_menu")
		if get_filename().get_file().get_basename() == "item":
			connect("equip_self", unit.igm, "_on_equip_item")
			connect("drop", unit.igm, "_on_drop_item")
	if get_owner() == globals.current_scene and add_to_bag:
		set_pause_mode(PAUSE_MODE_PROCESS)
		emit_signal("set_in_menu", self, stack_size > 0, \
		get_filename().get_file().get_basename())
		return
	elif get_parent():
		get_parent().remove_child(self)
	else:
		$sight.set_block_signals(true)
		$select.set_block_signals(true)
	if get_filename().get_file().get_basename() == "item":
		unit.get_node(@"inventory").add_child(self)
	else:
		unit.get_node(@"spells").add_child(self)
	set_owner(unit)
	if add_to_bag:
		emit_signal("set_in_menu", self, stack_size > 0, \
		get_filename().get_file().get_basename())

func get_time_left() -> float:
	return $timer.get_wait_time() - $timer.get_time_left()

func get_initial_time() -> float:
	return $timer.get_wait_time()

func equals(other_item):
	if type == other_item.get_type(true) \
	and sub_type == other_item.get_sub_type(true) \
	and level == other_item.get_level():
		return true
	return false

func buy(buyer) -> void:
	emit_signal("exchanged", self, true)
	var loaded_obj: Resource = load(get_filename())
	var obj = loaded_obj.instance() ### Pickable
	obj.set_type(type)
	obj.set_sub_type(sub_type)
	obj.set_level(level)
	obj.get_obj(buyer, true)
	buyer.set_gold(-obj.gold)

func sell(seller) -> void:
	emit_signal("exchanged", self, false)
	seller.set_gold(gold)
	unmake()

func drop() -> void:
	emit_signal("exchanged", self, false)
	emit_signal("drop", self)
	$sight.set_block_signals(false)
	$select.set_block_signals(false)
	$img.show()

func unmake() -> void:
	emit_signal("unmake")
	queue_free()

func set_obj_name(value: String) -> void:
	world_name = value.replace("  ", " ").strip_edges().to_lower()
	set_name("%s-%s" % [world_name, get_instance_id()])

func get_obj_name() -> String:
	return world_name

func set_duration(value) -> void:
	duration = value
	if value > 0:
		$timer.set_wait_time(value)

func get_duration():
	return duration

func set_type(value):
	if typeof(value) == TYPE_STRING:
		type = TYPES[value.to_upper()]
	else:
		type = int(value)

func get_type(get_int=false):
	if get_int:
		return type
	return globals.get_enum_key(TYPES, type)

func set_sub_type(value):
	if typeof(value) == TYPE_STRING:
		sub_type = SUB_TYPES[value.to_upper()]
	else:
		sub_type = int(value)

func get_sub_type(get_int=false):
	if get_int:
		return sub_type
	return globals.get_enum_key(SUB_TYPES, sub_type)

func set_level(value):
	level = int(value)

func get_level() -> int:
	return level

func set_data(value):
	data = value

func get_data():
	return data

func make():
	pass

func uncouple_slot(slot) -> void:
	slot.disconnect("hide", self, "uncouple_slot")
	disconnect("unmake", slot, "set_item")

