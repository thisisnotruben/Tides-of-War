"""
Chooses animation color based on potion/elixir,
and deletes itself when done with animation.
"""

extends Particles2D
class_name BuffAnim

var elixir: bool = true
var item: Item

func _ready() -> void:
	var color: Color = Color(1.0, 1.0 , 1.0, 1.0)
	match item.get_sub_type():
		"HEALING":
			color = Color(1.0, 0.0, 0.0, 1.0)
			elixir = false
		"MANA":
			color = Color(0.0, 0.455, 0.663, 1.0)
			elixir = false
		"STAMINA":
			color = Color(0.647, 0.165, 0.165, 1.0)
		"INTELLECT":
			color = Color(0.502, 0.0, 0.502, 1.0)
		"AGILITY":
			color = Color(0.0, 1.0 ,0.0, 1.0)
		"STRENGTH":
			color = Color(1.0, 1.0, 0.0, 1.0)
		"DEFENSE":
			color = Color(0.5, 0.5, 0.5, 1.0)
	($buff_after_effect as Particles2D).set_modulate(color)
	set_modulate(color)
	set_emitting(true)

func _on_timer_timeout() -> void:
	queue_free()
