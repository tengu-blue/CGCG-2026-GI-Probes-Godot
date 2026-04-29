extends Node

@export var prober : Prober

# TODO: proper kd closest find
func get_closest_probe(pos : Vector3, probes, sh):	
	var closest_ids = -1
	var closest_dist = INF

	for idx in range(len(probes)):
		var d = pos.distance_squared_to(probes[idx].global_position)
		if d < closest_dist:
			closest_dist = d
			closest_ids = idx
		
	return sh[closest_ids]

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
	
	# only set the values to all, once all computed	
	# for i in range(len(probes)):
	#	probes[i].assign_mats(sh_harmonics[i])
	
	# find all materials with the custom shader
	# set their sh based on the closest probe
	var materials = get_tree().get_nodes_in_group("update_materials")
	for obj in materials:
		var mat = obj.get_active_material(0).duplicate()
		obj.set_surface_override_material(0, mat)
		
		mat.set_shader_parameter("use_sh", true)
		var closest = get_closest_probe(obj.global_position, probes, sh_harmonics) 
		mat.set_shader_parameter("sh", closest)
