"""
Handles the tomb that allows the player to revive.
"""
extends Node2D
class_name Grave

var deceased: Character

func _ready() -> void:
	deceased.igm.get_node(@"c/osb/m/cast").connect("pressed", self, "revive")
	deceased.igm.get_node(@"c/osb").set_position(Vector2(0.0, 180.0))
	deceased.igm.get_node(@"c/osb/m/cast/label").set_text("Revive")
	set_global_position(deceased.get_global_position())

func _on_deceased_area_entered(area: Area2D) -> void:
	if area.get_owner() == deceased:
		deceased.igm.get_node(@"c/osb").show()

func _on_deceased_area_exited(area: Area2D) -> void:
	if area.get_owner() == deceased:
		deceased.igm.get_node(@"c/osb").hide()

func set_grave(unit: Character, unit_name: String, unit_id: int) -> void:
	deceased = unit
	set_name("%s-%s" % [unit_name, unit_id])
	unit.get_parent().add_child(self)

func revive() -> void:
	globals.play_sample("click2")
	$img/area.set_block_signals(true)
	deceased.igm.get_node(@"c/osb").hide()
	deceased.igm.get_node(@"c/osb/m/cast").disconnect("pressed", self, "revive")
	globals.current_scene.set_veil(false)
	deceased.set_state(deceased.STATES.ALIVE)
	$tween.interpolate_property(self, @":modulate", get_modulate(), \
	Color(1.0, 1.0, 1.0, 0.0), 0.75, Tween.TRANS_CIRC, Tween.EASE_OUT)
	$tween.start()
	yield($tween, "tween_completed")
	queue_free()