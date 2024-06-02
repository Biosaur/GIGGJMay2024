extends CharacterBody3D

enum PowerupClass {
	NONE,
	BUTTER,
	PEANUTBUTTER,
	JAM
}

const LEVEL_PATH = "res://Level/Levels/Level"

@export var movementSpeed : float = 8.0
@export var traction : float = 1.5
@export var airTraction : float = 0.7

@export var jumpHeight : float = 3.0
@export var jumpTimeToPeak : float = 0.4
@export var jumpTimeToFall : float = 0.3

@onready var jumpVelocity : float = (2.0 * jumpHeight) / jumpTimeToPeak
@onready var jumpGravity : float = (-2.0 * jumpHeight) / (jumpTimeToPeak * jumpTimeToPeak)
@onready var fallGravity : float = (-2.0 * jumpHeight) / (jumpTimeToFall * jumpTimeToFall)

@export var dashDistance : float = 5.0
@export var dashDuration : float = 0.2
@export var dashCarryover : float = 0.3

@onready var dashVelocity : float = dashDistance / dashDuration

@export var slideMultiplier : float = 4.0
@export var slideDuration : float = 3.0
@export var slideSlipperiness : float = 0.2

@export var attackDuration : float = 0.2
@export var attackCooldown : float = 0.3

@export var projectileToFire : PackedScene
@export var attackRecoil : float = 10
@export var upgradedAttackRecoil : float = 20

signal dead
signal next_level

var currentPowerup = PowerupClass.NONE
var dashDirection = Vector3()
var isDashing = false
var isSliding = false

var isAttacking = false
var canAttack = true

var lastFacedDirection = Vector2(1, 0)

func startDashTimer():
	isDashing = true
	await get_tree().create_timer(dashDuration).timeout
	isDashing = false
	velocity = dashDirection * dashVelocity * dashCarryover

func startSlideTimer():
	isSliding = true
	movementSpeed *= slideMultiplier
	floor_max_angle = deg_to_rad(85)
	await get_tree().create_timer(slideDuration).timeout
	isSliding = false
	movementSpeed /= slideMultiplier
	floor_max_angle = deg_to_rad(45)

func startAttackCooldown():
	canAttack = false
	await get_tree().create_timer(attackCooldown).timeout
	canAttack = true

func startAttackTimer():
	isAttacking = true
	startAttackCooldown()
	await get_tree().create_timer(attackDuration).timeout
	$SmallSlashHitbox.get_child(1).visible = false
	$CircularStrikeHitbox.get_child(1).visible = false
	$LongSlashHitbox.get_child(1).visible = false
	$SmallSlashHitbox.get_child(0).disabled = true
	$CircularStrikeHitbox.get_child(0).disabled = true
	$LongSlashHitbox.get_child(0).disabled = true
	isAttacking = false
	
func triggerRecoil(strength : float, recoilFromGlobalPosition : Vector3):
	velocity += strength * (global_position - recoilFromGlobalPosition).normalized()

func _physics_process(delta):
	# Add the gravity.
	position.z = 0.5
	velocity.z = 0

	var direction = Input.get_vector("left", "right", "up", "down")
	
	if Input.is_action_just_pressed("attack") and canAttack:
		var slashDirection = direction if direction else lastFacedDirection
		startAttackTimer()
		if currentPowerup == PowerupClass.NONE:
			$SmallSlashHitbox.position = Vector3(slashDirection.x, -slashDirection.y, 0)
			$SmallSlashHitbox.rotation.z = atan2(slashDirection.y, -slashDirection.x) + PI/2
			$SmallSlashHitbox.get_child(1).visible = true
			$SmallSlashHitbox.get_child(0).disabled = false
		if currentPowerup == PowerupClass.BUTTER:
			$CircularStrikeHitbox.get_child(1).visible = true
			$CircularStrikeHitbox.get_child(0).disabled = false
		if currentPowerup == PowerupClass.PEANUTBUTTER:
			$LongSlashHitbox.position = Vector3(slashDirection.x, -slashDirection.y, 0) * 3
			$LongSlashHitbox.rotation.z = atan2(slashDirection.y, -slashDirection.x) + PI/2
			$LongSlashHitbox.get_child(1).visible = true
			$LongSlashHitbox.get_child(0).disabled = false
		if currentPowerup == PowerupClass.JAM:
			var projectile = projectileToFire.instantiate()
			add_sibling(projectile)
			projectile.global_position = global_position
			projectile.velocity = Vector2(slashDirection.x, -slashDirection.y) * 20
			triggerRecoil(attackRecoil, global_position + Vector3(slashDirection.x, -slashDirection.y, 0))
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
		var currTraction = traction if is_on_floor() else airTraction
		if direction.x != 0:
			if direction.x < 0.0:
				lastFacedDirection = Vector2(-1, 0)
				if velocity.x > -movementSpeed:
					velocity.x = move_toward(velocity.x, -movementSpeed, currTraction)
			else:
				lastFacedDirection = Vector2(1, 0)
				if velocity.x < movementSpeed:
					velocity.x = move_toward(velocity.x, movementSpeed, currTraction)
		else:
			velocity.x = move_toward(velocity.x, 0, currTraction)
			
		if isSliding:
			velocity.x = lerp(velocity.x, oldXVel, slideSlipperiness)

		if Input.is_action_just_pressed("ability"):
			if currentPowerup == PowerupClass.PEANUTBUTTER:
				dashDirection = Vector3(direction.x, -direction.y, 0)
				startDashTimer()
			if currentPowerup == PowerupClass.BUTTER:
				startSlideTimer()
			currentPowerup = PowerupClass.NONE
	
	move_and_slide()

func _on_hitbox_area_entered(area):
	if area.is_in_group("Powerup"):
		if area.owner.is_in_group("Butter"):
			currentPowerup = PowerupClass.BUTTER
		elif area.owner.is_in_group("PeanutButter"):
			currentPowerup = PowerupClass.PEANUTBUTTER
		elif area.owner.is_in_group("Jam"):
			currentPowerup = PowerupClass.JAM
		return
	if area.get_collision_layer_value(2):
		die()
		return
	if area.get_collision_layer_value(3):
		progress()
		return

func die():
	dead.emit()

func progress():
	next_level.emit()


func _on_small_slash_hitbox_body_entered(body):
	if body.owner.is_in_group("Spreadable"):
		# No condiment, don't spread
		triggerRecoil(attackRecoil, body.global_position)

func _on_long_slash_hitbox_body_entered(body):
	if body.owner.is_in_group("Spreadable"):
		body.owner.spread()
		triggerRecoil(upgradedAttackRecoil, body.global_position)

func _on_circular_strike_hitbox_body_entered(body):
	if body.owner.is_in_group("Spreadable"):
		body.owner.spread()
		triggerRecoil(upgradedAttackRecoil, body.global_position)
