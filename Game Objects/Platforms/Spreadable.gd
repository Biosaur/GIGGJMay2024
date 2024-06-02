extends Node3D

@export var is_spreaded: bool = false

signal spreaded

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func spread():
	if not is_spreaded:
		$Unspreaded.hide()
		$Spreaded.show()
		is_spreaded = true
		spreaded.emit()

