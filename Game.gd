extends Node
const LEVEL_PATH = "res://Level/Levels/Level"
var timer = null
var timer_text = null
var current_level = null
var numSpreadables = 0
var numSpreaded = 0

signal spreadWarning

# Called when the node enters the scene tree for the first time.
func _ready():
	timer = $Level/Timer
	timer._timer_start()
	timer_text = $Level/Time_remaining
	
	$Level/Player.next_level.connect(_on_next_level)
	$Level/Player.dead.connect(_on_player_death)
	

func _on_next_level():
	if numSpreadables == numSpreaded:
		var next_level_path = LEVEL_PATH + str($Level.scene_file_path.to_int() + 1) + ".tscn"
		var newLevel:PackedScene = load(next_level_path)
		get_tree().paused = true
		$"Control/Screen Transition Rect/AnimationPlayer".play("Swipe1")
		await get_tree().create_timer($Level.respawnTime).timeout
		remove_child($Level)
		var current_level = newLevel.instantiate()
		add_child(current_level)
		$"Control/Screen Transition Rect/AnimationPlayer".play("Swipe2")
		get_tree().paused = false
		$Level/Player.next_level.connect(_on_next_level)
		$Level/Player.dead.connect(_on_player_death)
		
		var spreadables = get_tree().get_nodes_in_group("Spreadable")
		numSpreadables = len(spreadables)
		numSpreaded = 0
		for s in spreadables:
			s.spreaded.connect(_on_spread)
		
		# Re-initialize the timer for the next level
		timer = $Level/Timer
		$Level/Timer._timer_start()
		timer_text = $Level/Time_remaining
	else: 
		$"Control/MarginContainer/Spreadable Warning".show()
		await get_tree().create_timer(3).timeout
		$"Control/MarginContainer/Spreadable Warning".hide()

func _process(delta):
	timer_text.text = "%s" % roundf(timer.time_left)

func _on_timer_timeout() -> void:
	print("timer timed out")

func _on_pause_button_pressed():
	$Control.get_child(0).release_focus()
	get_tree().paused = !get_tree().paused

func _on_player_death():
	$Camera3D.global_position = $Level/Player/SpringArm3D/Camera3D.global_position
	$Camera3D.make_current()
	$"Control/Screen Transition Rect/AnimationPlayer".play("Swipe1")
	await get_tree().create_timer($Level.respawnTime).timeout
	$"Control/Screen Transition Rect/AnimationPlayer".play("Swipe2")
	$Level/Player.position = $Level.startLocation
	$Level/Player/SpringArm3D/Camera3D.make_current()

func _on_spread():
	numSpreaded += 1
	$"Control/MarginContainer/Spreadable Counter".spread(numSpreaded, numSpreadables)
	
