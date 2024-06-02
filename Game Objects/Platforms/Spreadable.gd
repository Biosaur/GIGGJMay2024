extends Node3D

@export var is_spreaded: bool = false

signal spreaded

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func spread(spreadType):
	if not is_spreaded:
		$Unspreaded.hide()
		is_spreaded = true
		spreaded.emit()
		if spreadType == "Butter":
			$Buttered.show()
		elif spreadType == "Peanut":
			$Peanutted.show()
		elif spreadType == "Jam":
			$Jammed.show()

