extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	emit_signal("entered_level")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


signal exit_level()
signal entered_level()


func _exit_tree():
	emit_signal("exit_level")
