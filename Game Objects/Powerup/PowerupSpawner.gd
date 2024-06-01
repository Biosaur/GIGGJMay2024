extends Node3D

@export var objectToSpawn : PackedScene
@export var timeToSpawn : float = 3.0
var spawnedObject : Node3D
var isSpawning = false

func spawn():
	spawnedObject = objectToSpawn.instantiate()
	add_child(spawnedObject)

func startSpawnTimer():
	await get_tree().create_timer(timeToSpawn).timeout
	spawn()
	isSpawning = false

# Called when the node enters the scene tree for the first time.
func _ready():
	spawn()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if get_children().is_empty() and not isSpawning:
		isSpawning = true
		startSpawnTimer()
