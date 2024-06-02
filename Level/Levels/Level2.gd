extends Node3D

@export var startLocation : Vector3
@export var respawnTime : float = 0.5


# Called when the node enters the scene tree for the first time.
func _ready():
	print("level 2 ready")
	#$Timer._timer_start()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_debug()
	#$Time_remaining.text = "%s" % roundf($Timer.time_left)


func _on_timer_timeout() -> void:
	print("timer timed out")


# debug statements
func _debug():
	return
	#print_debug("time left:", $Timer.time_lef
