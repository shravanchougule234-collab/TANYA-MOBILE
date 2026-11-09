extends VehicleBody3D
class_name TanyaVehicle

# =====================================
# TANYA OPEN WORLD - VEHICLE SYSTEM (fixed)
# Godot 4 / Android
# Project Settings > Input Devices > Pointing:
#   enable "Emulate Touch From Mouse" to test touch buttons on PC.
# =====================================

@export_group("Vehicle Settings")
@export var vehicle_name := "TANYA Sports Car"
@export var max_engine_force := 1800.0
@export var reverse_force := 900.0
@export var max_brake_force := 55.0
@export var max_steering := 0.48
@export var steering_speed := 2.5
@export var max_speed_kmh := 160.0
@export var coast_brake := 2.0      # slows the car when you release gas
@export var parked_brake := 30.0    # holds the car still when nobody drives

@onready var vehicle_camera: Camera3D = $VehicleCamera/Camera3D
@onready var enter_area: Area3D = $EnterArea

var driver: Node3D
var nearby_player: Node3D
var driving := false
var current_steering := 0.0

var old_collision_layer := 1
var old_collision_mask := 1

var speed_label: Label
var drive_ui: Control   # only visible while driving
var enter_button: Button  # only visible when player is close
var left_pad: Control
var right_pad: Control


func _ready() -> void:
	add_to_group("vehicles")
	setup_input()
	setup_touch_controls()

	enter_area.body_entered.connect(_on_body_entered)
	enter_area.body_exited.connect(_on_body_exited)

	get_viewport().size_changed.connect(_layout_hud)
	_layout_hud()


# =====================================
# INPUT SETUP
# =====================================

func setup_input() -> void:
	add_key_action("accelerate", KEY_W)
	add_key_action("reverse", KEY_S)
	add_key_action("steer_left", KEY_A)
	add_key_action("steer_right", KEY_D)
	add_key_action("handbrake", KEY_SPACE)
	add_key_action("interact", KEY_E)


func add_key_action(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

	# Don't add the same key again when a 2nd vehicle spawns
	for e in InputMap.action_get_events(action):
		if e is InputEventKey and e.physical_keycode == key:
			return

	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)


# =====================================
# PLAYER DETECTION
# =====================================

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not driving:
		nearby_player = body
		enter_button.visible = true


func _on_body_exited(body: Node3D) -> void:
	if body == nearby_player:
		nearby_player = null
		enter_button.visible = false


# =====================================
# ENTER / EXIT VEHICLE
# =====================================

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		if driving:
			exit_vehicle()
		elif nearby_player != null:
			enter_vehicle(nearby_player)


func enter_vehicle(player: Node3D) -> void:
	if driving:
		return

	driver = player
	driving = true

	old_collision_layer = player.collision_layer
	old_collision_mask = player.collision_mask

	player.hide()
	# Hide the player's on-foot touch HUD while the vehicle HUD is active.
	var player_hud := player.get_node_or_null("PlayerMobileHUD")
	if player_hud is CanvasLayer:
		player_hud.visible = false
	player.collision_layer = 0
	player.collision_mask = 0
	player.set_physics_process(false)
	player.set_process(false)

	vehicle_camera.current = true
	nearby_player = null

	enter_button.visible = false
	drive_ui.visible = true


func exit_vehicle() -> void:
	if not driving or driver == null:
		return

	var player := driver

	player.global_position = global_position + global_transform.basis.x * 3.0 + Vector3.UP
	player.show()
	# Restore on-foot touch controls after leaving the vehicle.
	var player_hud := player.get_node_or_null("PlayerMobileHUD")
	if player_hud is CanvasLayer:
		player_hud.visible = true
	player.collision_layer = old_collision_layer
	player.collision_mask = old_collision_mask
	player.set_physics_process(true)
	player.set_process(true)

	# Give the camera back to the player
	vehicle_camera.current = false
	for cam in player.find_children("*", "Camera3D", true, false):
		cam.current = true
		break

	driver = null
	driving = false
	drive_ui.visible = false

	# Release any held touch inputs
	for a in ["accelerate", "reverse", "steer_left", "steer_right", "handbrake"]:
		Input.action_release(a)

	engine_force = 0.0
	brake = max_brake_force


# =====================================
# VEHICLE PHYSICS
# =====================================

func _physics_process(delta: float) -> void:
	if not driving:
		engine_force = 0.0
		brake = parked_brake
		steering = 0.0
		return

	var throttle := Input.get_action_strength("accelerate")
	var reverse_input := Input.get_action_strength("reverse")
	var left := Input.get_action_strength("steer_left")
	var right := Input.get_action_strength("steer_right")

	var speed_kmh := linear_velocity.length() * 3.6
	var forward_speed := linear_velocity.dot(-global_transform.basis.z)

	if throttle > 0.0:
		engine_force = throttle * max_engine_force if speed_kmh < max_speed_kmh else 0.0
		brake = 0.0
	elif reverse_input > 0.0:
		if forward_speed > 2.0:
			# still rolling forward: brake first
			engine_force = 0.0
			brake = reverse_input * max_brake_force
		else:
			engine_force = -reverse_input * reverse_force
			brake = 0.0
	else:
		engine_force = 0.0
		brake = coast_brake

	# STEERING: in Godot, POSITIVE steering turns LEFT
	var steering_input := left - right
	current_steering = move_toward(
		current_steering,
		steering_input * max_steering,
		steering_speed * delta
	)
	steering = current_steering

	if Input.is_action_pressed("handbrake"):
		engine_force = 0.0
		brake = max_brake_force * 1.5

	speed_label.text = str(roundi(speed_kmh)) + " KM/H"


# =====================================
# MOBILE TOUCH CONTROLS
# =====================================

func setup_touch_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "VehicleHUD"
	add_child(layer)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	# Everything that shows only while driving
	drive_ui = Control.new()
	drive_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drive_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drive_ui.visible = false
	root.add_child(drive_ui)

	# Speed display
	var speed_panel := PanelContainer.new()
	speed_panel.position = Vector2(25, 25)
	drive_ui.add_child(speed_panel)

	speed_label = Label.new()
	speed_label.text = "0 KM/H"
	speed_label.add_theme_font_size_override("font_size", 25)
	speed_panel.add_child(speed_label)

	# Pads (positioned in _layout_hud)
	left_pad = Control.new()
	left_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drive_ui.add_child(left_pad)

	right_pad = Control.new()
	right_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drive_ui.add_child(right_pad)

	# TouchScreenButton supports several fingers at once
	# (e.g. hold GAS and steer together). Normal Buttons do not.
	add_touch_button(left_pad, "LEFT", "steer_left", Vector2(50, 0))
	add_touch_button(left_pad, "RIGHT", "steer_right", Vector2(160, 0))
	add_touch_button(right_pad, "GAS", "accelerate", Vector2(50, 0))
	add_touch_button(right_pad, "BRAKE", "reverse", Vector2(160, 0))
	add_touch_button(right_pad, "HAND\nBRAKE", "handbrake", Vector2(50, -95))

	# Exit button
	var exit_button := Button.new()
	exit_button.text = "EXIT CAR"
	exit_button.size = Vector2(120, 65)
	exit_button.position = Vector2(25, 110)
	exit_button.pressed.connect(exit_vehicle)
	drive_ui.add_child(exit_button)

	# Enter button (shown when the player is near)
	enter_button = Button.new()
	enter_button.text = "ENTER CAR"
	enter_button.size = Vector2(180, 70)
	enter_button.visible = false
	enter_button.pressed.connect(func(): if nearby_player: enter_vehicle(nearby_player))
	root.add_child(enter_button)


func add_touch_button(parent: Control, text: String, action: String, pos: Vector2) -> void:
	var size := Vector2(100, 80)

	var btn := TouchScreenButton.new()
	btn.position = pos
	btn.action = action
	btn.passby_press = true

	var shape := RectangleShape2D.new()
	shape.size = size
	btn.shape = shape
	parent.add_child(btn)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.45)
	bg.size = size
	bg.position = -size / 2.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(bg)

	var lbl := Label.new()
	lbl.text = text
	lbl.size = size
	lbl.position = -size / 2.0
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)


# Keeps the buttons in the right place on any screen size
func _layout_hud() -> void:
	if left_pad == null:
		return
	var vp := get_viewport().get_visible_rect().size
	left_pad.position = Vector2(0, vp.y - 70)
	right_pad.position = Vector2(vp.x - 270, vp.y - 70)
	enter_button.position = Vector2((vp.x - enter_button.size.x) / 2.0, vp.y - 120)
