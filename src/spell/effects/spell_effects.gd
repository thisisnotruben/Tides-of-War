 """
Script to handle all the visual spell effects in the game
"""

extends Node2D
class_name SpellEffect

var effect: String
var seek_pos: Vector2 = Vector2()
export (bool) var play_sound: bool = false
export (bool) var fade_light: bool = true
export (float) var light_fade_delay: float = 0.65

signal unmake

func _ready() -> void:
#	have every child use parent material for the use of shaders
	for particle in $idle.get_children():
		particle.set_use_parent_material(true)
	for particle in $explode.get_children():
		particle.set_use_parent_material(true)
	if effect != "meteor":
		set_process(false)

func _process(delta: float) -> void:
	$tween.interpolate_property(self, @":global_position", get_global_position(), \
	seek_pos, 5.0, Tween.TRANS_CIRC, Tween.EASE_OUT)
	$tween.start()
	if get_global_position().distance_to(seek_pos) < 2:
		set_process(false)
		on_hit()

func _on_timer_timeout() -> void:
	emit_signal("unmake")
	match effect:
		"fortify", "frenzy", "intimidating_shout", "bash", "slow", "divine_heal":
#			fade out light to prepare to delete itself
			fade_light(true)
			match effect:
				"fortify", "bash", "divine_heal":
#					fade out effect entirely
					$tween.interpolate_property(self, @":modulate", get_modulate(), \
					Color(1.0, 1.0, 1.0, 0.0), 0.65,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
					$tween.start()
#			kill all particles in effect and start timer, recursive here
			for particle in $explode.get_children():
				particle.set_emitting(false)
			set_name(str(get_instance_id())) ###hmm, not sure what this does
			$timer.start()
		_:
#			deletes itself after all particles have been killed
			queue_free()

func on_hit(spell=null) -> void:
	if typeof(spell) == TYPE_OBJECT:
		effect = spell.world_name
	elif typeof(spell) == TYPE_STRING:
		effect = spell
#	play the specific preloaded sound from the effect scene
	$snd.play()
#	bounce animation when hit
	$tween.interpolate_property(self, @":scale", Vector2(0.75, 0.75), \
	Vector2(1.0, 1.0), 0.5, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	fade_light(fade_light)

#	based on the spell, configure to where is belongs
	match effect:
		"haste", "hemorrhage", "overpower", "devastate", "cleave":
			set_position((get_owner() as Character).get_node(@"img").get_position())

		"frost_bolt", "fireball", "shadow_bolt", "lightning_bolt", "siphon_mana", "meteor":
#			have the bolt fade away gradually
			$tween.interpolate_property($idle/bolt, @":modulate", $idle/bolt.get_modulate(), \
			Color(1.0, 1.0, 1.0, 0.0), 0.65,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			if effect == "siphon_mana":
				var caster: Character = get_owner()
				set_global_position(caster.target.get_center_pos())
			elif effect == "meteor":
				emit_signal("renamed", true) # not sure what this does

		"fortify", "frenzy", "bash", "divine_heal":
			set_position((get_owner() as Character).get_node(@"head").get_position())
			if effect == "frenzy":
#				moves to the back of the sprite (head)
				(get_parent() as Character).move_child(self, 0)

		"slow":
			var missile = get_owner()
			missile.set_global_position(missile.target.get_center_pos())
#			when spell ends, this effect ends as well
			spell.connect("unmake", self, "_on_timer_timeout")

		"intimidating_shout":
			set_position((get_owner() as Character).get_node(@"head").get_position() + Vector2(0.0, 6.0))

		"concussive_shot":
#			spawns the bash effect when hit, since they're very similar
			$light.show()
			var loaded_effect: Resource = load("res://src/spell/effects/bash.tscn")
			var effect: SpellEffect = loaded_effect.instance()
			var unit: Character = get_owner()
			unit.target.add_child(effect)
			effect.set_owner(unit.target)
			spell.connect("unmake", effect, "_on_timer_timeout")
			effect.get_node(@"snd").set_stream(null)
			effect.on_hit("bash")

		"mind_blast":
			var missile = get_owner()
			missile.set_global_position(missile.target.get_node(@"head").get_global_position())

		"explosive_arrow", "sniper_shot":
			$light.show()

#	start all cumulated tween animations
	$tween.start()

#	set particle animations in the persistant phase off when it hits target
	for particle in $idle.get_children():
		particle.set_emitting(false)
#	start explosion particle effects when hits target
	for particle in $explode.get_children():
		particle.set_emitting(true)

#	based on spell, start the timer
	if not (effect == "bash" or effect == "frenzy" or effect == "slow"):
		$timer.start()

func fade_light(proceed: bool=true) -> void:
	"""modulate the light gradually either on/off"""
	if proceed:
		$tween.interpolate_property($light, @":modulate", $light.get_modulate(), \
		Color(1.0, 1.0, 1.0, 0.0), light_fade_delay, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)

