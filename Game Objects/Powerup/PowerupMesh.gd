extends MeshInstance3D

var t = 0
const amplitude = 0.5
const rotation_rate = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	t += delta
	position.y = sin(t) * amplitude
	rotate_y(rotation_rate * delta)
