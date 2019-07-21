extends Control
class_name Hotkeys

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if not event.is_pressed() or event.is_echo():
			return
		var event_code: int = event.get_scancode()
		if get_tree().is_paused():
			if get_owner().menu.is_visible():
				match event_code:
					KEY_R, KEY_ESCAPE:
						get_owner()._on_resume_pressed()
					KEY_I:
						get_owner()._on_inventory_pressed()
					KEY_S:
						get_owner()._on_stats_pressed()
					KEY_Q:
						get_owner()._on_quest_log_pressed()
					KEY_A:
						get_owner()._on_about_pressed()
					KEY_L:
						get_owner()._on_save_load_pressed()
					KEY_E:
						get_owner()._on_exit_pressed()
			elif get_owner().list_of_menus.is_visible():
				if event_code == KEY_ESCAPE or event_code == KEY_B:
					if get_owner().list_of_menus.get_node(@"about").is_visible():
						get_owner().list_of_menus.get_node(@"about")._on_back_pressed()
					elif get_owner().popup.is_visible():
						if get_owner().popup.get_node(@"m/error").is_visible():
							get_owner().popup._on_okay_pressed()
						else:
							get_owner().popup._on_back_pressed()
					elif get_owner().item_info.get_node(@"s/h/v/back"). \
					is_connected("pressed", get_owner(), "hide_menu"):
						get_owner().hide_menu()
					else:
						get_owner()._on_back_pressed()
				elif get_owner().popup.get_node(@"m/save_load").is_visible():
					match event_code:
						KEY_D:
							get_owner().popup._on_delete_pressed()
						KEY_S:
							get_owner().popup._on_save_pressed()
						KEY_L:
							get_owner().popup._on_load_pressed()
				elif get_owner().popup.get_node(@"m/yes_no").is_visible():
					match event_code:
						KEY_Y:
							get_owner().popup._on_yes_pressed()
						KEY_N:
							get_owner().popup._on_no_pressed()
				elif get_owner().popup.get_node(@"m/error").is_visible():
					match event_code:
						KEY_KP_ENTER, KEY_ENTER, KEY_O:
							get_owner().popup._on_okay_pressed()
				elif get_owner().popup.get_node(@"m/exit").is_visible():
					match event_code:
						KEY_M:
							set_process_input(false)
							get_owner().popup._on_exit_menu_pressed()
						KEY_X:
							get_owner().popup._on_exit_game_pressed()
				elif get_owner().popup.get_node(@"m/filter_options").is_visible():
					match event_code:
						KEY_A:
							get_owner().popup._on_all_pressed()
						KEY_T:
							get_owner().popup._on_active_pressed()
						KEY_C:
							get_owner().popup._on_completed_pressed()
				elif get_owner().popup.get_node(@"m/add_to_slot").is_visible():
					match event_code:
						KEY_KP_1, KEY_1:
							get_owner().popup._on_slot_pressed(1)
						KEY_KP_2, KEY_2:
							get_owner().popup._on_slot_pressed(2)
						KEY_KP_3, KEY_3:
							get_owner().popup._on_slot_pressed(3)
				elif get_owner().popup.get_node(@"m/repair").is_visible():
					match event_code:
						KEY_A:
							if get_owner().popup.get_node(@"m/repair/repair_all").is_visible():
								get_owner().popup._on_repair_pressed("all")
						KEY_W:
							if get_owner().popup.get_node(@"m/repair/repair_weapon").is_visible():
								get_owner().popup._on_repair_pressed("weapon")
						KEY_R:
							if get_owner().popup.get_node(@"m/repair/repair_armor").is_visible():
								get_owner().popup._on_repair_pressed("armor")
				elif get_owner().item_info.is_visible():
					match event_code:
						KEY_LEFT:
							if not get_owner().item_info.get_node(@"s/h/left").is_disabled():
								get_owner()._on_sift_configure(false)
						KEY_RIGHT:
							if not get_owner().item_info.get_node(@"s/h/right").is_disabled():
								get_owner()._on_sift_configure(true)
						KEY_KP_ENTER, KEY_ENTER, KEY_C:
							if get_owner().item_info.get_node(@"s/h/v/cast").is_visible():
								get_owner()._on_cast_pressed()
						KEY_U:
							if get_owner().item_info.get_node(@"s/h/v/use").is_visible():
								get_owner()._on_use_pressed()
							elif get_owner().item_info.get_node(@"s/h/v/buy").is_visible():
								get_owner()._on_buy_pressed()
							elif get_owner().item_info.get_node(@"s/h/v/unequip").is_visible():
								get_owner()._on_unequip_pressed()
						KEY_S:
							if get_owner().item_info.get_node(@"s/h/v/sell").is_visible():
								get_owner()._on_sell_pressed()
						KEY_E:
							if get_owner().item_info.get_node(@"s/h/v/equip").is_visible():
								get_owner()._on_equip_pressed()
						KEY_D:
							if get_owner().item_info.get_node(@"s/h/v/drop").is_visible():
								get_owner()._on_drop_pressed()
				elif event_code == KEY_F and get_owner().quest_log.is_visible():
					get_owner()._on_filter_pressed()
				elif get_owner().inventory.is_visible() or get_owner().stats_menu.is_visible():
					match event_code:
						KEY_A:
							get_owner()._on_armor_slot_pressed()
						KEY_W:
							get_owner()._on_weapon_slot_pressed()
				elif get_owner().save_load.is_visible():
					match event_code:
						KEY_KP_1, KEY_1:
							get_owner().save_load._on_slot_pressed(0)
						KEY_KP_2, KEY_2:
							get_owner().save_load._on_slot_pressed(1)
						KEY_KP_3, KEY_3:
							get_owner().save_load._on_slot_pressed(2)
						KEY_KP_4, KEY_4:
							get_owner().save_load._on_slot_pressed(3)
						KEY_KP_5, KEY_5:
							get_owner().save_load._on_slot_pressed(4)
						KEY_KP_6, KEY_6:
							get_owner().save_load._on_slot_pressed(5)
						KEY_KP_7, KEY_7:
							get_owner().save_load._on_slot_pressed(6)
						KEY_KP_8, KEY_8:
							get_owner().save_load._on_slot_pressed(7)
				elif get_owner().dialogue.is_visible():
					match event_code:
						KEY_H:
							if get_owner().dialogue.get_node(@"s/s/v/heal").is_visible():
								get_owner()._on_heal_pressed()
						KEY_F:
							if get_owner().dialogue.get_node(@"s/s/v/finish").is_visible():
								get_owner()._on_finish_pressed()
						KEY_A:
							if get_owner().dialogue.get_node(@"s/s/v/accept").is_visible():
								get_owner()._on_accept_pressed()
		else:
			match event_code:
				KEY_F1, KEY_ESCAPE:
					get_owner()._on_pause_pressed()
				KEY_F2:
					get_owner()._on_spell_book_pressed()
				KEY_F3, KEY_M:
					get_owner()._on_mini_map_pressed()
				KEY_DELETE:
					get_owner()._on_unit_hud_pressed()
