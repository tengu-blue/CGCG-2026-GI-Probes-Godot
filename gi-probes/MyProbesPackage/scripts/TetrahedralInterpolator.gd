class_name TetrahedralInterpolator

class SamplePoint:
	var position: Vector3
	var value: Array[Vector3]

	func _init(pos: Vector3, val: Array[Vector3]):
		position = pos
		value = val


class Tetrahedron:
	var indices: PackedInt32Array

	func _init(a: int, b: int, c: int, d: int):
		indices = PackedInt32Array([a, b, c, d])


var points: Array[SamplePoint] = []
var tetrahedra: Array[Tetrahedron] = []


func build(sample_positions: Array[Vector3], sample_values) -> void:
	points.clear()
	tetrahedra.clear()

	for i in sample_positions.size():
		points.append(SamplePoint.new(sample_positions[i], sample_values[i]))

	_generate_tetrahedra()


func query(position: Vector3) -> Array[Vector3]:
	
	# find the first that this position falls into
	for tet in tetrahedra:
		var bary = _barycentric_coords(position, tet)

		if bary != null:
			return (
				bary[0] * points[tet.indices[0]].value +
				bary[1] * points[tet.indices[1]].value +
				bary[2] * points[tet.indices[2]].value +
				bary[3] * points[tet.indices[3]].value
			)

	# if outside -> 
	return _nearest_neighbor(position)


func _generate_tetrahedra() -> void:
	var n := points.size()

	# Brute force all tetra combinations
	for a in range(n):
		for b in range(a + 1, n):
			for c in range(b + 1, n):
				for d in range(c + 1, n):

					if _tetrahedron_volume(
						points[a].position,
						points[b].position,
						points[c].position,
						points[d].position
					) < 0.00001:
						continue

					tetrahedra.append(Tetrahedron.new(a, b, c, d))

func _barycentric_coords(p: Vector3, tet: Tetrahedron):
	var p0 = points[tet.indices[0]].position
	var p1 = points[tet.indices[1]].position
	var p2 = points[tet.indices[2]].position
	var p3 = points[tet.indices[3]].position

	var m = Basis(
		p1 - p0,
		p2 - p0,
		p3 - p0
	)

	var det = m.determinant()
	if abs(det) < 0.000001:
		return null

	var local = m.inverse() * (p - p0)

	var w1 = local.x
	var w2 = local.y
	var w3 = local.z
	var w0 = 1.0 - w1 - w2 - w3

	var epsilon = -0.0001

	if w0 >= epsilon and w1 >= epsilon and w2 >= epsilon and w3 >= epsilon:
		return [w0, w1, w2, w3]

	return null


func _nearest_neighbor(p: Vector3) -> Array[Vector3]:
	var best_dist := INF
	var best_index := -1

	for sample_index in range(len(points)):
		var sample := points[sample_index] 
		var d = p.distance_squared_to(sample.position)

		if d < best_dist:
			best_dist = d
			best_index = sample_index

	return points[best_index].value


func _tetrahedron_volume(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> float:
	return abs((b - a).dot((c - a).cross(d - a))) / 6.0
