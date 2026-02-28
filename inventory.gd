# inventory.gd
# Pure data model — no UI. Attach this as an Autoload (singleton) or
# add it as a child node and access it via get_node().

class_name INventory
extends Node

signal item_added(slot_index: int)
signal item_removed(slot_index: int)
signal item_moved(from_index: int, to_index: int)
signal inventory_changed

# Each slot is either null or { "item": Item, "count": int }
var slots: Array = []
var size: int = 40  # 5 rows x 8 cols — change to whatever fits your grid


func _ready() -> void:
	slots.resize(size)
	slots.fill(null)


# --- Public API ---

## Add an item. Returns leftover count (0 = fully added).
func add_item(item: Item, count: int = 1) -> int:
	var remaining := count

	# Try stacking onto existing slots first
	if item.max_stack > 1:
		for i in size:
			if remaining <= 0:
				break
			var slot = slots[i]
			if slot != null and slot["item"].id == item.id and slot["count"] < item.max_stack:
				var space := item.max_stack - slot["count"]
				var to_add := mini(space, remaining)
				slot["count"] += to_add
				remaining -= to_add
				item_added.emit(i)
				inventory_changed.emit()

	# Fill empty slots with the rest
	for i in size:
		if remaining <= 0:
			break
		if slots[i] == null:
			var to_add := mini(item.max_stack, remaining)
			slots[i] = { "item": item, "count": to_add }
			remaining -= to_add
			item_added.emit(i)
			inventory_changed.emit()

	return remaining  # > 0 means inventory was full


## Remove `count` of an item by id. Returns how many were actually removed.
func remove_item_by_id(item_id: String, count: int = 1) -> int:
	var removed := 0
	for i in size:
		if removed >= count:
			break
		var slot = slots[i]
		if slot != null and slot["item"].id == item_id:
			var to_remove := mini(slot["count"], count - removed)
			slot["count"] -= to_remove
			removed += to_remove
			if slot["count"] <= 0:
				slots[i] = null
			item_removed.emit(i)
			inventory_changed.emit()
	return removed


## Remove items directly from a specific slot.
func remove_from_slot(slot_index: int, count: int = 1) -> void:
	var slot = slots[slot_index]
	if slot == null:
		return
	slot["count"] -= count
	if slot["count"] <= 0:
		slots[slot_index] = null
	item_removed.emit(slot_index)
	inventory_changed.emit()


## Swap or merge two slots (used for drag-and-drop).
func move_slot(from_index: int, to_index: int) -> void:
	if from_index == to_index:
		return

	var from_slot = slots[from_index]
	var to_slot   = slots[to_index]

	# Try to stack if same item
	if from_slot != null and to_slot != null:
		if from_slot["item"].id == to_slot["item"].id:
			var max_s: int = to_slot["item"].max_stack
			var space := max_s - to_slot["count"]
			var to_move := mini(space, from_slot["count"])
			if to_move > 0:
				to_slot["count"] += to_move
				from_slot["count"] -= to_move
				if from_slot["count"] <= 0:
					slots[from_index] = null
				item_moved.emit(from_index, to_index)
				inventory_changed.emit()
				return

	# Otherwise swap
	slots[to_index]   = from_slot
	slots[from_index] = to_slot
	item_moved.emit(from_index, to_index)
	inventory_changed.emit()


## Returns true if the inventory contains at least `count` of item_id.
func has_item(item_id: String, count: int = 1) -> bool:
	var total := 0
	for slot in slots:
		if slot != null and slot["item"].id == item_id:
			total += slot["count"]
			if total >= count:
				return true
	return false


## Count total of a specific item across all slots.
func count_item(item_id: String) -> int:
	var total := 0
	for slot in slots:
		if slot != null and slot["item"].id == item_id:
			total += slot["count"]
	return total


## Clear the entire inventory.
func clear() -> void:
	slots.fill(null)
	inventory_changed.emit()
