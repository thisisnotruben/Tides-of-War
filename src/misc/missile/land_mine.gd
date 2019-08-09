extends Node
class_name LandMine

var excluded_unit_area: Area2D
export (int) var min_damage: int = 0
export (int) var max_damage: int = 10
var exploded: bool = false
var _units_in_blast_distance: Array = []

func _ready() -> void:
	$img/body.connect("combust", self, "explode")

func _on_timer_timeout() -> void:
	explode()

func _on_affected_area_entered(area: Area2D):
	if area != excluded_unit_area and area.get_collision_layer() == globals.collision.CHARACTERS:
		explode()

func _on_tween_completed(object, key):
	queue_free()

func explode() -> void:
	if exploded:
		return

	exploded = true
	$img/snd.play()

	for particle in $img/explode.get_children():
		particle.set_emitting(true)

	for area in $img/affected_area.get_overlapping_areas():
		var layer: int = area.get_collision_layer()

		if layer == globals.collision.CHARACTERS and area != excluded_unit_area:
			var damage: int = int(rand_range(min_damage, max_damage))
			area.get_owner().take_damage(damage, "hit", excluded_unit_area.get_owner())
		elif layer == globals.collision.COMBUSTIBLE and area != self:
			area.combust()

	$tween.interpolate_property($img, @":self_modulate", $img.get_self_modulate(), \
	Color(1.0, 1.0, 1.0, 0.0), 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$tween.start()