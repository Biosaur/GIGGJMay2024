extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	$Timer._timer_start()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_debug()
	$Time_remaining.text = "%s" % roundf($Timer.time_left)


func _on_timer_timeout() -> void:
	print("timer timed out")
	#if $Player.visible:
	#	$Player.hide()
	#else:
	#	$Player.show()

# debug statements
func _debug():
	#print_debug("time left:", $Timer.time_left)
