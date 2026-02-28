# inventory_slot.gd
# Attach to a Panel (or TextureRect) node.
# Each slot is a cell in the grid.
#
# Node structure:
#   Panel (inventory_slot.gd)
#   ├── TextureRect  (item icon)      — name it "Icon"
#   └── Label        (stack count)   — name it "CountLabel"

class_name InventorySlot
extends Panel

signal slot_clicked(slot_index: int, button: int)
signal slot_hovered(slot_index: int)
signal slot_unhovered(slot_index: int)

@onready var icon_rect: TextureRect = $Icon
@onready var count_label: Label     = $CountLabel

var slot_index: int = -1
var is_dragging: bool = false

# Visual states — tweak colours to match your theme
const COLOR_NORMAL   := Color(0.15, 0.15, 0.15, 0.9)
const COLOR_HOVER    := Color(0.25, 0.25, 0.25, 1.0)
const COLOR_SELECTED := Color(0.35, 0.6,  0.35, 1.0)
const COLOR_EMPTY    := Color(0.1,  0.1,  0.1,  0.8)


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	refresh(null)


## Call this whenever the underlying inventory data changes.
func refresh(slot_data) -> void:
	if slot_data == null:
		icon_rect.texture = null
		count_label.text  = ""
		self_modulate     = COLOR_EMPTY
	else:
		icon_rect.texture = slot_data["item"].icon
		var count: int = slot_data["count"]
		count_label.text  = str(count) if count > 1 else ""
		self_modulate     = COLOR_NORMAL


func set_selected(selected: bool) -> void:
	self_modulate = COLOR_SELECTED if selected else COLOR_NORMAL


func _on_mouse_entered() -> void:
	if self_modulate != COLOR_SELECTED:
		self_modulate = COLOR_HOVER
	slot_hovered.emit(slot_index)


func _on_mouse_exited() -> void:
	if self_modulate != COLOR_SELECTED:
		self_modulate = COLOR_NORMAL
	slot_unhovered.emit(slot_index)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		slot_clicked.emit(slot_index, event.button_index)
