extends CharacterBody3D

enum PowerupClass {
	NONE,
	BUTTER,
	PEANUTBUTTER,
}

const LEVEL_PATH = "res://Level/Levels/Level"
const SPEED = 5.0
const JUMP_VELOCITY = 9.5

signal dead
signal next_level

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var currentPowerup = PowerupClass.NONE

func _physics_process(delta):
	# Add the gravity.
	position.z = 0.5
	velocity.z = 0
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _on_hitbox_area_entered(area):
	if area.is_in_group("Powerup"):
		if area.owner.is_in_group("Butter"):
			currentPowerup = PowerupClass.BUTTER
		return
	if area.get_collision_layer_value(2):
		die()
		return
	if area.get_collision_layer_value(3):
		progress()
		return
	
func die():
	dead.emit()
	queue_free()

func progress():
	next_level.emit()
