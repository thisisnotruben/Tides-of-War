extends Node2D
class_name FootStep

var pos: Vector2 = Vector2()

func _draw() -> void:
	draw_rect(Rect2(pos, Vector2(3.0, 3.0)), Color(0.10, 0.10, 0.10, 0.175))

func _on_timer_timeout() -> void:
	"""Has the footstep gradually fade away and then delete"""
	$tween.interpolate_property(self, @":modulate", get_modulate(), \
	Color(0.15, 0.15, 0.15, 0.0), 2.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$tween.start()
	yield($tween, "tween_completed")
	queue_free()