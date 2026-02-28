# inventory_ui.gd
# Attach to a Control node. Builds the slot grid and handles
# drag-and-drop, selection, and tooltip display.
#
# Recommended node structure:
#   Control  (inventory_ui.gd)
#   ├── Panel              (background)
#   ├── GridContainer      (name it "Grid")
#   ├── Control            (name it "DragPreview")  — floats under cursor
#   │   └── TextureRect    (name it "DragIcon")
#   └── Panel              (name it "Tooltip")
#       ├── Label          (name it "TooltipName")
#       └── Label          (name it "TooltipDesc")

class_name InventoryUI
extends Control

@export var inventory: Inventory          # Drag your Inventory node here in the Inspector
@export var columns: int = 8              # Grid columns (rows = inventory.size / columns)
@export var slot_scene: PackedScene       # Drag your InventorySlot scene here

@onready var grid: GridContainer     = $Grid
@onready var drag_preview: Control   = $DragPreview
@onready var drag_icon: TextureRect  = $DragPreview/DragIcon
@onready var tooltip: Panel          = $Tooltip
@onready var tooltip_name: Label     = $Tooltip/TooltipName
@onready var tooltip_desc: Label     = $Tooltip/TooltipDesc

var slot_nodes: Array[InventorySlot] = []
var drag_from_index: int = -1   # -1 = not dragging
var selected_index:  int = -1


func _ready() -> void:
	grid.columns = columns
	_build_grid()
	inventory.inventory_changed.connect(_refresh_all)
	drag_preview.hide()
	tooltip.hide()


func _build_grid() -> void:
	for i in inventory.size:
		var slot: InventorySlot = slot_scene.instantiate()
		slot.slot_index = i
		slot.slot_clicked.connect(_on_slot_clicked)
		slot.slot_hovered.connect(_on_slot_hovered)
		slot.slot_unhovered.connect(_on_slot_unhovered)
		grid.add_child(slot)
		slot_nodes.append(slot)
	_refresh_all()


func _refresh_all() -> void:
	for i in slot_nodes.size():
		slot_nodes[i].refresh(inventory.slots[i])


# --- Input: drag preview follows mouse ---
func _process(_delta: float) -> void:
	if drag_from_index >= 0:
		drag_preview.global_position = get_global_mouse_position() - drag_icon.size * 0.5


# --- Slot interaction ---
func _on_slot_clicked(slot_index: int, button: int) -> void:
	# LEFT click — pick up / place / swap
	if button == MOUSE_BUTTON_LEFT:
		if drag_from_index == -1:
			# Pick up from this slot
			if inventory.slots[slot_index] != null:
				drag_from_index = slot_index
				drag_icon.texture = inventory.slots[slot_index]["item"].icon
				drag_preview.show()
		else:
			# Drop onto this slot
			inventory.move_slot(drag_from_index, slot_index)
			_end_drag()

	# RIGHT click — drop single item while dragging, or remove stack
	elif button == MOUSE_BUTTON_RIGHT:
		if drag_from_index >= 0 and drag_from_index != slot_index:
			# Place one item from the dragged stack into this slot
			_place_one(drag_from_index, slot_index)
		else:
			# Just select / deselect for info
			_toggle_select(slot_index)


func _place_one(from_index: int, to_index: int) -> void:
	var from_slot = inventory.slots[from_index]
	if from_slot == null:
		return

	var to_slot = inventory.slots[to_index]
	var item: Item = from_slot["item"]

	if to_slot == null:
		# Empty destination — place one
		inventory.slots[to_index] = { "item": item, "count": 1 }
		from_slot["count"] -= 1
		if from_slot["count"] <= 0:
			inventory.slots[from_index] = null
			_end_drag()
	elif to_slot["item"].id == item.id and to_slot["count"] < item.max_stack:
		# Same item, room to stack
		to_slot["count"] += 1
		from_slot["count"] -= 1
		if from_slot["count"] <= 0:
			inventory.slots[from_index] = null
			_end_drag()

	inventory.inventory_changed.emit()


func _end_drag() -> void:
	drag_from_index = -1
	drag_preview.hide()
	_refresh_all()


func _toggle_select(slot_index: int) -> void:
	if selected_index == slot_index:
		slot_nodes[selected_index].set_selected(false)
		selected_index = -1
	else:
		if selected_index >= 0:
			slot_nodes[selected_index].set_selected(false)
		selected_index = slot_index
		slot_nodes[slot_index].set_selected(true)


# --- Tooltip ---
func _on_slot_hovered(slot_index: int) -> void:
	var slot_data = inventory.slots[slot_index]
	if slot_data == null:
		tooltip.hide()
		return
	var item: Item = slot_data["item"]
	tooltip_name.text = item.name
	tooltip_desc.text = item.description
	tooltip.show()
	# Position tooltip near cursor, keep it on-screen
	var mouse := get_global_mouse_position()
	var tp_size := tooltip.size
	tooltip.global_position = Vector2(
		clamp(mouse.x + 16, 0, get_viewport_rect().size.x - tp_size.x),
		clamp(mouse.y + 16, 0, get_viewport_rect().size.y - tp_size.y)
	)


func _on_slot_unhovered(_slot_index: int) -> void:
	tooltip.hide()


# --- Cancel drag with Escape ---
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and drag_from_index >= 0:
		_end_drag()
