class_name TetrahedralInterpolator


# =========================================================
# DATA
# =========================================================

class SamplePoint:
	var position: Vector3
	var value: Array[Vector3]

	func _init(p: Vector3, v: Array[Vector3]):
		position = p
		value = v


class Tetrahedron:
	var a: int
	var b: int
	var c: int
	var d: int

	var basis_inv: Basis

	func _init(_a: int, _b: int, _c: int, _d: int):
		a = _a
		b = _b
		c = _c
		d = _d


# =========================================================
# STATE
# =========================================================

var points: Array[SamplePoint] = []
var tetrahedra: Array[Tetrahedron] = []

var super_point_indices: Array[int] = []


# =========================================================
# PUBLIC API
# =========================================================

func build(sample_positions: Array[Vector3], sample_values: Array) -> void:
	points.clear()
	tetrahedra.clear()
	super_point_indices.clear()

	for i in range(sample_positions.size()):
		points.append(SamplePoint.new(sample_positions[i], sample_values[i]))

	_build_delaunay()


func query(p: Vector3) -> Array[Vector3]:
	var tet := _find_containing_tetra(p)
	if tet == null:
		return _nearest(p)

	var bary := _barycentric(p, tet)
	if bary[0] == null:
		return _nearest(p)

	var result: Array[Vector3] = []

	for h in range(9):
		var v := Vector3.ZERO
		v += bary[0] * points[tet.a].value[h]
		v += bary[1] * points[tet.b].value[h]
		v += bary[2] * points[tet.c].value[h]
		v += bary[3] * points[tet.d].value[h]
		result.append(v)

	return result


# =========================================================
# DELAUNAY (BOWYER–WATSON)
# =========================================================

func _build_delaunay() -> void:
	_add_super_tetra()

	for i in range(points.size() - 4):
		_insert_point(i)

	_remove_super_tetra()


func _add_super_tetra() -> void:
	var min_v := Vector3(INF, INF, INF)
	var max_v := Vector3(-INF, -INF, -INF)

	for p in points:
		min_v = min_v.min(p.position)
		max_v = max_v.max(p.position)

	var size := (max_v - min_v).length() + 10.0
	var c := (min_v + max_v) * 0.5

	var p0 := c + Vector3(-size, -size, -size)
	var p1 := c + Vector3( size, -size, -size)
	var p2 := c + Vector3( 0,  size, -size)
	var p3 := c + Vector3( 0, 0,  size)

	var base := points.size()

	points.append(SamplePoint.new(p0, _dummy()))
	points.append(SamplePoint.new(p1, _dummy()))
	points.append(SamplePoint.new(p2, _dummy()))
	points.append(SamplePoint.new(p3, _dummy()))

	super_point_indices = [base, base + 1, base + 2, base + 3]

	var t := Tetrahedron.new(base, base + 1, base + 2, base + 3)
	t.basis_inv = _compute_basis_inv(t)
	tetrahedra = [t]


func _insert_point(idx: int) -> void:
	var p := points[idx].position

	var bad: Array[Tetrahedron] = []

	for t in tetrahedra:
		if _in_sphere(p, t):
			bad.append(t)

	var boundary := _boundary_faces(bad)

	for t in bad:
		tetrahedra.erase(t)

	for f in boundary:
		var new_t := Tetrahedron.new(f[0], f[1], f[2], idx)
		new_t.basis_inv = _compute_basis_inv(new_t)
		tetrahedra.append(new_t)


func _boundary_faces(bad: Array) -> Array:
	var face_count := {}

	for t in bad:
		_add_face(face_count, t.a, t.b, t.c)
		_add_face(face_count, t.a, t.b, t.d)
		_add_face(face_count, t.a, t.c, t.d)
		_add_face(face_count, t.b, t.c, t.d)

	var result: Array = []

	for k in face_count.keys():
		if face_count[k] == 1:
			result.append(k)

	return result


func _add_face(dict: Dictionary, a: int, b: int, c: int) -> void:
	var key := [a, b, c]
	key.sort()

	if dict.has(key):
		dict[key] += 1
	else:
		dict[key] = 1


func _remove_super_tetra() -> void:
	var filtered: Array[Tetrahedron] = []

	for t in tetrahedra:
		if _is_super(t):
			continue
		filtered.append(t)

	tetrahedra = filtered


func _is_super(t: Tetrahedron) -> bool:
	return (
		t.a in super_point_indices or
		t.b in super_point_indices or
		t.c in super_point_indices or
		t.d in super_point_indices
	)


# =========================================================
# GEOMETRY
# =========================================================

func _compute_basis_inv(t: Tetrahedron) -> Basis:
	var p0 = points[t.a].position
	var p1 = points[t.b].position
	var p2 = points[t.c].position
	var p3 = points[t.d].position

	var m := Basis(p1 - p0, p2 - p0, p3 - p0)
	return m.inverse()


func _barycentric(p: Vector3, t: Tetrahedron) -> Array:
	var p0 = points[t.a].position
	var local : Vector3 = t.basis_inv * (p - p0)

	var w1 := local.x
	var w2 := local.y
	var w3 := local.z
	var w0 := 1.0 - w1 - w2 - w3

	if w0 >= -1e-4 and w1 >= -1e-4 and w2 >= -1e-4 and w3 >= -1e-4:
		return [w0, w1, w2, w3]

	return [null]


func _find_containing_tetra(p: Vector3) -> Tetrahedron:
	for t in tetrahedra:
		var b := _barycentric(p, t)
		if b != null:
			return t
	return null


# =========================================================
# INSPHERE (simplified but consistent)
# =========================================================

func _in_sphere(p: Vector3, t: Tetrahedron) -> bool:
	var a = points[t.a].position
	var b = points[t.b].position
	var c = points[t.c].position
	var d = points[t.d].position

	var pa := a.length_squared()
	var pb := b.length_squared()
	var pc := c.length_squared()
	var pd := d.length_squared()
	var pp := p.length_squared()

	# simplified determinant sign test (not perfectly robust but consistent in GDScript)
	var det := \
	(pa * _det3(b, c, d)) - \
	(pb * _det3(a, c, d)) + \
	(pc * _det3(a, b, d)) - \
	(pd * _det3(a, b, c)) + \
	(pp * _det3(a, b, c))

	return det > 0.0


func _det3(a: Vector3, b: Vector3, c: Vector3) -> float:
	return a.dot(b.cross(c))


# =========================================================
# FALLBACK
# =========================================================

func _nearest(p: Vector3) -> Array[Vector3]:
	var best := INF
	var idx := 0

	for i in range(points.size() - 4): # ignore super points
		var d := p.distance_squared_to(points[i].position)
		if d < best:
			best = d
			idx = i

	return points[idx].value


func _dummy() -> Array[Vector3]:
	var v: Array[Vector3] = []
	for i in range(9):
		v.append(Vector3.ZERO)
	return v
