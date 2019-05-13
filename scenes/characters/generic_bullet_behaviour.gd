extends KinematicBody2D

# variables
var sprite

export var movementDirection = 1
export var speed = 800
export var power = 0
export var damage = 30

var velocity = Vector2(0, 0)
var noValidCollision = []
var deltaTime = 0

const bricksParticle_scene = preload("res://scenes/environment/Brick_1_Particle_Scene.tscn")
const blood_scene = preload("res://scenes/Blood_Particle_Scene.tscn")

func _animate_bullet(delta):
	deltaTime += delta
	_set_speed(delta)
	_animate()
	
	if (power == 0):
		self.scale = Vector2(0.2, 0.2)
	elif (power == 1):
		self.scale = Vector2(0.21, 0.22)
	elif (power == 2):
		self.scale = Vector2(0.22, 0.23)
		
	var collider1 = move_and_collide(Vector2(velocity.x, velocity.y))
	_check_collision_objects()
	_remove_if_brick(collider1)
	
	# Ensures bullet disapears upon hitting invalid objects
	if (noValidCollision.size() == 2):
		self.queue_free()
	pass


func _set_speed(delta):
	velocity.x = speed * delta * movementDirection
	velocity.y = 0
	pass


func _create_muzzle(muzzle_scene):
	var muzzle = muzzle_scene.instance()
	
	if (movementDirection == 1):
		muzzle.position = self.position - Vector2(-20, 1)
	else:
		muzzle.position = self.position - Vector2(20, 1)
	
	get_tree().root.add_child(muzzle)
	pass


func _animate():
	sprite.play()
	pass


func _remove_if_brick(object):
	if (object and object.collider):
		var objectParent = object.collider.get_parent()
		if (objectParent.is_in_group("brick")):
			objectParent.break_object()
			if (power < 1):
				self.queue_free()
		elif (objectParent.is_in_group("power_up_brick")):
			objectParent.break_object()
			if (power < 1):
				self.queue_free()
		else:
			noValidCollision.append(true)
	pass

	
func _check_collision_objects():
	var area = get_node("Area2D").get_overlapping_bodies()
	if (area.size() != 0):
		for body in area:
			if (body.is_in_group("enemy_character")):
				get_node("CollisionShape2D").disabled = true
				body._take_damage(damage + (5 * power)) #take damage and increase damage based on power level of bullet
				self.queue_free()
			if (body.is_in_group("enemy_saw")):
				if (power > 1):
					body.queue_free()
				self.queue_free()
	pass
