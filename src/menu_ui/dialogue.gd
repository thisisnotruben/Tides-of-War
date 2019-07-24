extends "res://src/menu_ui/in_game_menu.gd"


func _on_dialogue_hide() -> void:
	dialogue.get_node(@"s/s/v/heal").hide()

func _on_heal_pressed() -> void:
	var amount: int = stats.healer_cost(get_owner().level)
	if get_owner().gold >= amount:
		globals.play_sample("sell_buy")
		get_owner().set_gold(-amount)
		get_owner().set_hp(get_owner().hp_max)
		_on_back_pressed()
	else:
		popup.get_node(@"m/error/label").set_text("Not Enough\nGold!")
		popup.get_node(@"m/error").show()
		popup.show()

func _on_finish_pressed() -> void:
	var quest: Quest = world_quests.focused_quest
	if quest.get_gold() > 0:
		globals.play_sample("sell_buy")
		get_owner().set_gold(quest.get_gold())
		var text: CombatText = globals.combat_text.instance()
		text.type = "gold"
		text.set_text("+%s" % globals.add_comma(quest.get_gold()))
		get_owner().add_child(text)
	var reward = quest.get_reward()
	if reward:
		globals.current_scene.get_node(@"zed/z1").add_child(reward)
		var pos: Vector2 = globals.current_scene. \
		get_grid_position(get_owner().get_global_position())
		reward.set_global_position(pos)
	world_quests.finish_focused_quest()
	if world_quests.focused_quest:
		dialogue.get_node(@"s/s/label2").set_text(world_quests.focused_quest.quest_start)
		dialogue.get_node(@"s/s/v/finish").hide()
		dialogue.get_node(@"s/s/v/accept").show()
	else:
		_on_back_pressed()

func _on_accept_pressed() -> void:
	globals.play_sample("quest_accept")
	world_quests.start_focused_quest()
	var qe = globals.quest_entry.instance()
	qe.add_to_quest_log(quest_log)
	qe.set_quest(world_quests.focused_quest)
	dialogue.get_node(@"s/s/v/accept").hide()
	dialogue.get_node(@"s/s/v/finish").hide()
	dialogue.hide()
	get_owner().set_target(null)
	hide_menu()

func _on_back_pressed() -> void:
	globals.play_sample("click3")
	dialogue.hide()
	if selected == quest_log:
		quest_log.show()
		selected = null
	else:
		dialogue.get_node(@"s/s/v/accept").hide()
		dialogue.get_node(@"s/s/v/finish").hide()
		hp_mana.get_node(@"h/u").hide()
		get_owner().set_target(null)
		hide_menu()