extends Node
class_name Quest

var quest_giver: NodePath setget set_quest_giver
var objective: Dictionary

var quest_name: String setget set_quest_name
var quest_start: String
var quest_active: String
var quest_completed: String
var quest_delivered: String
var receiver_completed: String
var receiver_delivered: String

var keep_items: bool

var gold: int setget set_gold, get_gold
var reward setget set_reward, get_reward

func set_quest_giver(value: NodePath) -> void:
	quest_giver = "/root".plus_file(value)

func set_quest_name(value: String) -> void:
	quest_name = value
	set_name(value)
	_load_text()

func _load_text() -> void:
	"""Fetches dialogue file and loads it appropriat"""
	var file = XMLParser.new()
	if file.open("res://meta/dialogue/%s.xml" % quest_name) == OK:
		while file.read() == OK:
			if file.get_node_type() == file.NODE_ELEMENT:
				var var_name: String
				match file.get_node_name():
					"start":
						var_name = "quest_start"
					"active":
						var_name = "quest_active"
					"completed":
						var_name = "quest_completed"
					"delivered":
						var_name = "quest_delivered"
					"r_completed":
						var_name = "receiver_completed"
					"r_delivered":
						var_name = "receiver_delivered"
				if not var_name.empty() and file.read() == OK:
					var text: String = file.get_node_data()
					text = text.replace("\n        ", " ").replace("  ", " ").strip_edges()
					set(var_name, text)
	else:
		print("Error: couldn't open %s.xml dialogue file." % quest_name)

func set_reward(value: Dictionary) -> void:
	var pickable: Pickable
	if value.has_all(["type", "sub_type", "level"]):
		pickable = globals.item.instance()
	elif value.has("type"):
		pickable = globals.spell.instance()
	for attribute in value:
		pickable.set(attribute, value[attribute])
	reward = pickable

func get_reward() -> Pickable:
	return reward

func set_save_game(data: Dictionary):
	pass

func get_save_game():
	var dict: Dictionary = {}
	return dict

func set_gold(value) -> void:
	gold = int(value)

func get_gold() -> int:

	return gold

func is_part_of(world_object: Node2D) -> bool:
	return objective.has(world_object.world_name)

func check_quest(world_object: Node2D) -> bool:
	"""Updates quest, world_object can be a Pickable/Character object"""
	var key_content = objective[world_object.world_name]
	match typeof(key_content):
		TYPE_ARRAY:
			if key_content.size() == 3 and key_content[2].has(world_object.get_path()):
#					this is for quests where generic units cannot be spoken to twice
#					and still count towards quest goal.
				(world_object as Character).set_text(receiver_delivered)
			elif key_content[0] < key_content[1]:
				key_content[0] += 1
				if key_content.size() == 3:
					(world_object as Character).set_text(receiver_completed)
					key_content[2].append(world_object.get_path())
		TYPE_DICTIONARY:
#				This is only for character units only
			if key_content.has("amount") \
			and key_content["amount"][0] < key_content["amount"][1]:
				key_content["amount"][0] += 1
			elif key_content.has_all(["spoken", "unit_path"]) \
			and world_object.get_path() == NodePath(key_content["unit_path"]):
				if key_content["spoken"]:
					(world_object as Character).set_text(receiver_delivered)
				else:
					(world_object as Character).set_text(receiver_completed)
					key_content["spoken"] = true
#				if key_content.has("item"):
#					drop item here
	return _is_completed()

func _is_completed() -> bool:
	"""Checks if quest is completed, doesn't finish it"""
	var quest_completion_tracker: int = 0
	for task in objective:
		var key_content = objective[task]
		match typeof(key_content):
			TYPE_ARRAY:
				if key_content[0] == key_content[1]:
					quest_completion_tracker += 1
			TYPE_DICTIONARY:
				if key_content.has("amount") \
				and key_content["amount"][0] == key_content["amount"][1]:
					quest_completion_tracker += 1
				elif key_content.has("spoken") and key_content["spoken"]:
					quest_completion_tracker += 1
	return quest_completion_tracker == objective.size()

func change_state(state: String) -> void:
	if has_node(quest_giver):
		match state:
			"available":
				get_node(quest_giver).set_text(quest_start)
			"active":
				get_node(quest_giver).set_text(quest_active)
			"completed":
				get_node(quest_giver).set_text(quest_completed)
			"delivered":
				get_node(quest_giver).set_text(quest_delivered)

func get_state() -> String:
	return get_parent().get_name()

func format_with_objective_text() -> String:
	var quest_completion_tracker: int = 0
	var format: String = "%s: %s/%s\n"
	var text: String = ""
	for world_name in objective:
		var key_content = objective[world_name]
		match typeof(key_content):
			TYPE_ARRAY:
				text += format % [world_name, key_content[0], key_content[1]]
			TYPE_DICTIONARY:
				if key_content.has("amount"):
					text += format % [world_name, key_content["amount"][0], key_content["amount"][1]]
				elif key_content.has("spoken"):
					text += format % [world_name, 1 if key_content["spoken"] else 0, 1]
#	removes the last newline characters
	text.erase(text.length() - 2, 2)
	text = "--Quest Objective--\n" + text
	text = quest_start.insert(quest_start.find("--Rewards--"), text)
	return text


