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

@export var attackDuration : float = 0.1
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

const attackAnimDuration = 0.3
var isAttackAnimPlaying = false

var lastFacedDirection = Vector2(1, 0)

func updateAnimationFlavour():
	$Anim/BaseAnimation.visible = currentPowerup == PowerupClass.NONE
	$Anim/ButterAnimation.visible = currentPowerup == PowerupClass.BUTTER
	$Anim/JamAnimation.visible = currentPowerup == PowerupClass.JAM
	$Anim/PeanutAnimation.visible = currentPowerup == PowerupClass.PEANUTBUTTER

func setAnimation(animation):
	if not isAttackAnimPlaying or animation == "Attack":
		$Anim/BaseAnimation.play(animation)
		$Anim/ButterAnimation.play(animation)
		$Anim/JamAnimation.play(animation)
		$Anim/PeanutAnimation.play(animation)

func setAnimationFlip(onOrOff : bool):
	$Anim/BaseAnimation.flip_h = onOrOff
	$Anim/ButterAnimation.flip_h = onOrOff
	$Anim/JamAnimation.flip_h = onOrOff
	$Anim/PeanutAnimation.flip_h = onOrOff

func startDashTimer():
	isDashing = true
	await get_tree().create_timer(dashDuration).timeout
	isDashing = false
	velocity = dashDirection * dashVelocity * dashCarryover

func startSlideTimer():
	isSliding = true
	movementSpeed *= slideMultiplier
	floor_max_angle = deg_to_rad(85)
	$"Slippery Rect/AnimationPlayer".play("Slippery")
	await get_tree().create_timer(slideDuration).timeout
	isSliding = false
	movementSpeed /= slideMultiplier
	floor_max_angle = deg_to_rad(45)

func startAttackCooldown():
	canAttack = false
	await get_tree().create_timer(attackCooldown).timeout
	canAttack = true

func startAttackAnimation():
	setAnimation("Attack")
	isAttackAnimPlaying = true
	await get_tree().create_timer(attackAnimDuration).timeout
	isAttackAnimPlaying = false

func startAttackTimer():
	isAttacking = true
	startAttackAnimation()
	startAttackCooldown()
	await get_tree().create_timer(attackDuration).timeout
	$CircularStrikeHitbox.get_child(1).visible = false
	$LongSlashHitbox.get_child(1).visible = false
	$SmallSlashHitbox.get_child(0).disabled = true
	$CircularStrikeHitbox.get_child(0).disabled = true
	$LongSlashHitbox.get_child(0).disabled = true
	isAttacking = false
	
func triggerRecoil(strength : float, recoilFromGlobalPosition : Vector3):
	velocity = strength * (global_position - recoilFromGlobalPosition).normalized()

func _ready():
	$CircularStrikeHitbox.get_child(1).visible = false
	$LongSlashHitbox.get_child(1).visible = false
	$SmallSlashHitbox.get_child(0).disabled = true
	$CircularStrikeHitbox.get_child(0).disabled = true
	$LongSlashHitbox.get_child(0).disabled = true
	updateAnimationFlavour()

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
			projectile.rotation.z = atan2(slashDirection.y, -slashDirection.x) 
			triggerRecoil(attackRecoil, global_position + Vector3(slashDirection.x, -slashDirection.y, 0))
			$SoundEffects/Spread_1.play()
			
	if isDashing:
		velocity = dashDirection * dashVelocity
	else:
		if not is_on_floor():
			velocity.y += (jumpGravity if velocity.y > 0.0 else fallGravity) * delta

		# Handle jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jumpVelocity
			$SoundEffects/Jump.play()

		# Get the input direction and handle the movement/deceleration.
		var oldXVel = velocity.x
		var currTraction = traction if is_on_floor() else airTraction
		if direction.x != 0:
			if not isSliding:
				setAnimation("Run")
			if direction.x < 0.0:
				lastFacedDirection = Vector2(-1, 0)
				setAnimationFlip(true)
				if velocity.x > -movementSpeed:
					velocity.x = move_toward(velocity.x, -movementSpeed, currTraction)
			else:
				lastFacedDirection = Vector2(1, 0)
				setAnimationFlip(false)
				if velocity.x < movementSpeed:
					velocity.x = move_toward(velocity.x, movementSpeed, currTraction)
			if is_on_floor() and $Timer.time_left <= 0.05:
				$SoundEffects/Walking.pitch_scale = randf_range(0.8, 1.2)
				$SoundEffects/Walking.play()
				$Timer.start(0.3)
		else:
			if not isSliding:
				setAnimation("Idle")
			velocity.x = move_toward(velocity.x, 0, currTraction)
			
		if isSliding:
			setAnimation("Slide")
			velocity.x = lerp(velocity.x, oldXVel, slideSlipperiness)
		
		if not is_on_floor():
			if velocity.y > 0:
				setAnimation("Jump")
			else:
				setAnimation("Fall")
		if Input.is_action_just_pressed("ability"):
			if currentPowerup == PowerupClass.PEANUTBUTTER:
				dashDirection = Vector3(direction.x, -direction.y, 0)
				startDashTimer()
				$SoundEffects/Dash.play()
			if currentPowerup == PowerupClass.BUTTER:
				startSlideTimer()
			currentPowerup = PowerupClass.NONE
			updateAnimationFlavour()
		
	move_and_slide()

func _on_hitbox_area_entered(area):
	if area.is_in_group("Powerup"):
		$SoundEffects/Item_Pickup.play()
		if area.owner.is_in_group("Butter"):
			currentPowerup = PowerupClass.BUTTER
			updateAnimationFlavour()
		elif area.owner.is_in_group("PeanutButter"):
			currentPowerup = PowerupClass.PEANUTBUTTER
			updateAnimationFlavour()
		elif area.owner.is_in_group("Jam"):
			currentPowerup = PowerupClass.JAM
			updateAnimationFlavour()
		return
	if area.get_collision_layer_value(2):
		die()
		return
	if area.get_collision_layer_value(3):
		progress()
		return

func die():
	currentPowerup = PowerupClass.NONE
	updateAnimationFlavour()
	dead.emit()

func progress():
	next_level.emit()


func _on_small_slash_hitbox_body_entered(body):
	if body.owner.is_in_group("Spreadable"):
		# No condiment, don't spread
		triggerRecoil(attackRecoil, body.global_position)

func _on_long_slash_hitbox_body_entered(body):
	if body.owner.is_in_group("Spreadable"):
		body.owner.spread("Peanut")
		triggerRecoil(upgradedAttackRecoil, body.global_position)

func _on_circular_strike_hitbox_body_entered(body):
	if body.owner.is_in_group("Spreadable"):
		body.owner.spread("Butter")
		triggerRecoil(upgradedAttackRecoil * 1.3, body.global_position)
