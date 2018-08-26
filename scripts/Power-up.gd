extends KinematicBody2D

# variables
var playerSpeedY = 0
var velocity = Vector2(0, 0)
var movementDirection = 1

const PLAYERSPEEDX = 110
const GRAVITY = 800

func _ready():
	set_process(true)
	pass
	
	
func _process(delta):
	playerSpeedY += GRAVITY * delta
	velocity.x = PLAYERSPEEDX * delta * movementDirection
	velocity.y = playerSpeedY * delta
	var collider = move_and_collide(velocity)
	move_local_x(velocity.x)
	
	if (collider):
		if (collider.normal == Vector2(0,-1)):
			playerSpeedY = 0
		if (collider.normal == Vector2(1,0)):
			movementDirection = 1
		elif ( collider.normal == Vector2(-1,0)):
			movementDirection = -1
	pass
