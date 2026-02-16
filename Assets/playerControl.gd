extends SpringArm3D

@export var mouseSensitivity := 0.0025
@export var moveSpeed := 6.0
@export var jumpSpeed := 6.0
@export var jumpVelocity := 4.5
@export var gravity := 9.8
enum Mode {
	FPS,
	THIRD
}
@export var mode : Mode = Mode.THIRD:
	set(v):
		mode = v

var pitch := 0.0
var animationName = "Idle"

@onready var player: CharacterBody3D = get_parent()
@onready var playerMesh: Node3D = player.get_node("Player")
@onready var animationPlayer: AnimationPlayer = playerMesh.get_node("AnimationPlayer")

func setupPlayer():
	if mode == Mode.THIRD:
		margin = 10
		spring_length = 3
	elif mode == Mode.FPS:
		margin = 0
		spring_length = 0
		playerMesh.visible = false

func setupMovementInputs():
	var mappings = {
		"move_forward": KEY_W,
		"move_backward": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"jump": KEY_SPACE
	}

	for action in mappings.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)

			var event := InputEventKey.new()
			event.keycode = mappings[action]

			InputMap.action_add_event(action, event)

func _ready():
	setupMovementInputs()
	setupPlayer()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		var mouse_delta: Vector2 = event.relative
		rotate_y(-mouse_delta.x * mouseSensitivity)
		playerMesh.rotate_y(-mouse_delta.x * mouseSensitivity)
		pitch -= mouse_delta.y * mouseSensitivity
		pitch = clamp(pitch, deg_to_rad(-85), deg_to_rad(85))
		rotation.x = pitch

func _physics_process(delta):
	var direction := Vector3.ZERO

	var forward = -transform.basis.z
	var right = transform.basis.x
	var up = transform.basis.y

	if Input.is_action_pressed("move_forward"):
		direction += forward
		animationName = "Walk"
	if Input.is_action_pressed("move_backward"):
		direction -= forward
		animationName = "Walk"
	if Input.is_action_pressed("move_right"):
		direction += right
		animationName = "WalkRight"
	if Input.is_action_pressed("move_left"):
		direction -= right
		animationName = "WalkLeft"
	if Input.is_action_pressed("jump"):
		direction += up
		animationName = "Jump"
		
	if direction.length() < 0.01 && player.velocity.length() < 0.01:
		animationName = "Idle"
		
	animationPlayer.play(animationName)
	direction = direction.normalized()

	if not player.is_on_floor():
		player.velocity.y -= gravity * delta
	else:
		player.velocity.y = direction.y * jumpSpeed

	player.velocity.x = direction.x * moveSpeed
	player.velocity.z = direction.z * moveSpeed
	

	player.move_and_slide()
