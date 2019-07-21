"""
Class for determining day/light and queues sun up/down animation
"""

extends Timer
class_name DayTime

const LENGTH_OF_DAY: float = 210.0

func _ready() -> void:
	if is_stopped():
		start()

func _on_day_time_timeout() -> void:
	if globals.day_night:
		$anim.play("sun_up_down")
		globals.day_night = false
	else:
		$anim.play_backwards("sun_up_down")
		globals.day_night = true

func _on_anim_animation_finished(anim_name: String) -> void:
	if get_wait_time() != LENGTH_OF_DAY:
#		this is used when map is loaded from save file
		set_wait_time(LENGTH_OF_DAY)
	start()

func trigger_lights() -> void:
	"""Turns on/off all the lights in scene
	from sun/up down animation"""
	for light in get_tree().get_nodes_in_group("lights"):
		if globals.day_night:
			if light.is_class("Light2D"):
				light.hide()
			else:
				light.stop()
		else:
			if light.is_class("Light2D"):
				light.show()
			else:
				light.start()

func set_save_game(data: Dictionary) -> void:
	globals.day_night = data.day_night
	if not data.timer_stopped:
		if not data.day_night:
			$anim.play("sun_up_down")
			$anim.seek($anim.get_current_animation_length(), true)
		set_wait_time(data.time_of_day)
		start()
	else:
		if data.day_night:
			$anim.play_backwards("sun_up_down")
		else:
			$anim.play("sun_up_down")
		$anim.seek(data.anim_pos, true)

func get_save_game() -> Dictionary:
	var save_dict: Dictionary = {"day_night" : globals.day_night, "timer_stopped": is_stopped()}
	if not save_dict.timer_stopped:
		save_dict.time_of_day = get_time_left()
	else:
		save_dict.anim_pos = $anim.get_current_animation_position()
	return save_dict