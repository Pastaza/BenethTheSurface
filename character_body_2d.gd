extends CharacterBody2D

# --- Movement Settings ---
@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var step_height: float = 5.0

# --- Gravity ---
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			_try_pickup()


func _try_pickup() -> void:
	var inventory_node: Node = null
	for child in get_tree().root.get_children():
		if child.name == "INventory":
			inventory_node = child
			break

	if inventory_node == null:
		print("ERROR: INventory autoload not found!")
		return

	var item_nodes: Array = get_tree().get_nodes_in_group("items")
	for node in item_nodes:
		var item_node: Node2D = node as Node2D
		if item_node == null:
			continue
		var dist: float = global_position.distance_to(item_node.global_position)
		if dist <= 100.0:
			if not item_node.has_meta("item_resource"):
				print("ERROR: No item_resource meta!")
				continue
			var item = item_node.get_meta("item_resource")
			if item == null:
				print("ERROR: item_resource is null!")
				continue
			var leftover: int = inventory_node.add_item(item, 1)
			if leftover == 0:
				item_node.queue_free()
				print("Picked up: ", item.name)
			else:
				print("Inventory full!")
			return


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * speed if direction != 0 else move_toward(velocity.x, 0, speed)

	move_and_slide()

	if is_on_floor() and direction != 0 and get_slide_collision_count() > 0:
		_try_step_up(direction)


func _try_step_up(direction: float) -> void:
	var forward: Vector2 = Vector2(direction, 0.0)
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state

	var ray_params: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + forward * 20.0
	)
	ray_params.exclude = [self]
	ray_params.collision_mask = collision_mask

	var wall_hit: Dictionary = space.intersect_ray(ray_params)
	if wall_hit.is_empty():
		return

	var raised_origin: Vector2 = global_position + Vector2(0.0, -step_height)
	var raised_ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		raised_origin,
		raised_origin + forward * 20.0
	)
	raised_ray.exclude = [self]
	raised_ray.collision_mask = collision_mask

	var raised_hit: Dictionary = space.intersect_ray(raised_ray)
	if not raised_hit.is_empty():
		return

	var step_land_origin: Vector2 = raised_origin + forward * 20.0
	var ground_ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		step_land_origin,
		step_land_origin + Vector2(0.0, step_height + 2.0)
	)
	ground_ray.exclude = [self]
	ground_ray.collision_mask = collision_mask

	var ground_hit: Dictionary = space.intersect_ray(ground_ray)
	if ground_hit.is_empty():
		return

	global_position.y -= step_height
