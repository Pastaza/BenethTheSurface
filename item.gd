# item.gd
# A Resource representing a single item type.
# Create these as .tres files in your project: res://items/sword.tres, etc.

class_name Item
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D = null
@export var max_stack: int = 64        # 1 = not stackable (weapons, armor, etc.)
@export var category: String = "misc"  # e.g. "weapon", "consumable", "misc"
