extends Sprite2D

func _ready() -> void:
	add_to_group("items")
	set_meta("item_resource", load("res://items/stick.tres"))
