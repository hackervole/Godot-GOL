extends Node2D

const ZOOM_STEP = 0.1

var zoom = 1.0

var grids = [{}, {}]
var cells = {}
var to_check = []

func _unhandled_input(event):
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

func _on_Timer_timeout():
	grids.invert()
	grids[1].clear()

	# Do game stuffs
	regenerate()
	spawn_new_cells()
	colorize_cells()

	print("Step!")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func regenerate():
	for key in cells.keys():
		var n = get_num_live_cells(key)
		if grids[0][key]: # Alive
			grids[1][key] = (n == 2 or n == 3)
		else: # Dead
			grids[1][key] = (n == 3)

func get_num_live_cells(pos: Vector2, first_pass := true):
	var num_live_cells = 0
	for y in [-1, 0, 1]:
		for x in [-1, 0, 1]:
			if x != 0 or y != 0:
				var new_pos = pos + Vector2(x, y)
				if grids[0].has(new_pos):
					if grids[0][new_pos]: # If alive
						num_live_cells += 1
				else:
					if first_pass:
						to_check.append(new_pos)

	return num_live_cells

func spawn_new_cells():
	for pos in to_check:
		var n = get_num_live_cells(pos, false)
		if n == 3 and not grids[1].has(pos):
			add_new_cell(pos)
	to_check.clear()

func add_new_cell(grid_pos: Vector2):
	var cell = $Cell.duplicate()
	cell.position = grid_pos * 32
	add_child(cell)
	cell.show()
	cells[grid_pos] = cell
	grids[1][grid_pos] = true

func colorize_cells():
	for key in cells.keys():
		cells[key].modulate = Color.aqua if grids[1][key] else Color.gray

func start_stop():
	if $Timer.is_stopped() and cells.size() > 0:
		$Timer.start()
		print("Starting!")
	else:
		$Timer.stop()
		print("Stopping!")

func reset():
	$Timer.stop()
	for key in cells.keys():
		cells[key].queue_free()
	grids[1].clear()
	cells.clear()
	print("Reset!")

func change_zoom(dz: float):
	zoom = clamp(zoom + dz, 0.1, 8.0)
	$Camera2D.zoom = Vector2(zoom, zoom)
	print("Zoom ", dz, " ", $Camera2D.zoom, "!")

func move_camera(dv: Vector2):
	$Camera2D.offset -= dv * zoom
	print("Move camera!")

func get_grid_pos(pos: Vector2) -> Vector2:
	var pixels = 32.0 / $Camera2D.zoom.x
	return pos.snapped(Vector2(pixels, pixels)) / pixels

func mouse_pos_to_cam_pos(pos: Vector2) -> Vector2:
	return pos + ($Camera2D.offset / $Camera2D.zoom) - (get_viewport_rect().size / 2)

func place_cell(pos: Vector2):
	pos = mouse_pos_to_cam_pos(pos)
	pos = get_grid_pos(pos)
	if not cells.has(pos): # No cell present, add
		add_new_cell(pos)
		print("Placed!")
	elif not grids[1][pos]: # Dead cell present, revive
		grids[1][pos] = true
	colorize_cells()

func remove_cell(pos: Vector2):
	pos = mouse_pos_to_cam_pos(pos)
	pos = get_grid_pos(pos)
	# Check if user clicked occupied position
	if cells.has(pos):
		cells[pos].queue_free()
		cells.erase(pos)
		grids[1].erase(pos)
		print("Removed!")

