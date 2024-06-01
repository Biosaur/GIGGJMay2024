extends Timer


# Called when the node enters the scene tree for the first time.
func _ready():
	print("timer ready")

func _timer_start():
	print("timer started")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
