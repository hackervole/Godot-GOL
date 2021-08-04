extends Node2D

const ZOOM_STEP = 0.1

enum {STATE_PREV = 0, STATE_NOW = 1}

# Current zoom
var zoom = 1.0

# Pair of dictionaries holding the state of cells from the current/previous
# iterations
var grids = [{}, {}]
# Dictionary containing existing cells (living and dead)
var cells = {}
# List of candidates positions for cell spawning on the current iteration
var to_check = []

#
## Callbacks

# Handle user input
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			place_cell(event.position)
		if event.button_index == BUTTON_RIGHT and event.pressed:
			remove_cell(event.position)
		if event.button_index == BUTTON_WHEEL_DOWN:
			change_zoom(ZOOM_STEP)
		if event.button_index == BUTTON_WHEEL_UP:
			change_zoom(-ZOOM_STEP)
	if event is InputEventMouseMotion and event.button_mask == BUTTON_MASK_MIDDLE:
		move_camera(event.relative)
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event.is_action_pressed("ui_accept"):
		start_stop()
	if event.is_action_pressed("ui_reset"):
		reset()

# Handle update processing
func _on_Timer_timeout() -> void:
	grids.invert()
	grids[STATE_NOW].clear()

	# Do game stuffs
	regenerate()
	spawn_new_cells()
	colorize_cells()

	print("Step!")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

#
## Game logic

# Get number of living neighbors of the given cell, optionally updating
# the `to_check` list as well.
func get_num_live_cells(pos: Vector2, first_pass : bool = true) -> int:
	var num_live_cells = 0
	for y in [-1, 0, 1]:
		for x in [-1, 0, 1]:
			if x != 0 or y != 0:
				var new_pos = pos + Vector2(x, y)
				if grids[STATE_PREV].has(new_pos):
					if grids[STATE_PREV][new_pos]: # If alive
						num_live_cells += 1
				else:
					if first_pass:
						to_check.append(new_pos)

	return num_live_cells

# Update state of existing cells based on their neighbors
func regenerate() -> void:
	for key in cells.keys():
		var n = get_num_live_cells(key)
		if grids[STATE_PREV][key]: # Alive
			grids[STATE_NOW][key] = (n == 2 or n == 3)
		else: # Dead
			grids[STATE_NOW][key] = (n == 3)

# Adds a new cell at the given location
func add_new_cell(grid_pos: Vector2) -> void:
	var cell = $Cell.duplicate()
	cell.position = grid_pos * 32
	add_child(cell)
	cell.show()
	cells[grid_pos] = cell
	grids[STATE_NOW][grid_pos] = true

# Spawns new cells where there are sufficient neighbors
func spawn_new_cells() -> void:
	for pos in to_check:
		var n = get_num_live_cells(pos, false)
		if n == 3 and not grids[STATE_NOW].has(pos):
			add_new_cell(pos)
	to_check.clear()

# Sets cell colors based on current state
func colorize_cells() -> void:
	for key in cells.keys():
		cells[key].modulate = Color.aqua if grids[STATE_NOW][key] else Color.gray

#
## UI Handling

# Handles start/stopping simulation
func start_stop() -> void:
	if $Timer.is_stopped() and cells.size() > 0:
		$Timer.start()
		print("Starting!")
	else:
		$Timer.stop()
		print("Stopping!")

# Resets state
func reset() -> void:
	$Timer.stop()
	for key in cells.keys():
		cells[key].queue_free()
	grids[STATE_NOW].clear()
	cells.clear()
	print("Reset!")

# Change zoom level
func change_zoom(dz: float) -> void:
	zoom = clamp(zoom + dz, 0.1, 8.0)
	$Camera2D.zoom = Vector2(zoom, zoom)
	print("Zoom ", dz, " ", $Camera2D.zoom, "!")

# Move camera position based on relative mouse position
func move_camera(dv: Vector2) -> void:
	# Scale the movement speed based on zoom (slower at high zoom)
	$Camera2D.offset -= dv * zoom

# Helper to get grid position of mouse click
func get_grid_pos(pos: Vector2) -> Vector2:
	var pixels = 32.0 / $Camera2D.zoom.x
	return pos.snapped(Vector2(pixels, pixels)) / pixels

# Convert mouse position to camera position based on zoom/offset
func mouse_pos_to_cam_pos(pos: Vector2) -> Vector2:
	return pos + ($Camera2D.offset / $Camera2D.zoom) - (get_viewport_rect().size / 2)

# Place cell at clicked position OR revive a dead cell
func place_cell(pos: Vector2) -> void:
	pos = mouse_pos_to_cam_pos(pos)
	pos = get_grid_pos(pos)
	if not cells.has(pos): # No cell present, add
		add_new_cell(pos)
		print("Placed!")
	elif not grids[STATE_NOW][pos]: # Dead cell present, revive
		grids[STATE_NOW][pos] = true
	colorize_cells()

# Remove cell at clicked position
func remove_cell(pos: Vector2) -> void:
	pos = mouse_pos_to_cam_pos(pos)
	pos = get_grid_pos(pos)
	# Check if user clicked occupied position
	if cells.has(pos):
		cells[pos].queue_free()
		cells.erase(pos)
		grids[STATE_NOW].erase(pos)
		print("Removed!")

