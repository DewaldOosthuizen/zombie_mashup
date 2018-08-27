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
var power = 0
var invincible = false;
var invincibleTime = 0;
var invincibleTimer = 0;

# constants
const MAXIMUMSPEED = 300
const MOVEMULTI = 800
const JUMPFORCE = 350
const GRAVITY = 800
const bricksParticle_scene = preload("res://Scenes/Bricks_Particle_Scene.tscn")
const powerUp_scene = preload("res://Scenes/Power_Up_Scene.tscn")
const powerUpBrick_scene = preload("res://Scenes/Box_Scene.tscn")

func _ready():
	playerSprite = get_node("Mario")
	set_process(true)
	$CollisionShape2D.connect("area_entered", self, "_remove_if_brick")
	pass


func _process(delta):
	deltaTime = deltaTime + delta
	_control_mario(delta)
	_check_invincibility(delta)
	
	pass


func _check_invincibility(delta):
	if (invincible):
		invincibleTime = invincibleTime + delta
		invincibleTimer = invincibleTimer + delta
		if (invincibleTimer > 2):
			playerSprite.visible = true
			invincible = false
			
		if(invincibleTime > 0.05):
			if(playerSprite.visible):
				playerSprite.visible = false
			else:
				playerSprite.visible = true
			
			invincibleTime = 0
	else:
		playerSprite.visible = true

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
	_check_for_power_up()
	_check_if_player_has_fallen_in_pit()
	_check_if_enemy_has_killed_player()
	
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
			playerSpeedY= 0
			 
			if (currentJumpCount > 0):
				playerSprite.frame = 0
				currentJumpCount = 0
	
		#if character collides with an object
		_remove_if_brick(collidedObject);
		_check_if_power_up_brick(collidedObject)
	pass
	
func _remove_if_brick(object):
	if (power > 0):
		var objectParent = object.collider.get_parent()
		
		if (objectParent.is_in_group("Bricks") and object.normal == Vector2(0, 1)):
			#add the particle effect of the brick breaking
			var particleEffect = bricksParticle_scene.instance()
			particleEffect.get_node(".").set_emitting(true)
			particleEffect.position = self.get_position()  - Vector2(0, 20)
			get_tree().root.add_child(particleEffect)
			#remove the brick
			objectParent.queue_free()
	pass
	
func _check_if_power_up_brick(object):
	var objectParent = object.collider.get_parent()
	if (objectParent.is_in_group("PowerUpBrick")):
		# create power up brick
		var powerUpBrick = powerUpBrick_scene.instance()
		powerUpBrick.position = objectParent.get_node("Sprite").global_position
		#remove the brick previous brick
		objectParent.queue_free()
		# add the new box brick
		get_tree().root.add_child(powerUpBrick)
		
		# create actual power up
		var powerUp = powerUp_scene.instance()
		powerUp.position = powerUpBrick.position - Vector2(0, 50)
		get_tree().root.add_child(powerUp)
		
	pass
	
func _check_for_power_up():
	var area = get_node("Area2D").get_overlapping_bodies()
	if (area.size() != 0):
		for body in area:
			if (body.is_in_group("PowerUp")):
				power += 1
				body.queue_free()
				var mario = get_node("Mario")
				mario.scale = Vector2(1.3, 1.3)
				mario.position = Vector2(mario.position.x, mario.position.y - 8)
	pass
	
func _remove_power_up():
	var mario = get_node("Mario")
	mario.scale = Vector2(1, 1)
	mario.position = Vector2(mario.position.x, mario.position.y + 8)
	pass
	
func _check_if_player_has_fallen_in_pit():
	var area = get_node("Area2D").get_overlapping_bodies()
	if (area.size() != 0):
		for body in area:
			if (body.is_in_group("Pits")):
				get_tree().reload_current_scene()
	pass
	
func _check_if_enemy_has_killed_player():
	var area = get_node("Area2D").get_overlapping_bodies()
	if (area.size() != 0):
		for body in area:
			if (body.is_in_group("Enemy")):
				if (body.position.y > self.position.y + 5):
					body.get_node("CollisionShape2D").disabled = true
					#body.queue_free()
				elif(!invincible):
					power -= 1
					invincible = true
					if (power < 0):
						get_tree().reload_current_scene()
					else:
						_remove_power_up()
	pass