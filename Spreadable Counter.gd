extends Label


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func spread(numSpreaded, numSpreadables):
	if numSpreadables != 0:
		text = "%s/%s spreadables spread" % [numSpreaded, numSpreadables]
	else:
		text = ""
