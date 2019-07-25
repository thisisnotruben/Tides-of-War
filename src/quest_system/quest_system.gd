extends Node

# quests player is ready to pickup
onready var available_quests = $available

# quests player is currently doing
onready var active_quests = $active

# quests player completed, but haven't turned in yet
onready var completed_quests = $completed

# quests player delivered and is all done with
onready var delivered_quests = $delivered

var focused_quest: Quest

func _ready():
	_load_quests()

func _load_quests() -> void:
	var quest_meta: Dictionary = globals.quest_meta
	var chain_quest_queue: Dictionary

	for quest_name in quest_meta:
		var quest: Quest = Quest.new()
		if quest_meta[quest_name].has("chain_quest"):
			chain_quest_queue[quest_name] = quest_meta[quest_name]["chain_quest"]
		available_quests.add_child(quest)
		quest.set_quest_name(quest_name)
		for attr in quest_meta[quest_name]:
			quest.set(attr, quest_meta[quest_name][attr])

	for root_quest_name in chain_quest_queue:
		var root_quest = available_quests.get_node(root_quest_name)
		for quest_name in chain_quest_queue[root_quest_name]:
			var linked_quest = available_quests.get_node(quest_name)
			_move_quest(linked_quest, root_quest)
		root_quest.change_state(available_quests.get_name())

func reset() -> void:
	for quest_cat in get_children():
		for quest in quest_cat.get_children():
			quest.queue_free()
	_load_quests()

func is_focused_chained() -> bool:
	return focused_quest.get_child_count() > 0

func start_focused_quest() -> void:
	_move_quest(focused_quest, active_quests)

func finish_focused_quest() -> void:
	var linked_quest: Quest
	if is_focused_chained():
		linked_quest = focused_quest.get_child(0)
	_move_quest(focused_quest, delivered_quests)
	focused_quest = linked_quest

func update():
	for quest_cat in get_children():
		for quest in quest_cat.get_children():
			quest.change_state(quest_cat.get_name())

func update_quest_item(item, add) -> void:
	"""Searches active/completed quest nodes for quest item matches to
	parameter 'item'. If match update quest."""
	for quest_cat in [active_quests, completed_quests]:
		if quest_cat == completed_quests and add:
			break
		for quest in quest_cat.get_children():
			if quest.is_part_of(item):
				if quest.check_quest(item, add):
					_move_quest(quest, completed_quests)
				else:
					_move_quest(quest, active_quests)

func update_quest_unit(unit) -> void:
	"""Similar method as 'update_quest_item' but for units"""
	for quest in active_quests.get_children():
		if quest.is_part_of(unit) and quest.check_quest(unit):
			_move_quest(quest, completed_quests)
	for quest_cat in [available_quests, completed_quests]:
		for quest in quest_cat.get_children():
			if unit.get_path() == quest.quest_giver:
				focused_quest = quest
				if quest_cat == available_quests:
					globals.player.igm.dialogue.get_node(@"s/s/v/accept").show()
				else:
					globals.player.igm.dialogue.get_node(@"s/s/v/finish").show()
				return

func _move_quest(quest: Quest, to: Node) -> void:
	"""Determines what state the quest will be in,
	returns bool indicating whether or not there is another quest"""
	quest.get_parent().remove_child(quest)
	to.add_child(quest)
	quest.change_state(to.get_name())
	if to == delivered_quests and quest.get_child_count() > 0:
#		checks if finished quest has a chain quest and moves it
#		to available quests upon completion
		_move_quest(quest.get_child(0), available_quests)
