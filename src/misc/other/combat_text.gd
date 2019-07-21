"""
In-game floating text, determines the color and placement of text.
"""

extends Node2D
class_name CombatText

var type: String = ""

const TIME: float = 1.1

signal queue

func _ready() -> void:
#	Center text amongst character
	var center_pos: Vector2 = get_parent().get_node(@"img").get_position()
	center_pos.x = -$label.get_size().x / 2.0
	center_pos.y -= 8.0
#	Chooses text color amongst type of text
	var color1: Color =  Color(1.0, 1.0, 1.0, 0.5)
	var color2: Color =  Color(1.0, 1.0, 1.0, 0.0)
	match $label.get_text():
		"Dodge", "Parry", "Miss":
			set_modulate(Color(1.0, 1.0, 1.0, 1.0))
	match type:
		"xp":
			set_modulate(Color(0.502, 0.0, 0.502, 1.0))
		"gold":
			set_modulate(Color(1.0, 1.0, 0.0, 1.0))
		"critical":
			color1 = Color(1.0, 1.0, 1.0, 1.0)
			color2 = Color(1.0, 1.0, 1.0, 1.0)
		"mana":
			set_modulate(Color(0.0, 0.686, 1.0, 1.0))
#	Set chosen parameters to self
	$tween.interpolate_property(self, @":position", center_pos,\
	 Vector2(center_pos.x, center_pos.y - 14.0), TIME, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$tween.interpolate_property($label, @":modulate", \
	color1, color2, TIME, Tween.TRANS_LINEAR, Tween.EASE_IN)
#	Queue text animation amongst other text animations
	var node_above: Node = get_parent().get_child(get_index() - 1)
	if "combat_text" in node_above.get_name():
		node_above.connect("queue", self, "start")
	else:
		start()

func start() -> void:
	"""Start the text animation"""
	if not $tween.is_active():
		$tween.start()
		$anim.play("label_fade")
		yield($anim, "animation_finished")
		emit_signal("queue")
		queue_free()

func queue() -> void:
	emit_signal("queue")

func set_text(value: String) -> void:
	$label.set_text(value)