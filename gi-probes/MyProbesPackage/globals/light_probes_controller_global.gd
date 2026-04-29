extends Node

@export var prober : Prober

# list of probes -> 
# on init_probes()
func init_probes():
	var probes = get_tree().get_nodes_in_group("light_probes")
	
	print(probes)

# on update_probes()
func update_probes():
	# find all probes
	var probes = get_tree().get_nodes_in_group("light_probes")
	var sh_harmonics = []
	
	# compute the harmonics for each probes
	for probe in probes:
		var sh = await prober.capture(probe.global_position)
		sh_harmonics.push_back(sh)
	
		# debug test
		probe.debug_set(sh)
	
	# only set the values to all, once all computed	
	for i in range(len(probes)):
		probes[i].assign_mats(sh_harmonics[i])
	
	pass

func assign_to_materials():
	
	pass

# list of materials -> TODO: closest probes
