extends Node

signal item_added(slot_index: int)
signal item_removed(slot_index: int)
signal item_moved(from_index: int, to_index: int)
signal inventory_changed

var slots: Array = []
var size: int = 40


func _ready() -> void:
	slots.resize(size)
	slots.fill(null)


func add_item(item, count: int = 1) -> int:
	var remaining: int = count

	if item.max_stack > 1:
		for i in size:
			if remaining <= 0:
				break
			var slot = slots[i]
			if slot != null and slot["item"].id == item.id and slot["count"] < item.max_stack:
				var space: int = item.max_stack - slot["count"]
				var to_add: int = mini(space, remaining)
				slot["count"] += to_add
				remaining -= to_add
				item_added.emit(i)
				inventory_changed.emit()

	for i in size:
		if remaining <= 0:
			break
		if slots[i] == null:
			var to_add: int = mini(item.max_stack, remaining)
			slots[i] = { "item": item, "count": to_add }
			remaining -= to_add
			item_added.emit(i)
			inventory_changed.emit()

	return remaining


func remove_item_by_id(item_id: String, count: int = 1) -> int:
	var removed: int = 0
	for i in size:
		if removed >= count:
			break
		var slot = slots[i]
		if slot != null and slot["item"].id == item_id:
			var to_remove: int = mini(slot["count"], count - removed)
			slot["count"] -= to_remove
			removed += to_remove
			if slot["count"] <= 0:
				slots[i] = null
			item_removed.emit(i)
			inventory_changed.emit()
	return removed


func remove_from_slot(slot_index: int, count: int = 1) -> void:
	var slot = slots[slot_index]
	if slot == null:
		return
	slot["count"] -= count
	if slot["count"] <= 0:
		slots[slot_index] = null
	item_removed.emit(slot_index)
	inventory_changed.emit()


func move_slot(from_index: int, to_index: int) -> void:
	if from_index == to_index:
		return
	var from_slot = slots[from_index]
	var to_slot = slots[to_index]
	if from_slot != null and to_slot != null:
		if from_slot["item"].id == to_slot["item"].id:
			var max_s: int = to_slot["item"].max_stack
			var space: int = max_s - to_slot["count"]
			var to_move: int = mini(space, from_slot["count"])
			if to_move > 0:
				to_slot["count"] += to_move
				from_slot["count"] -= to_move
				if from_slot["count"] <= 0:
					slots[from_index] = null
				item_moved.emit(from_index, to_index)
				inventory_changed.emit()
				return
	slots[to_index] = from_slot
	slots[from_index] = to_slot
	item_moved.emit(from_index, to_index)
	inventory_changed.emit()


func has_item(item_id: String, count: int = 1) -> bool:
	var total: int = 0
	for slot in slots:
		if slot != null and slot["item"].id == item_id:
			total += slot["count"]
			if total >= count:
				return true
	return false


func count_item(item_id: String) -> int:
	var total: int = 0
	for slot in slots:
		if slot != null and slot["item"].id == item_id:
			total += slot["count"]
	return total


func clear() -> void:
	slots.fill(null)
	inventory_changed.emit()
