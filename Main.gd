extends Node

var texture_run = load("res://images/Arrow.png")
var texture_pause = load("res://images/Pause.png")

onready var _pause_run_indicator : Sprite = $CanvasLayer/PauseRunIndicator
onready var _speed_label : Label = $CanvasLayer/SpeedLabel

# Handle user input
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event.is_action_pressed("ui_accept"):
		start_stop()
	if event.is_action_pressed("ui_reset"):
		reset()
	if event.is_action_pressed("ui_speed_up"):
		$World.speed_up()
		update_speed()
	if event.is_action_pressed("ui_speed_down"):
		$World.slow_down()
		update_speed()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_speed()

func update_speed() -> void:
	_speed_label.text = "Speed: %dx" % $World.get_speed()


func start_stop() -> void:
	if not $World.running():
		if $World.start():
			# Started
			_pause_run_indicator.texture = texture_run
	else:
		$World.stop()
		_pause_run_indicator.texture = texture_pause

func reset() -> void:
	$World.reset()
