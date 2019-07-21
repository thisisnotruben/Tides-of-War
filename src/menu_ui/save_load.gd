"""
UI controller for save/load menu, septerate so that start_menu/igm can instance this.
"""
extends Container
class_name SaveLoad

func _ready():
	set_labels()
	if get_owner().get_name() == "start_menu":
		$v/label.set_text("Load Game")

func _on_back_pressed():
	get_owner()._on_back_pressed()

func _on_slot_pressed(index):
	get_owner().popup.save_load_go(index)

func set_labels():
	for x in $v/s/c/g.get_child_count() / 2:
		var slot_text: String = "slot_" + str(x)
		if globals.game_meta.has(slot_text):
			if globals.game_meta[slot_text]:
				get_node("v/s/c/g/slot_label_%s" % x).set_text(globals.game_meta[slot_text])
