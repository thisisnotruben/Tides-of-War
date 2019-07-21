extends HBoxContainer
class_name QuestEntry

var quest: Quest setget set_quest, get_quest

func add_to_quest_log(quest_log) -> void:
	quest_log.get_node(@"s/v/s/v").add_child(self)
	quest_log.get_node(@"s/v/s/v").move_child(self, 0)

func set_quest(value: Quest) -> void:
	$label.set_text(value.quest_name)
	set_name(value.quest_name)
	quest = value

func get_quest() -> Quest:
	return quest

func _on_quest_slot_pressed() -> void:
	globals.player.igm.show_quest_text(quest)