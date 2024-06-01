extends Node
const LEVEL_PATH = "res://Level/Levels/Level"

# Called when the node enters the scene tree for the first time.
func _ready():
	var player = find_child("Player").get_child(0)
	player.next_level.connect(_on_next_level)

func _on_next_level():
	var current_level = get_child(1)
	var next_level_path = LEVEL_PATH + str(current_level.scene_file_path.to_int() + 1) + ".tscn"
	print(next_level_path)
	var newLevel:PackedScene = load(next_level_path)
	remove_child(current_level)
	add_child(newLevel.instantiate())
	var player = get_child(1).get_child(0).get_child(0)
	player.next_level.connect(_on_next_level)



func _on_pause_button_pressed():
	get_child(0).get_child(0).get_child(0).release_focus()
	get_tree().paused = !get_tree().paused
