extends Node3D

@export var min_time := 1.0
@export var max_time := 3.0
@export var duration := 1.0

var tween: Tween


func _ready():
	randomize()
	_next_rotation()


func _next_rotation():
	if tween:
		tween.kill()

	var from_q := global_transform.basis.get_rotation_quaternion()
	var to_q := _random_quaternion()

	tween = create_tween()

	tween.tween_method(
		func(t):
			var q := from_q.slerp(to_q, t)
			global_transform.basis = Basis(q),
		0.0, 1.0, duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_callback(_wait_then_next)


func _wait_then_next():
	var wait_time := randf_range(min_time, max_time)
	await get_tree().create_timer(wait_time).timeout
	_next_rotation()


func _random_quaternion() -> Quaternion:
	# Uniform random rotation
	var u1 := randf()
	var u2 := randf()
	var u3 := randf()

	var q := Quaternion(
		sqrt(1 - u1) * sin(TAU * u2),
		sqrt(1 - u1) * cos(TAU * u2),
		sqrt(u1) * sin(TAU * u3),
		sqrt(u1) * cos(TAU * u3)
	)

	return q.normalized()
