extends Node
class_name LandMine

var excluded_unit#: Character = null
export (int) var min_damage: int = 0
export (int) var max_damage: int = 10

func _on_timer_timeout() -> void:
	if $img/explode.is_visible():
		queue_free()
	else:
		explode()

func _on_body_entered(body) -> void:
	#check if land mine or something else here
	if body != excluded_unit and not body.dead and not $img/explode.is_visible():
		explode()

func explode() -> void:
	if not $img/explode.is_visible():
		$img/snd.play()
		$img/explode.show()
		for particle in $img/explode.get_children():
			particle.set_emitting(true)
		for body in $img/combustible.get_overlapping_bodies():
			if not body.dead:
				body.take_damage(rand_range(min_damage, max_damage), "hit", self)
		for explosive_stuff in $img/combustible.get_overlapping_areas():
			if explosive_stuff.get_name() == "combustible":
				explosive_stuff.get_owner().explode()
		$tween.interpolate_property($img, @":self_modulate", $img.get_self_modulate(), \
		Color(1.0, 1.0, 1.0, 0.0), 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		$tween.start()
		$timer.set_wait_time(5.0)
		$timer.start()
