extends KinematicBody2D


var playerSprite
var blood_colour = Color("#b90b0b")
var gender = "male"

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
var energy = 0 # energy gained from energy stones
var energyIncrease = 20  # used for incrementing the energy when another energy up brick is obtained
var type = "" # used to define what character is currently active e.g (Robot, Ninja, etc)
var health = 100 # character starts with 100 % health
var maxHealth = 100 # character max health %
var action1Damage = 30
var action2Damage = 20
var action3Damage = 10

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
var glideTimer = 0
var glideTime = 0.6

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
		playerSprite.visible = true
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
			
		if(flickerTimer > 0.1 and health > 0):
			if(playerSprite.visible):
				playerSprite.visible = false
			else:
				playerSprite.visible = true

			flickerTimer = 0
	elif (!playerSprite.visible):
		playerSprite.visible = true
	pass


func _handle_collision(collidedObject, resetJump):
	if (collidedObject):
		#if character is on the floor
		if (resetJump):
			playerSpeedY = 0
			currentJumpCount = 0
			repeatFrames = true
	pass


func _shoot_bullet(power):
	action1 = true
	var bullet = bullet_scene.instance()
	bullet.speed = 800
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
	var objectsInCharacterArea = get_node("CharacterArea2D").get_overlapping_bodies()
	
	if (objectsInCharacterArea and objectsInCharacterArea.size() != 0):
		for body in objectsInCharacterArea:
			if (body and !body.is_queued_for_deletion() and health > 0):
				var parent = body.get_parent()
				if (body.is_in_group("ammo_pack")):
					ammo += ammoIncrease
					body.queue_free()
					_emit_refresh_hud()
				elif (body.is_in_group("health_pack")):
					health += body.health
					body.queue_free()
					_emit_refresh_hud()
				elif (body.is_in_group("energy_stone")):
					energy += energyIncrease
					body.queue_free()
					_emit_refresh_hud()
				elif (body.is_in_group("pit")):
					energy = 0
					ammo = 0
					health -= 100
					_emit_reload()
				elif (body.is_in_group("enemy_character")):
					if (body.health > 0 and (body.action1 or body.action2 or body.action3) and !dazed):
						if (body.action1):
							_take_damage(body.action1Damage)
						elif (body.action2):
							_take_damage(body.action2Damage)
						elif (body.action3):
							_take_damage(body.action3Damage)
#				if (objectParent.is_in_group("float")):
#					if (objectParent.canTween and currentJumpCount == 0 and facingDirection == 0):
#						self.position.x += (collidedObject.position.x - self.position.x)
	
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
				elif (body.is_in_group("energy_stone")):
					energy += energyIncrease
					body.queue_free()
					_emit_refresh_hud()
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


func _reset_character_sprite_states(delta):
	if (disableGravity):
		glideTimer += delta
		if (glideTimer > glideTime):
			glideTimer = 0
			disableGravity = false
	
	if (health <= 0):
		_change_sprite_animation("dead")
		repeatFrames = false
		disableGravity = false
	elif (dazed):
		_change_sprite_animation("idle")
		disableGravity = false
	elif (currentJumpCount == 0 and (action1 or action2 or action3)):
		if (!playerSprite.is_playing()):
			repeatFrames = true
			if (facingDirection == 0):
				_change_sprite_animation("idle")
			else: 
				_change_sprite_animation("walk")
			_default_collision()
			disableGravity = false
	elif (!action1 and !action2 and !action3 and currentJumpCount == 0):
		_default_collision()
		repeatFrames = true
		if (facingDirection == 0):
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
	if (action2 and movementDirection == 1):
		AreaRightAttackCollisionShape2D.disabled = false
	elif (action2 and movementDirection == -1):
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
