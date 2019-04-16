extends AnimatedSprite

# Declare member variables here.
var deltaTime = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	self.animation = "blood"
	set_process(true)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	deltaTime += delta
	_animate()
	pass

func _animate():
	print("running: " + str(deltaTime))
	if (deltaTime > 1):
		if (self.frame == self.get_sprite_frames().get_frame_count(self.animation) - 1):
			self.queue_free();
		else:
			self.frame += 1
	
	pass
