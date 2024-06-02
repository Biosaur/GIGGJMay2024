extends Area3D

@export var velocity = Vector2()
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position += Vector3(velocity.x, velocity.y, 0) * delta


func _on_area_entered(area):
	if not area.is_in_group("Player"):
		queue_free()


func _on_body_entered(body):
	if not body.is_in_group("Player"):
		queue_free()
