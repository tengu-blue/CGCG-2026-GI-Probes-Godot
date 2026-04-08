extends Camera3D


@export var speed := 5.0
@export var mouse_sensitivity := 0.002

var yaw := 0.0
var pitch := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		
		pitch = clamp(pitch, -PI/2, PI/2)

		rotation = Vector3(pitch, yaw, 0)

func _process(delta):
	var dir := Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		dir -= transform.basis.z
	if Input.is_action_pressed("move_back"):
		dir += transform.basis.z
	if Input.is_action_pressed("move_left"):
		dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		dir += transform.basis.x
	if Input.is_action_pressed("move_up"):
		dir += transform.basis.y
	if Input.is_action_pressed("move_down"):
		dir -= transform.basis.y

	if dir != Vector3.ZERO:
		dir = dir.normalized()

	position += dir * 2.0 * delta
