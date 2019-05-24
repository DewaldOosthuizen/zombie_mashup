extends KinematicBody2D


var playerSprite # reference to character sprite image
var blood_colour = Color("#b90b0b") # default blood color
var gender = "male" # default character gender
var type = "" # used to define what character is currently active e.g (Robot, Ninja, etc)

# variables defaults, values can be changed from within script extending this script
var playerSpeedX = 0 # controlled by this script, speed on x-axis
var playerSpeedY = 0 # controlled by this scriptt, speed on y-axis
var facingDirection = 0 # controlled by this script, used for player sprite flip
var movementDirection = 0 # direction in which the character is moveing.
var currentJumpCount = 0 # checks if the character is busy jumping, the count being the amount of jumps

var movementMultiplier = 800 # character movement multiplier
var stationaryVelocity = 0.2 # default velocity on ground with gravity sits at 0.22, anything under means the character is in the air
var velocity = Vector2(0, 0)

export var maxJumpCount = 1 # characters can only jump once by default
export var maxSpeed = 350 # character max speed, defaulted to 350 
export var ammo = 0 # default starting ammo for characters
export var energy = 0 # energy gained from energy stones
export var maxEnergy = 100 # character max energy
export var health = 100 # character starts with 100 % health
export var maxHealth = 100 # character max health %
export var action1Damage = 30 # damage dealt with action 1
export var action2Damage = 20 # damage dealt with action 2
export var action3Damage = 10 # damage dealt with action 3
export var characterScale = Vector2(1, 1)
export var mainCharacter = false # indicate whether the character should have mainCharacter features

# Timers
var deathTime = 3
var deathTimer = 0
var flickerTimer = 0;
var invincibleTime = 3;
var invincibleTimer = 0;
var dazedTime = 2;
var dazedTimer = 0;
var glideTimer = 0
var glideTime = 0.6

# Flags
var blood = false # set to true to display blood and automatically reset to false afterwards
var dazed = false # character cannot move when set dazed to true, will be driven by dazed time and timer
var invincible = false # indicate whether the character can be hurt or not
var repeatFrames = true # indicate whether current sprite frames should be repeated or not
var disableGravity = false  # disable character gravity when set to true
var action1 = false # mapped to z
var action2 = false # mapped to x
var action3 = false # mapped to control
var shieldIndicator = false # indicate if shield is destroyed

# Constants
const GRAVITY = 800 # default gravity force
const JUMPFORCE = 400 # default jump force

# preloaded scenes
const bloodParticle_scene = preload("res://scenes/Blood_Particle_Scene.tscn")
const bone_scene = preload("res://scenes/environment/Bone_Scene.tscn")

# scenes that can be changed
var bullet_scene

# Collision objects
var AreaStandCollisionShape2D
var AreaSlideCollisionShape2D 
var AreaLeftAttackCollisionShape2D
var AreaRightAttackCollisionShape2D
var StandCollisionShape2D
var SlideCollisionShape2D

#signals
signal reload(character)
signal reposition()
signal refresh_hud(character)
signal character_ready(character)

# default character behavioyr drive, used for main characters
func _start_process(delta):
	# check which objects are within player area
	_area_checks()
	
	# set player speed, gravity and animate sprite
	_animate_player(delta)
	
	# handle collision on the x-axis
	var collidedObject1 = move_and_collide(Vector2(velocity.x, 0))
	_handle_collision(collidedObject1, false)

	# handle collision on the y-axis
	var collidedObject2 = move_and_collide(Vector2(0, velocity.y))
	_handle_collision(collidedObject2, velocity.y > stationaryVelocity)
	
	pass


func _animate_player(delta):
	# control speed
	if (dazed or health <= 0):
		playerSpeedX = 0
	elif (movementDirection != 0):
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
	playerSpeedY = clamp(playerSpeedY, playerSpeedY, maxSpeed * 3)
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
	if (disableGravity):
		glideTimer += delta
		if (glideTimer > glideTime):
			glideTimer = 0
			disableGravity = false
	
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
			particleEffect.modulate = blood_colour
			particleEffect.get_node(".").set_emitting(true)
			particleEffect.position = self.get_position()
			get_tree().root.add_child(particleEffect)
			_emit_refresh_hud()

	# check if player is dead
	if (health <= 0):
		_change_sprite_animation("dead")
		repeatFrames = false
		dazed = false
		deathTimer += delta
		velocity.x = 0
		velocity.y = 0
		if (deathTimer > deathTime):
			velocity.y = 1
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
			flickerTimer = 0
			shieldIndicator = false
			playerSprite.modulate = Color("#ffffff")
			
	if(flickerTimer > 0.12 and health > 0):
		if (shieldIndicator):
			# indicate shield has been depleted
			if(playerSprite.modulate == Color("#ffffff")):
				playerSprite.modulate = Color("#1d68c9") # blues
			else:
				playerSprite.modulate = Color("#ffffff") # normal
		elif ((stepify(health, 0.2) / stepify(maxHealth, 0.2) * 100) < 40):
			# indicate that health has dropped below 40%
			if(playerSprite.modulate == Color("#ffffff")):
				playerSprite.modulate = Color("#dd1717") # red
			else:
				playerSprite.modulate = Color("#ffffff") # normal
		else:
			if(playerSprite.visible):
				playerSprite.visible = false
			else:
				playerSprite.visible = true

		flickerTimer = 0
	pass


func _handle_collision(collidedObject, resetJump):
	if (collidedObject):
		#if character is on the floor
		if (resetJump):
			playerSpeedY = 0
			currentJumpCount = 0
	pass


func _shoot_bullet(power):
	action1 = true
	var bullet = bullet_scene.instance()
	bullet.power = power
	bullet.damage = action1Damage
	var bulletSprite = bullet.get_node("AnimatedSprite")
	ammo -= 1
	
	if (!playerSprite.flip_h):
		bulletSprite.flip_h = false
		bullet.movementDirection = 1
		bullet.position = self.get_position()  - Vector2(-20, 5)
	elif (playerSprite.flip_h):
		bulletSprite.flip_h = true;
		bullet.movementDirection = -1
		bullet.position = self.get_position()  - Vector2(20, 5)
		
	#	Add the nodes to the current scene
	get_tree().root.add_child(bullet)
	pass


func _area_checks():
	var objectsInAttackArea = get_node("AttackArea2D").get_overlapping_bodies()
	if (objectsInAttackArea and objectsInAttackArea.size() != 0):
		for body in objectsInAttackArea:
			if (body and !body.is_queued_for_deletion() and health > 0):
				var parent = body.get_parent()
				if (body.is_in_group("enemy_character")):
					if (action2):
						body._take_damage(action2Damage)
						body._daze()
					elif (action3):
						body._take_damage(action3Damage)
						body._daze()
				elif ((parent.is_in_group("brick") or parent.is_in_group("power_up_brick"))):
					parent.break_object()
					
					
	var objectsInCharacterArea = get_node("CharacterArea2D").get_overlapping_bodies()
	if (objectsInCharacterArea and objectsInCharacterArea.size() != 0):
		for body in objectsInCharacterArea:
			if (body and !body.is_queued_for_deletion() and health > 0):
				var parent = body.get_parent()
				if (parent.is_in_group("float")):
					if (parent.canTween and currentJumpCount == 0 and movementDirection == 0):
						self.position.x += (parent.position.x - self.position.x)
	
	
	var areasInCharacterArea = get_node("CharacterArea2D").get_overlapping_areas()
	if (areasInCharacterArea and areasInCharacterArea.size() != 0):
		for area in areasInCharacterArea:
			if (area and !area.is_queued_for_deletion() and health > 0):
				var parent = area.get_parent()
				if (area.is_in_group("enemy_attack")):
					if (parent.health > 0 and (parent.action1 or parent.action2 or parent.action3) and !dazed):
						if (!action1 and !action2 and !action3):
							if (parent.action1 and !action1):
								_take_damage(parent.action1Damage)
							elif (parent.action2):
								_take_damage(parent.action2Damage)
							elif (parent.action3):
								_take_damage(parent.action3Damage)
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
		if (energy > 0):
			energy -= damageAmount
			
			if (energy <= 0):
				health += energy # adding negative value, to deduct the difference from health
				shieldIndicator = true
				energy = 0
		else:
			health -= damageAmount
		
	pass	


func _daze():
	dazed = true
	pass


func _reset_character_sprite_states(delta):
	if (health <= 0):
		_change_sprite_animation("dead")
		repeatFrames = false
		disableGravity = false
	elif (dazed):
		_change_sprite_animation("idle")
		disableGravity = false
	elif (action1 or action2 or action3):
		if (!playerSprite.is_playing()):
			action1 = false
			action2 = false
			action3 = false
			repeatFrames = true
			disableGravity = false
			if (movementDirection == 0):
				_change_sprite_animation("idle")
			else: 
				_change_sprite_animation("walk")
			_default_collision()
	elif (!action1 and !action2 and !action3 and currentJumpCount == 0):
		_default_collision()
		repeatFrames = true
		if (movementDirection == 0):
			_change_sprite_animation("idle")
		else: 
			_change_sprite_animation("walk")
		disableGravity = false


func _setup_collision():
	AreaStandCollisionShape2D = get_node("CharacterArea2D/StandCollisionShape2D")
	AreaSlideCollisionShape2D = get_node("AttackArea2D/SlideAttackCollisionShape2D")
	AreaLeftAttackCollisionShape2D = get_node("AttackArea2D/LeftAttackCollisionShape2D")
	AreaRightAttackCollisionShape2D = get_node("AttackArea2D/RightAttackCollisionShape2D")
	StandCollisionShape2D = get_node("StandCollisionShape2D")
	SlideCollisionShape2D = get_node("SlideCollisionShape2D")
	_default_collision()
	

func _default_collision():
	AreaStandCollisionShape2D.disabled = false
	AreaSlideCollisionShape2D.disabled = true
	AreaLeftAttackCollisionShape2D.disabled = true
	AreaRightAttackCollisionShape2D.disabled = true
	StandCollisionShape2D.disabled = false
	SlideCollisionShape2D.disabled = true
	pass
	
	
func _melee_attack_collision():
	if (action2 and facingDirection == 1):
		AreaRightAttackCollisionShape2D.disabled = false
	elif (action2 and facingDirection == -1):
		AreaLeftAttackCollisionShape2D.disabled = false
	pass


func _slide_attack_collision():
	SlideCollisionShape2D.disabled = false
	AreaSlideCollisionShape2D.disabled = false
	StandCollisionShape2D.disabled = true
	AreaStandCollisionShape2D.disabled = true
	pass
	
	
func _change_sprite_animation(animationText):
	playerSprite.animation = gender + "_" + type + "_" + animationText
	pass


func _take_damage_from_saw(character, saw):
	if (self == character and saw.is_in_group("enemy_saw")):
		_take_damage(15)
	pass

# called from world scene when setting up the character
func _subscribe_to_signals():
	var enemy_saws = get_tree().get_nodes_in_group("enemy_saw")
	for i in enemy_saws:
		if (!i.is_connected("touchedSaw", self, "_take_damage_from_saw")):
			i.connect("touchedSaw", self, "_take_damage_from_saw")
			

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
	

func _emit_character_ready():
	if (mainCharacter):
		emit_signal("character_ready", self)
	pass
