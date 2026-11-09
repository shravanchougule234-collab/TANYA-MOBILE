extends CharacterBody3D

@export var move_speed: float = 6.0
@export var jump_velocity: float = 4.5
@export var gravity: float = 9.8

var mobile_layer: CanvasLayer
var mobile_root: Control

func _ready() -> void:
    add_to_group("player")
    _setup_actions()
    _setup_mobile_controls()

func _setup_actions() -> void:
    _ensure_action("move_left", KEY_A)
    _ensure_action("move_right", KEY_D)
    _ensure_action("move_forward", KEY_W)
    _ensure_action("move_back", KEY_S)
    _ensure_action("jump", KEY_SPACE)

func _ensure_action(action_name: String, key_code: Key) -> void:
    if not InputMap.has_action(action_name):
        InputMap.add_action(action_name)
    for event in InputMap.action_get_events(action_name):
        if event is InputEventKey and event.physical_keycode == key_code:
            return
    var key_event := InputEventKey.new()
    key_event.physical_keycode = key_code
    InputMap.action_add_event(action_name, key_event)

func set_mobile_controls_visible(is_visible: bool) -> void:
    if mobile_layer != null:
        mobile_layer.visible = is_visible

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0

    var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := Vector3(input_vector.x, 0.0, input_vector.y).rotated(Vector3.UP, rotation.y)
    if direction.length() > 0.01:
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
        rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 8.0)
    else:
        velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 3.0)
        velocity.z = move_toward(velocity.z, 0.0, move_speed * delta * 3.0)

    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity
    move_and_slide()

func _setup_mobile_controls() -> void:
    mobile_layer = CanvasLayer.new()
    mobile_layer.name = "PlayerMobileHUD"
    add_child(mobile_layer)

    mobile_root = Control.new()
    mobile_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mobile_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    mobile_layer.add_child(mobile_root)

    _add_touch_control("◀", "move_left", Vector2(65, -145), Vector2(82, 82))
    _add_touch_control("▶", "move_right", Vector2(245, -145), Vector2(82, 82))
    _add_touch_control("▲", "move_forward", Vector2(155, -235), Vector2(82, 82))
    _add_touch_control("▼", "move_back", Vector2(155, -55), Vector2(82, 82))
    _add_touch_control("JUMP", "jump", Vector2(-145, -125), Vector2(110, 82))
    _layout_mobile_controls()
    get_viewport().size_changed.connect(_layout_mobile_controls)

func _add_touch_control(label_text: String, action_name: String, offset: Vector2, button_size: Vector2) -> void:
    var button := TouchScreenButton.new()
    button.name = "Touch_" + action_name
    button.action = action_name
    button.shape = RectangleShape2D.new()
    (button.shape as RectangleShape2D).size = button_size
    button.position = offset
    mobile_root.add_child(button)

    var background := ColorRect.new()
    background.size = button_size
    background.position = -button_size * 0.5
    background.color = Color(0.05, 0.08, 0.12, 0.62)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    button.add_child(background)

    var label := Label.new()
    label.text = label_text
    label.size = button_size
    label.position = -button_size * 0.5
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 20)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    button.add_child(label)

func _layout_mobile_controls() -> void:
    if mobile_root == null:
        return
    var viewport_size := get_viewport().get_visible_rect().size
    var left_center := Vector2(195, viewport_size.y - 155)
    var right_center := Vector2(viewport_size.x - 95, viewport_size.y - 125)
    var positions := {
        "Touch_move_left": left_center + Vector2(-90, 0),
        "Touch_move_right": left_center + Vector2(90, 0),
        "Touch_move_forward": left_center + Vector2(0, -90),
        "Touch_move_back": left_center + Vector2(0, 90),
        "Touch_jump": right_center
    }
    for child in mobile_root.get_children():
        if child is TouchScreenButton and positions.has(child.name):
            child.position = positions[child.name]
