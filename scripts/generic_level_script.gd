extends Node2D

# Declare member variables here. Examples:
signal exit_level()
signal entered_level()

# Called when the node enters the scene tree for the first time.
func _ready():
	emit_signal("entered_level")

func _exit_tree():
	emit_signal("exit_level")
