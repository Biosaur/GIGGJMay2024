extends CharacterBody3D

enum PowerupClass {
	NONE,
	BUTTER,
	PEANUTBUTTER,
}

const LEVEL_PATH = "res://Level/Levels/Level"
@export var movementSpeed : float = 5.0

@export var jumpHeight : float = 3.0
@export var jumpTimeToPeak : float = 0.4
@export var jumpTimeToFall : float = 0.3

@onready var jumpVelocity : float = (2.0 * jumpHeight) / jumpTimeToPeak
@onready var jumpGravity : float = (-2.0 * jumpHeight) / (jumpTimeToPeak * jumpTimeToPeak)
@onready var fallGravity : float = (-2.0 * jumpHeight) / (jumpTimeToFall * jumpTimeToFall)

@export var dashDistance : float = 5.0
@export var dashDuration : float = 0.2
@export var dashCarryover : float = 5

@onready var dashVelocity : float = dashDistance / dashDuration

signal dead
signal next_level

var currentPowerup = PowerupClass.NONE
var dashDirection = Vector3()
var isDashing = false

func startDashTimer():
	isDashing = true
	await get_tree().create_timer(dashDuration).timeout
	isDashing = false
	velocity = dashDirection * dashCarryover

func _physics_process(delta):
	# Add the gravity.
	position.z = 0.5
	velocity.z = 0
	if not is_on_floor():
		velocity.y += (jumpGravity if velocity.y > 0.0 else fallGravity) * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jumpVelocity

	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_vector("left", "right", "up", "down")
	if direction:
		velocity.x = (-1.0 if direction.x < 0.0 else 1.0 if direction.x > 0.0 else 0) * direction.length() * movementSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, movementSpeed)

	if Input.is_action_just_pressed("ability"):
		if currentPowerup == PowerupClass.BUTTER:
			currentPowerup = PowerupClass.NONE
			dashDirection = Vector3(direction.x, -direction.y, 0)
			startDashTimer()
	
	if isDashing:
		velocity = dashDirection * dashVelocity
	
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
