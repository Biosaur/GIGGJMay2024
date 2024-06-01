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

@export var slideMultiplier : float = 4.0
@export var slideDuration : float = 3.0
@export var slideSlipperiness : float = 0.95

signal dead
signal next_level

var currentPowerup = PowerupClass.NONE
var dashDirection = Vector3()
var isDashing = false
var isSliding = false

func startDashTimer():
	isDashing = true
	await get_tree().create_timer(dashDuration).timeout
	isDashing = false
	velocity = dashDirection * dashCarryover

func startSlideTimer():
	isSliding = true
	movementSpeed *= slideMultiplier
	floor_max_angle = deg_to_rad(85)
	await get_tree().create_timer(slideDuration).timeout
	isSliding = false
	movementSpeed /= slideMultiplier
	floor_max_angle = deg_to_rad(45)

func _physics_process(delta):
	# Add the gravity.
	position.z = 0.5
	velocity.z = 0
	
	
	var direction = Input.get_vector("left", "right", "up", "down")
	
	if isDashing:
		velocity = dashDirection * dashVelocity
	else:
		if not is_on_floor():
			velocity.y += (jumpGravity if velocity.y > 0.0 else fallGravity) * delta

		# Handle jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jumpVelocity

		# Get the input direction and handle the movement/deceleration.
		var oldXVel = velocity.x
		if direction:
			velocity.x = (-1.0 if direction.x < 0.0 else 1.0 if direction.x > 0.0 else 0) * direction.length() * movementSpeed
		else:
			velocity.x = move_toward(velocity.x, 0, movementSpeed)
			
		if isSliding:
			velocity.x = lerp(velocity.x, oldXVel, slideSlipperiness)

		if Input.is_action_just_pressed("ability"):
			if currentPowerup == PowerupClass.PEANUTBUTTER:
				currentPowerup = PowerupClass.NONE
				dashDirection = Vector3(direction.x, -direction.y, 0)
				startDashTimer()
			if currentPowerup == PowerupClass.BUTTER:
				currentPowerup = PowerupClass.NONE
				startSlideTimer()
	
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
