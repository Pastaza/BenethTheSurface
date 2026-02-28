extends CharacterBody2D

# --- Movement Settings ---
@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var step_height: float = 5.0  # Max ledge height to auto step over

# --- Gravity ---
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- Item Pickup ---
# Press F (or remap "pickup" in Input Map) while overlapping an item world node.
# Item world nodes must:
#   1. Be in the "items" group
#   2. Have set_meta("item_resource", my_item_resource) on them
#   3. Have an Area2D (or be an Area2D) with collision overlapping the player

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			_try_pickup()


func _try_pickup() -> void:
	print(INventory)
	print("--- Trying pickup ---")
	var item_nodes: Array = get_tree().get_nodes_in_group("items")
	print("Items in group: ", item_nodes.size())
	for node in item_nodes:
		var item_node: Node2D = node as Node2D
		if item_node == null:
			print("Node is not Node2D, skipping")
			continue
		var dist: float = global_position.distance_to(item_node.global_position)
		print("Distance to item: ", dist)
		if dist <= 100.0:
			print("In range!")
			if not item_node.has_meta("item_resource"):
				print("No item_resource meta found on node!")
				continue
			var item: Item = item_node.get_meta("item_resource") as Item
			if item == null:
				print("item_resource meta is not an Item resource!")
				continue
			var leftover: int = INventory.add_item(item, 1)
			if leftover == 0:
				item_node.queue_free()
				print("Picked up: ", item.name)
			else:
				print("Inventory full!")
			return
		else:
			print("Too far away: ", dist)


func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Horizontal movement
	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * speed if direction != 0 else move_toward(velocity.x, 0, speed)

	move_and_slide()

	# After sliding, if we're blocked horizontally, try to step up
	if is_on_floor() and direction != 0 and get_slide_collision_count() > 0:
		_try_step_up(direction)


func _try_step_up(direction: float) -> void:
	var forward: Vector2 = Vector2(direction, 0.0)
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state

	# Ray 1: Is there a wall directly ahead at our feet?
	var ray_params: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + forward * 20.0
	)
	ray_params.exclude = [self]
	ray_params.collision_mask = collision_mask

	var wall_hit: Dictionary = space.intersect_ray(ray_params)
	if wall_hit.is_empty():
		return  # Nothing blocking, no step needed

	# Ray 2: Is the path clear if we were step_height higher?
	var raised_origin: Vector2 = global_position + Vector2(0.0, -step_height)
	var raised_ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		raised_origin,
		raised_origin + forward * 20.0
	)
	raised_ray.exclude = [self]
	raised_ray.collision_mask = collision_mask

	var raised_hit: Dictionary = space.intersect_ray(raised_ray)
	if not raised_hit.is_empty():
		return  # Still blocked even higher, obstacle too tall

	# Ray 3: Is there ground to land on at the stepped position?
	var step_land_origin: Vector2 = raised_origin + forward * 20.0
	var ground_ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		step_land_origin,
		step_land_origin + Vector2(0.0, step_height + 2.0)
	)
	ground_ray.exclude = [self]
	ground_ray.collision_mask = collision_mask

	var ground_hit: Dictionary = space.intersect_ray(ground_ray)
	if ground_hit.is_empty():
		return  # No ground to land on

	# All clear — snap up!
	global_position.y -= step_height
