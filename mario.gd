extends KinematicBody2D

# variables
var playerSpeedX = 0
var playerSpeedY = 0
var velocity = Vector2(0, 0)
var facingDirection = 0
var movementDirection = 0
var playerSprite
var maxJumpCount = 1
var currentJumpCount = 0
var deltaTime = 0

# constants
const MAXIMUMSPEED = 300
const MOVEMULTI = 800
const JUMPFORCE = 350
const GRAVITY = 800


func _ready():
	playerSprite = get_node("Mario")
	set_process(true)
	
	pass


func _process(delta):
	deltaTime = deltaTime + delta
	_control_mario(delta)
	
	pass


func _control_mario(delta):
	_jump_mario()
	_move_mario()
	_set_mario_speed(delta)
	_apply_gravity(delta)
	
	var collidedObject = move_and_collide(Vector2(0, velocity.y))
	move_local_x(velocity.x)
	
	# reset the current sprite frame to 0 if mario is standing still on the x axis and not jumping
	if (velocity.x == 0 and currentJumpCount == 0):
		playerSprite.frame = 0
	
	_handle_collision(collidedObject)
	
	pass


func _jump_mario():
	# control mario jump
	if (Input.is_action_just_pressed("move_jump") and currentJumpCount < maxJumpCount):
		playerSpeedY = -JUMPFORCE
		currentJumpCount += 1
		playerSprite.frame = 5
	
	pass


func _move_mario():
	# control mario facing direction
	if (Input.is_action_pressed("move_left")):
		facingDirection = -1
		movementDirection = facingDirection
		playerSprite.flip_h = true;
		if (deltaTime > 0.1 and currentJumpCount == 0):
			_animate_player()
	elif (Input.is_action_pressed("move_right")):
		facingDirection = 1
		movementDirection = facingDirection
		playerSprite.flip_h = false;
		if (deltaTime > 0.1 and currentJumpCount == 0):
			_animate_player()
	else:
		facingDirection = 0
		if (currentJumpCount == 0):
			playerSprite.frame = 4
	
	pass


func _set_mario_speed(delta):
	# control mario speed
	if (facingDirection != 0):
		playerSpeedX += MOVEMULTI * delta
	else:
		playerSpeedX -= MOVEMULTI * 2 * delta
		
	pass
	
func _apply_gravity(delta):
	#apply gravity to jump
	playerSpeedY += GRAVITY * delta
	#stop player from keeping on increasing speed
	playerSpeedX = clamp(playerSpeedX, 0, MAXIMUMSPEED)
	#set player speed
	velocity.x = playerSpeedX * delta * movementDirection
	velocity.y = playerSpeedY * delta
	
	pass

func _animate_player():
	if (playerSprite.frame >= 3):
		playerSprite.frame = 1
	
	playerSprite.frame += 1
	deltaTime = 0
	
	pass


func _handle_collision(collidedObject):
	if (collidedObject):
		#if character is on the floor
		if (collidedObject.normal == Vector2(0, -1)):
			playerSpeedY = 0
			 
			if (currentJumpCount > 0):
				playerSprite.frame = 0
				currentJumpCount = 0
	
		#if character collides with an object from beneath
		if (collidedObject.normal == Vector2(0, 1)):
 			_remove_if_brick(collidedObject);
	
	pass
	
func _remove_if_brick(object):
	print(object.transform.parent.gameObject)
	#object.collider.free()
	pass