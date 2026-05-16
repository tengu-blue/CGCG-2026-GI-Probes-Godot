extends Node

@export var prober : Prober
var all_probes : TetrahedralInterpolator

func _ready() -> void:
	all_probes = TetrahedralInterpolator.new()


func get_closest_probe(pos : Vector3):	
	return all_probes.query(pos)


var t := false
func toggle():
	var materials = get_tree().get_nodes_in_group("update_materials")
	for obj in materials:
		var mat = obj.get_active_material(0)
		mat.set_shader_parameter("use_sh", t)
	
	t = not t

# on update_probes()
func update_probes():
	# find all probes
	var probes = get_tree().get_nodes_in_group("light_probes")
	var sh_harmonics = []
	
	# compute the harmonics for each probes
	for probe in probes:
		var sh = await prober.capture(probe.global_position, probe.min_dist)
		sh_harmonics.push_back(sh)
	
		# debug test
		# probe.debug_set(sh)
	
	# store the harmonics and positions
	var positions: Array[Vector3] = []

	for probe in probes:
		positions.append(probe.global_position)
	
	all_probes.build(positions, sh_harmonics)
	
	
	# find all materials with the custom shader
	# set their sh based on the closest probe
	var materials = get_tree().get_nodes_in_group("update_materials")
	for obj in materials:
		
		var mat = obj.get_active_material(0).duplicate()
		obj.set_surface_override_material(0, mat)
		
		# check if using the custom per-vertex
		var use_custom : bool = mat.get_shader_parameter("use_custom") 
		if(!use_custom):
			var closest = get_closest_probe(obj.global_position) 
			mat.set_shader_parameter("sh", closest)
		else:
			
			obj.mesh = set_per_vertex_harmonics(obj.global_transform, obj.mesh, mat)
			obj.set_surface_override_material(0, mat)
		
		mat.set_shader_parameter("use_sh", true)


func set_per_vertex_harmonics(global_transform, mesh, mat):
	
	var arrays = mesh.surface_get_arrays(0)
	var vertices = arrays[Mesh.ARRAY_VERTEX]
	
	var new_custom0 = PackedVector4Array()
	var new_custom1 = PackedVector4Array()
	var new_custom2 = PackedVector4Array()
	var new_custom3 = PackedVector4Array()
		
	for v in vertices:
		var world_v = global_transform * v
		
		var harmonics = get_closest_probe(world_v)

		new_custom0.append(Vector4(harmonics[0].x, harmonics[0].y, harmonics[0].z, 1))
		new_custom1.append(Vector4(harmonics[1].x, harmonics[1].y, harmonics[1].z, 1))
		new_custom2.append(Vector4(harmonics[2].x, harmonics[2].y, harmonics[2].z, 1))
		new_custom3.append(Vector4(harmonics[3].x, harmonics[3].y, harmonics[3].z, 1))
	
	arrays[Mesh.ARRAY_CUSTOM0] = new_custom0.to_byte_array().to_float32_array()
	arrays[Mesh.ARRAY_CUSTOM1] = new_custom1.to_byte_array().to_float32_array()
	arrays[Mesh.ARRAY_CUSTOM2] = new_custom2.to_byte_array().to_float32_array()
	arrays[Mesh.ARRAY_CUSTOM3] = new_custom3.to_byte_array().to_float32_array()	
			
	var format1 = 0
	format1 = format1 | Mesh.ARRAY_CUSTOM_RGBA_FLOAT
	format1 = format1 << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT
	
	var format2 = 0
	format2 = format2 | Mesh.ARRAY_CUSTOM_RGBA_FLOAT
	format2 = format2 << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT
	
	var format3 = 0
	format3 = format3 | Mesh.ARRAY_CUSTOM_RGBA_FLOAT
	format3 = format3 << Mesh.ARRAY_FORMAT_CUSTOM2_SHIFT
	
	var format4 = 0
	format4 = format4 | Mesh.ARRAY_CUSTOM_RGBA_FLOAT
	format4 = format4 << Mesh.ARRAY_FORMAT_CUSTOM3_SHIFT
	
	var format = format1 | format2 | format3 | format4

	format |= Mesh.ARRAY_FORMAT_VERTEX
	format |= Mesh.ARRAY_FORMAT_NORMAL
	format |= Mesh.ARRAY_FORMAT_TANGENT
	format |= Mesh.ARRAY_FORMAT_TEX_UV
	format |= Mesh.ARRAY_FORMAT_CUSTOM0
	format |= Mesh.ARRAY_FORMAT_CUSTOM1
	format |= Mesh.ARRAY_FORMAT_CUSTOM2
	format |= Mesh.ARRAY_FORMAT_CUSTOM3
	format |= Mesh.ARRAY_FORMAT_INDEX
	
	var new_mesh = ArrayMesh.new()
	new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, format)

	return new_mesh
