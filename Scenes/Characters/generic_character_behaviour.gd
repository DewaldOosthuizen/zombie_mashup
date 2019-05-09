extends KinematicBody2D


var playerSprite # set this from within the script that extends this script
var character_folder_name = ""

# variables defaults, values can be changed from within script extending this script
var playerSpeedX = 0 # controlled by this script, speed on x-axis
var playerSpeedY = 0 # controlled by this scriptt, speed on y-axis
var facingDirection = 0 # controlled by this script, used for player sprite flip
var movementDirection = 0 # direction in which the character is moveing.
var maxJumpCount = 1 # characters can only jump once by default
var currentJumpCount = 0 # checks if the character is busy jumping, the count being the amount of jumps
var maxSpeed = 350 # character max speed, defaulted to 350 
var movementMultiplier = 800 # character movement multiplier
var stationaryVelocity = 0.2 # default velocity on ground with gravity sits at 0.22, anything under means the character is in the air
var velocity = Vector2(0, 0)

var ammo = 0 # default starting ammo for characters
var ammoIncrease = 10 # default ammo increase when picking up more ammo 
var power = 0 # can be used for whatever the characters gains when a power up prick is picked up
var powerIncrease = 20  # used for incrementing the power when another power up brick is obtained
var type = "" # used to define what character is currently active e.g (Robot, Ninja, etc)
var health = 100 # character starts with 100 % health
var maxHealth = 100 # character max health %

# Timers
var deathTime = 2
var deathTimer = 0
var flickerTimer = 0;
var invincibleTime = 3;
var invincibleTimer = 0;
var dazedTime = 2;
var dazedTimer = 0;
var action1Timer = 0 
var action2Timer = 0
var action3Timer = 0
var action1TimerDelay = 0.5 # for how long does the character do action1, can be changed
var action2TimerDelay = 0.5  # for how long does the character do action2, can be changed
var action3TimerDelay = 1  # for how long does the character do action3, can be changed

# Flags
var blood = false # set to true to display blood and automatically reset to false afterwards
var dazed = false # character cannot move when set dazed to true, will be driven by dazed time and timer
var invincible = false # indicate whether the character can be hurt or not
var repeatFrames = true # indicate whether current sprite frames should be repeated or not
var mainCharacter = false # indicate whether the character should have mainCharacter features
var disableGravity = false  # disable character gravity when set to true
var action1 = false # mapped to z
var action2 = false # mapped to x
var action3 = false # mapped to control

# Constants
const GRAVITY = 800
const JUMPFORCE = 400
const bloodParticle_scene = preload("res://Scenes/Blood_Particle_Scene.tscn")
const bone_scene = preload("res://Scenes/Environment/Bone_Scene.tscn")

#signals
signal reload(character)
signal reposition()
signal refresh_hud(character)

func _animate_player(delta):
	# control speed
	
	if (facingDirection != 0):
		playerSpeedX += movementMultiplier * delta
	else:
		playerSpeedX -= movementMultiplier * 2 * delta
	
	#apply gravity to jump
	if (disableGravity):
		playerSpeedY += delta
	else:
		playerSpeedY += GRAVITY * delta
		
	#stop player from keeping on increasing speed
	playerSpeedX = clamp(playerSpeedX, 0, maxSpeed)
	#set player speed
	velocity.x = playerSpeedX * delta * movementDirection
	velocity.y = playerSpeedY * delta
	
	if (!repeatFrames and playerSprite.frame < playerSprite.get_sprite_frames().get_frame_count(playerSprite.animation) - 1):
		playerSprite.play()
	elif (repeatFrames): 
		playerSprite.play()
	else:
		playerSprite.stop()
		
	_handle_timers(delta)


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
			
	# creates a delay that the character remains dazed
	if (dazed):
		dazedTimer += delta
		if (dazedTimer > dazedTime):
			dazed = false
			dazedTimer = 0

	# set blood to true to take damage
	if (blood):
		blood = false
		if (!invincible):
			invincible = true
			# create instance of blodd and add it to the scene
			var particleEffect = bloodParticle_scene.instance()
			particleEffect.get_node(".").set_emitting(true)
			particleEffect.position = self.get_position()
			get_tree().root.add_child(particleEffect)
			_emit_refresh_hud()
			
	# check if player is dead
	if (health <= 0):
		playerSprite.animation = type + "_dead"
		repeatFrames = false
		dazed = false
		deathTimer += delta
		velocity.y = 0
		velocity.x = 0
		if (deathTimer > deathTime):
			#warning-ignore:return_value_discarded
			deathTimer = 0
			_emit_reload()
					
	# Create flickering effect to indicate damage
	if (invincible):
		flickerTimer += delta
		invincibleTimer += delta
		
		if (invincibleTimer > invincibleTime):
			playerSprite.visible = true
			invincible = false
			invincibleTimer = 0
			
		if(flickerTimer > 0.1 and health > 0):
			if(playerSprite.visible):
				playerSprite.visible = false
			else:
				playerSprite.visible = true

			flickerTimer = 0
	elif (!playerSprite.visible):
		playerSprite.visible = true
	pass


func _move_left():
	facingDirection = -1
	movementDirection = facingDirection
	playerSprite.flip_h = true
	pass


func _move_right():
	facingDirection = 1
	movementDirection = facingDirection
	playerSprite.flip_h = false
	pass
	

func _take_damage(damageAmount):
	if (!invincible):
		blood = true
		health -= damageAmount
	pass	


func _daze():
	dazed = true
	pass


func _emit_reload():
	if(mainCharacter):
		emit_signal("reload", self)
	else:
		var bones = bone_scene.instance()
		bones.position = self.get_position()  - Vector2(0, -70)
		get_tree().root.add_child(bones)
		self.queue_free()
	pass


func _emit_reposition():
	if(mainCharacter):
		emit_signal("reposition")
	else:
		self.queue_free()
	pass


func _emit_refresh_hud():
	if (mainCharacter):
		emit_signal("refresh_hud", self)
	pass
