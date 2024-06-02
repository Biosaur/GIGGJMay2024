extends Node
const LEVEL_PATH = "res://Level/Levels/Level"
var timer = null
var timer_text = null
var current_level = null

# Called when the node enters the scene tree for the first time.
func _ready():
	var player = find_child("Player")
	current_level = get_child(2)
	timer = current_level.get_node("Timer")
	timer._timer_start()
	timer_text = current_level.get_node("Time_remaining")
	
	player.next_level.connect(_on_next_level)
	player.dead.connect(_on_player_death)
	

func _on_next_level():
	var next_level_path = LEVEL_PATH + str(current_level.scene_file_path.to_int() + 1) + ".tscn"
	print(next_level_path)
	var newLevel:PackedScene = load(next_level_path)
	remove_child(current_level)
	current_level = newLevel.instantiate()
	add_child(current_level)
	var player = current_level.get_child(0)
	player.next_level.connect(_on_next_level)
	player.dead.connect(_on_player_death)
	
	timer = current_level.get_node("Timer")
	timer._timer_start()
	timer_text = current_level.get_node("Time_remaining")

func _process(delta):
	timer_text.text = "%s" % roundf(timer.time_left)

func _on_timer_timeout() -> void:
	print("timer timed out")

func _on_pause_button_pressed():
	$Control.get_child(0).release_focus()
	get_tree().paused = !get_tree().paused

func _on_player_death():
	var player = current_level.get_child(0)
	var playerCamera = player.find_child("Camera3D")
	$Camera3D.global_position = playerCamera.global_position
	$Camera3D.make_current()
	await get_tree().create_timer(current_level.respawnTime).timeout
	player.position = current_level.startLocation
	playerCamera.make_current()
