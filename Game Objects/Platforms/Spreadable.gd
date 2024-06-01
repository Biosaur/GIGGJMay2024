extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func spread():
	$Unspreaded.visible = !$Unspreaded.visible
	$Spreaded.visible = !$Spreaded.visible 

