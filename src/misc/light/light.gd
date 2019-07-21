extends Sprite

func _ready() -> void:
	if globals.day_night:
		start()
	else:
		stop()

func start() -> void:
	if $visibility.is_on_screen():
		if not globals.day_night:
			$light.show()
		$anim.play("torch")
		for node in get_children():
			emit(node)
			for child in node.get_children():
				emit(child)

func stop() -> void:
	$anim.stop()
	$light.hide()
	if not $visibility.is_on_screen():
		for node in get_children():
			emit(node, false)
			for child in node.get_children():
				emit(child, false)

func emit(x: Node, set=true) -> void:
	if x.is_class("Particles2D"):
		x.set_emitting(set)