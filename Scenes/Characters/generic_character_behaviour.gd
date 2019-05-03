extends KinematicBody2D

# variables defaults, values can be changed from within script extending this script
var playerSprite # set this from within the script that extends this script
var playerSpeedX = 0 # controlled by this script, speed on x-axis
var playerSpeedY = 0 # controlled by this scriptt, speed on y-axis
var facingDirection = 0 # controlled by this script, used for player sprite flip
var movementDirection = 0 # direction in which the character is moveing.
var maxJumpCount = 1 # characters can only jump once by default
var currentJumpCount = 0 # checks if the character is busy jumping, the count being the amount of jumps
var maxSpeed = 350 # character max speed, defaulted to 350 
var movementMultiplier = 800 # character movement multiplier
var health = 3 # character starts with 3 lives

var ammo = 0 # default starting ammo for characters
var ammoIncrease = 0 # default ammo increase when picking up more ammo 
var power = 0 # can be used for whatever the characters gains when a power up prick is picked up
var powerIncrease = 1  # used for incrementing the power when another power up brick is obtained

# Timers
var invincibleTime = 0;
var invincibleTimer = 0;
var action1Timer = 0
var action2Timer = 0
var action3Timer = 0
var action1TimerDelay = 0.5 # for how long does the character do action1, can be changed
var action2TimerDelay = 0.5  # for how long does the character do action2, can be changed
var action3TimerDelay = 1  # for how long does the character do action3, can be changed

# Flags
var repeatFrames = true
var blood = false
var invincible = false
var action1 = false # mapped to z
var action2 = false # mapped to x
var action3 = false # mapped to control
var canReload = false

# Constants
const GRAVITY = 800
const JUMPFORCE = 400

signal reload(character)

const bloodParticle_scene = preload("res://Scenes/Blood_Particle_Scene.tscn")

func _animate_player(delta):
	# control speed
	if (facingDirection != 0):
		playerSpeedX += movementMultiplier * delta
	else:
		playerSpeedX -= movementMultiplier * 2 * delta
	
	#apply gravity to jump
	playerSpeedY += GRAVITY * delta
	#stop player from keeping on increasing speed
	playerSpeedX = clamp(playerSpeedX, 0, maxSpeed)
	#set player speed
	var velocity = Vector2(0, 0)
	velocity.x = playerSpeedX * delta * movementDirection
	velocity.y = playerSpeedY * delta
	
	if (!repeatFrames and playerSprite.frame < playerSprite.get_sprite_frames().get_frame_count(playerSprite.animation) - 1):
		playerSprite.play()
	elif (repeatFrames): 
		playerSprite.play()
	else:
		playerSprite.stop()
		
	_handle_timers(delta)
	
	return velocity


func _handle_timers(delta):	
	# creates a delay until the player can perform action 1 again
	if (action1):
		repeatFrames = false;
		action1Timer += delta
		if (action1Timer > action1TimerDelay):
			action1 = false
			action1Timer = 0
	
	# creates a delay until the player can perform action 2 again
	if (action2):
		repeatFrames = false;
		action2Timer += delta
		if (action2Timer > action2TimerDelay):
			action2 = false
			action2Timer = 0
	
	# creates a delay until the player can perform action 2 again
	if (action3):
		repeatFrames = true;
		action3Timer += delta
		if (action3Timer > action3TimerDelay):
			action3 = false
			action3Timer = 0


	# set blood to true to take damage
	if (blood):
		blood = false
		if (!invincible):
			# create instance of blodd and add it to the scene
			var particleEffect = bloodParticle_scene.instance()
			particleEffect.get_node(".").set_emitting(true)
			particleEffect.position = self.get_position()
			get_tree().root.add_child(particleEffect)
			
			# subtract a life
			health -= 1
			invincible = true
			
			# check if player is dead
			if (health < 0):
				#warning-ignore:return_value_discarded
				_emit_reload()
					
	# Create flickering effect to indicate damage
	if (invincible):
		invincibleTime += delta
		invincibleTimer += delta
		
		if (invincibleTimer > 3):
			playerSprite.visible = true
			invincible = false
			invincibleTimer = 0
			
		if(invincibleTime > 0.1):
			if(playerSprite.visible):
				playerSprite.visible = false
			else:
				playerSprite.visible = true
			
			invincibleTime = 0
	elif (!playerSprite.visible):
		playerSprite.visible = true


func _move_left():
	facingDirection = -1
	movementDirection = facingDirection
	playerSprite.flip_h = true


func _move_right():
	facingDirection = 1
	movementDirection = facingDirection
	playerSprite.flip_h = false
	

func _emit_reload():
	if(canReload):
		emit_signal("reload", self)
	else:
		self.queue_free()