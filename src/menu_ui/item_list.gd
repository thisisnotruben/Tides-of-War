extends GridContainer
class_name Bag

export (bool) var allow_cooldown: bool = true
export (int) var ITEM_MAX: int = 25

signal on_item_selected(index, sifting)

func _ready() -> void:
	for x in ITEM_MAX - get_child_count():
		x = load("res://src/menu_ui/item_slot.tscn")
		add_child(x.instance())
	for slot in get_children():
		slot.connect("slot_selected", self, "on_slot_selected")
		slot.connect("stack_size_changed", self, "on_stack_size_changed")
		for other_slot in get_children():
			if slot != other_slot:
				slot.connect("cooldown", other_slot, "cool_down")

func on_slot_selected(index: int) -> void:
	emit_signal("on_item_selected", index, false)

func on_stack_size_changed(item_name: String, slot_size: int, item_slot: Slot) -> void:
	for slot in get_used_slots(true):
		if slot.get_item().world_name == item_name and slot.get_item(true).size() < slot_size:
			item_slot.set_item(slot.get_item())
			remove_item(slot.get_index(), false, false, true)
			return

func add_item(item: Pickable, stack: bool=true) -> void:
	var curr_slot: Slot
	for slot in get_children():
		if not slot.get_item():
			slot.set_item(item)
			curr_slot = slot
			break
		elif item.stack_size > 0 and item.world_name == slot.get_item().world_name and slot.stacking and stack:
			if not slot.stack_size == slot.get_item(true).size():
				slot.set_item(item)
				curr_slot = slot
				break
	if curr_slot and allow_cooldown and not curr_slot.get("is_cooling_down"):
		# add cooldown to current slot, if similar items are cooling down from bag
		for slot in get_used_slots():
			var oitm: Pickable = slot.get_item()
			if oitm.world_name == item.world_name and oitm != item and slot.is_cooling_down:
				curr_slot.cool_down(oitm, oitm.get_initial_time(), oitm.get_time_left())
				return
		# add cooldown to current slot, if similar items don't exist in bag, but in HUD
		for oitm in get_owner().hp_mana.get_node(@"m/h/p/h/g").get_children():
			oitm = oitm.get_item()
			if oitm:
				if oitm.world_name == item.world_name:
					curr_slot.cool_down(oitm, oitm.get_initial_time(), oitm.get_time_left())
					return

func remove_item(index: int, shuffle: bool=true, bypass: bool=false, funnel: bool=false) -> void:
	get_child(index).set_item(null, shuffle, bypass, funnel)

func clear() -> void:
	for slot_idx in get_child_count():
		remove_item(slot_idx, false, true)

func get_items(count_stack: bool=false) -> Array:
	var items: Array = []
	for slot in get_children():
		if slot.get_item():
			var itm: Pickable = slot.get_item(true)
			if typeof(itm) == TYPE_ARRAY and count_stack:
				for stacked_itm in itm:
					items.append(stacked_itm)
			else:
				items.append(itm)
	return items

func get_item_metadata(index: int) -> Item:
	return get_child(index).get_item()

func set_slot_cool_down(index: int, time, seek) -> void:
	get_child(index).cool_down(get_child(index).get_item(), time, seek)

func get_item_count() -> int:
	var count: int = 0
	for slot in get_children():
		if slot.get_item():
			count += 1
	return count

func is_cooling_down(index: int) -> bool:
	return get_child(index).is_cooling_down

func get_item_slot(find_itm: Pickable, index: bool=false):
	for slot in get_children():
		var itm = slot.get_item(true)
		if typeof(itm) == TYPE_ARRAY:
			for stacked_itm in itm:
				if stacked_itm == find_itm:
					return slot.get_index() if index else slot
		elif itm == find_itm:
			return slot.get_index() if index else slot

func get_used_slots(stacked_slots: bool=false) -> Array:
	var used_slots: Array = []
	for slot in get_children():
		if not slot.get_item():
			continue
		elif (slot.stacking and stacked_slots) or !stacked_slots:
			used_slots.append(slot)
	return used_slots

func has_item(item: Pickable) -> bool:
	for itm in get_items(true):
		if itm == item:
			return true
	return false
