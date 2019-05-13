extends Node2D

var tweenFloats = []

# Declare member variables here. Examples:
signal exit_level()
signal entered_level()

# Called when the node enters the scene tree for the first time.
func _ready():
	emit_signal("entered_level")

func _activate_tween_floats():
	var floats = get_tree().get_nodes_in_group("float")
	# loop through all floats
	for f in floats:
		# start tweeining on selected float objects
		for v in tweenFloats:
			if (f.name == ("Float" + str(v["name"]))):
				f.moveDirectionX = v["moveDirectionX"]
				f.moveDirectionY = v["moveDirectionY"]
				f.moveDistanceX = v["moveDistanceX"]
				f.moveDistanceY = v["moveDistanceY"]
				f.tweenDuration = v["tweenDuration"]
				f._set_can_tween(true)
	
	# reset object in attempt so free memory
	tweenFloats = []
	pass

func _exit_tree():
	emit_signal("exit_level")
