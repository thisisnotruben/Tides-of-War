extends Node2D
class_name Combustible

signal combust()

func combust() -> void:
	emit_signal("combust")
