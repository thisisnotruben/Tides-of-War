"""
UI controller for start menu.
"""
extends Control
class_name StartMenu

onready var list_of_menus = get_node(@"list_of_menus/m")
onready var load_menu = list_of_menus.get_node(@"save_load")
onready var settings = list_of_menus.get_node(@"settings")
onready var menu = list_of_menus.get_node(@"main_menu")
onready var about = list_of_menus.get_node(@"about")
onready var popup = get_node(@"popup")

var selected = null
var selected_index: int = -1

func _ready() -> void:
	globals.current_scene = self

func _on_new_game_pressed() -> void:
	globals.play_sample("click0")
	globals.set_scene("res://src/map/map-1.tscn")

func _on_load_pressed() -> void:
	globals.play_sample("click1")
	if menu.is_visible():
		menu.hide()
		load_menu.show()

func _on_settings_pressed() -> void:
	globals.play_sample("click1")
	menu.hide()
	settings.show()

func _on_about_pressed() -> void:
	globals.play_sample("click1")
	menu.hide()
	about.show()

func _on_back_pressed() -> void:
	globals.play_sample("click3")
	if load_menu.is_visible():
		load_menu.hide()
		menu.show()
	elif settings.is_visible():
		settings.hide()
		menu.show()

func _on_exit_pressed() -> void:
	get_tree().quit()

func _input(event: InputEvent) -> void:
	"""Hotkeys for non-phone deployments"""
	if event is InputEventKey:
		if not event.is_pressed() or event.is_echo():
			return
		var event_code: int = event.get_scancode()
		if menu.is_visible():
			match event_code:
				KEY_N:
					set_process_input(false)
					_on_new_game_pressed()
				KEY_L:
					_on_load_pressed()
				KEY_S:
					_on_settings_pressed()
				KEY_A:
					_on_about_pressed()
				KEY_ESCAPE:
					_on_exit_pressed()
		else:
			if event_code == KEY_ESCAPE:
				if about.is_visible():
					about._on_back_pressed()
				elif popup.is_visible():
					popup._on_back_pressed()
				else:
					_on_back_pressed()
			elif popup.get_node(@"m/save_load").is_visible():
				match event_code:
					KEY_D:
						popup._on_delete_pressed()
					KEY_L:
						set_process_input(false)
						popup._on_load_pressed()
			elif popup.get_node(@"m/yes_no").is_visible():
				match event_code:
					KEY_Y:
						popup._on_yes_pressed()
					KEY_N:
						popup._on_no_pressed()
			elif load_menu.is_visible():
				match event_code:
					KEY_KP_1, KEY_1:
						load_menu._on_slot_pressed(0)
					KEY_KP_2, KEY_2:
						load_menu._on_slot_pressed(1)
					KEY_KP_3, KEY_3:
						load_menu._on_slot_pressed(2)
					KEY_KP_4, KEY_4:
						load_menu._on_slot_pressed(3)
					KEY_KP_5, KEY_5:
						load_menu._on_slot_pressed(4)
					KEY_KP_6, KEY_6:
						load_menu._on_slot_pressed(5)
					KEY_KP_7, KEY_7:
						load_menu._on_slot_pressed(6)
					KEY_KP_8, KEY_8:
						load_menu._on_slot_pressed(7)
