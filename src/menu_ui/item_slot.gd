extends TextureButton
class_name Slot

signal slot_selected(index)
signal stack_size_changed(slot, world_name, size)
signal cooldown(time, seek)
signal sync_slot(slot, value)
signal shortcut_pressed(slot, itm)

var is_cooling_down: bool = false
var stacking: bool = false
var item setget set_item, get_item
var time: int = 0
var stack_size: int = 0

func _on_item_slot_pressed() -> void:
	if item and get_tree().is_paused():
		emit_signal("slot_selected", get_position_in_parent())

func _on_shortcut_pressed() -> void:
	if item:
		emit_signal("shortcut_pressed", self, get_item())

func _on_item_slot_button_down() -> void:
	$m/icon.set_scale(Vector2(0.8, 0.8))

func _on_item_slot_button_up() -> void:
	$m/icon.set_scale(Vector2(1.0, 1.0))

func _on_tween_tween_completed(object: Object, key: NodePath) -> void:
	if is_disabled():
		set_item(null, false, true)
		hide()
	move_child($count, 2)
	is_cooling_down = false
	$m/label.hide()
	$m/icon/overlay.set_scale(Vector2(1.0, 1.0))

func _on_tween_tween_step(object: Object, key: NodePath, elapsed: float, value: Object) -> void:
	if is_cooling_down:
		$m/label.set_text(str(round(time - elapsed)))
		if not $m/label.is_visible():
			$m/label.show()

func _on_label_draw() -> void:
	$m/icon/overlay.show()

func _on_label_hide() -> void:
	$m/icon/overlay.hide()

func _on_sync_shortcut(slot: Slot, value: Pickable) -> void:
	set_item(value, false)
	if not item:
		slot.disconnect("sync_slot", self, "_on_sync_shortcut")

func set_item(value: Pickable, shuffle: bool=true, overide: bool=false, funnel: bool=false) -> void:
	if not value:
		emit_signal("sync_slot", self, value)
		if typeof(item) == TYPE_ARRAY and not overide:
			item.remove(0)
			$count.set_text(str(item.size()))
			if item.size() == 1:
				$count.hide()
			elif item.empty():
				$m/icon.set_texture(null)
			elif not funnel:
				emit_signal("stack_size_changed", get_item()[0].world_name, item.size(), self)
		else:
			$m/icon.set_texture(null)
		if not $m/icon.get_texture():
			set_normal_texture(load("res://asset/img/ui/brown_bg_icon.res"))
			for link in get_signal_connection_list("sync_slot"):
				disconnect("sync_slot", link.target, "_on_sync_shortcut")
			is_cooling_down = false
			stacking = false
			item = null
			stack_size = 0
			$count.hide()
			$m/label.hide()
			$tween.stop_all()
			$m/icon/overlay.set_scale(Vector2(1.0, 1.0))
			if shuffle:
				get_parent().move_child(self, get_parent().get_child_count() - 1)
	else:
		var tex: String = "res://asset/img/ui/%s.res"
		if is_connected("pressed", self, "_on_shortcut_pressed"):
			tex = tex % "black_bg_icon_used0"

		else:
			tex = tex % "black_bg_icon_used1"
		if get_normal_texture().get_path() != tex:
			set_normal_texture(load(tex))
		$m/icon.set_texture(value.icon)
		if value.stack_size > 0:
			if typeof(item) != TYPE_ARRAY:
				stack_size = value.stack_size
				stacking = true
				item = [value]
			else:
				$count.show()
				item.append(value)
				$count.set_text(str(item.size()))
		else:
			$tween.stop_all()
			stacking = false
			stack_size = 0
			$count.hide()
			item = value

func get_item(bypass: bool=false):
	if typeof(item) == TYPE_ARRAY and not bypass:
		return item[0]
	return item

func cool_down(itm: Pickable, value, seek) -> void:
	if item and not is_cooling_down and itm and value > 0.0 and value != seek:
		if get_item().world_name == itm.world_name:
			is_cooling_down = true
			time = value
			$m/label.set_text(str(round(value)))
			$tween.interpolate_property($m/icon/overlay, @":rect_scale",\
			Vector2(1.0, 1.0), Vector2(0.0, 1.0), time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			move_child($count, 0)
			$m/label.show()
			$tween.start()
			if seek > 0.0:
				$tween.seek(seek)
			emit_signal("cooldown", get_item( ), value, seek)