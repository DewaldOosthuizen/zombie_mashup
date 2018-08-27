extends KinematicBody2D

# variables
var playerSpeedY = 0
var velocity = Vector2(0, 0)
var movementDirection = -1
var playerSprite
var deltaTime = 0

const PLAYERSPEEDX = 50
const GRAVITY = 800

func _ready():
	playerSprite = get_node("Sprite")
	set_process(true)
	pass
	
	
func _process(delta):
	deltaTime = deltaTime + delta
	if(get_node("CollisionShape2D").disabled):
		playerSprite.frame = 4
	
	if(self.position.y < -20):
		self.free()
	
	if(deltaTime > 0.1):
		if(!playerSprite.flip_h):
			playerSprite.flip_h = true
		else:
			playerSprite.flip_h = false
		deltaTime = 0
	
	playerSpeedY += GRAVITY * delta
	velocity.x = PLAYERSPEEDX * delta * movementDirection
	velocity.y = playerSpeedY * delta - 8
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