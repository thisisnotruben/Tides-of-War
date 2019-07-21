extends Node2D
class_name TargetDummy

var target: Character = null
var attacking: bool = false
var dead: bool = false
var enemy: bool = true
var npc: bool = true
var weapon_type: String = "club"
var weapon_speed: int = 0
var max_vel: int = 100
var mana: int = 100
var hp: int = 100
var hp_max: int = 100
var mana_max: int = 100

signal update_hud(type, who, value1, value2)

func _on_select_pressed() -> void:
	if globals.player.target == self:
		globals.player.set_target(null)
	else:
		globals.play_sample("click4")
		$tween.interpolate_property($img, @":scale", $img.get_scale(), \
		Vector2(1.03, 1.03), 0.5, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
		$tween.start()
		target = globals.player
		globals.player.set_target(self)
		emit_signal("update_hud", "name", self, "Target Dummy", null)
		emit_signal("update_hud", "hp", self, hp_max, hp_max)
		emit_signal("update_hud", "mana", self, mana_max, mana_max)

func _on_tween_completed(object, key) -> void:
	if object.get_scale() != Vector2(1.0, 1.0):
		$tween.interpolate_property(object, key, object.get_scale(), \
		Vector2(1.0, 1.0), 0.5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		$tween.start()

func get_center_pos() -> Vector2:
	return $img.get_global_position()

func take_damage(amount, type, foe, ignore_armor: bool=false) -> void:
	if foe == target:
		if target.target == self:
			amount = int(round(clamp(amount, 0.0, amount)))
			var text: CombatText = globals.combat_text.instance()
			if amount > 0:
				text.set_text("-%s" % amount)
				text.type = type
			elif ["dodge", "miss", "parry"].has(type):
				text.set_text(type.capitalize())
			add_child(text)
		else:
			target = null

