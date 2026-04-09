extends Node3D

@onready var viewport: Viewport = $SubViewport
@onready var cam: Camera3D = $SubViewport/Camera3D

@export var mesh: MeshInstance3D
@export var SH_mesh : MeshInstance3D

#var cubemap

func _ready():
	var map := await capture_cubemap(global_transform.origin)
	
#	cubemap = map
		
	var mat = mesh.get_active_material(0).duplicate()
	mesh.material_override = mat
	mat.set_shader_parameter("source_panorama", map)
	
	# assign the cubemap to the helper
	var mat2 = $CubemapTo2D/ColorRect.material.duplicate()
	$CubemapTo2D/ColorRect.material = mat2
	mat2.set_shader_parameter("source_panorama", map)
	
	$CubemapTo2D.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw  # wait for render
	
	var img : Image = $CubemapTo2D.get_texture().get_image()
	
	var SH = spherical_harmonics(img) 
	print(SH)
	
	var sh_mat = SH_mesh.get_active_material(0).duplicate()
	SH_mesh.material_override = sh_mat
	sh_mat.set_shader_parameter("sh", SH)
	 

"""
func _unhandled_input(event: InputEvent) -> void:
	
	if event.is_action_pressed("ui_accept"):
		ResourceSaver.save(cubemap, "res://cubemap.res", ResourceSaver.FLAG_COMPRESS)
"""


func capture_cubemap(pos: Vector3) -> Cubemap:
	# global_transform.origin = pos

	var directions = [
		{ "dir": Vector3.LEFT,	"up": Vector3.DOWN }, # -X
		{ "dir": Vector3.RIGHT,	"up": Vector3.DOWN }, # +X
		{ "dir": Vector3.DOWN,	"up": Vector3.BACK }, # +Y
		{ "dir": Vector3.UP,	     "up": Vector3.FORWARD }, # -Y
		{ "dir": Vector3.FORWARD, "up": Vector3.DOWN }, # -Z
		{ "dir": Vector3.BACK,	"up": Vector3.DOWN }, # +Z
	]

	var images: Array[Image] = []
	
	
	for d in directions:
		cam.transform = Transform3D().looking_at(d.dir, d.up)
		cam.position = position

		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw  # wait for render

		var img = viewport.get_texture().get_image()
		images.push_back(img)

	var cubemap = Cubemap.new()
	cubemap.create_from_images(images)
	
	return cubemap

func spherical_harmonics(sphere : Image) -> Array[Vector3]:
	
	var c : Array[Vector3] = []
	c.resize(9)
	
	var Y = []
	Y.resize(9)
	
	var total_weight : float = 0
	
	var dθ = PI / sphere.get_height()
	var dφ = 2.0 * PI / sphere.get_width()
	
	# numerical integration
	for x in sphere.get_width():
		for y in sphere.get_height():
			var φ = float(x) / sphere.get_width() * 2 * PI
			var θ = float(y) / sphere.get_height() * PI
						
			var p := sphere.get_pixel(x, y)
			var G := Vector3(p.r, p.g, p.b)
			
			var sin_θ = sin(θ)
			var sin_φ = sin(φ)
			var cos_θ = cos(θ)
			var cos_φ = cos(φ)
			
			var weight = sin_θ * dθ * dφ
			total_weight += weight
			
			# I = G(θ,φ) * Y(θ,φ) * sin(θ)
			# these are pure magic 
			Y[0] = 1.0
			Y[1] = sin_θ * sin_φ
			Y[2] = cos_θ
			Y[3] = sin_θ * cos_φ
			Y[4] = sin_θ * sin_θ * cos_φ * sin_φ
			Y[5] = sin_θ * cos_θ * sin_φ
			Y[6] = 3.0 * cos_θ * cos_θ - 1.0
			Y[7] = sin_θ * cos_θ * cos_φ
			Y[8] = sin_θ * sin_θ * (cos_φ * cos_φ - sin_φ * sin_φ)

			for i in range(9):
				c[i] += G * Y[i] * weight
			
	#print(total_weight)
	
	# normalization constants
	c[0] *= 0.282095 
	c[1] *= 0.488603
	c[2] *= 0.488603
	c[3] *= 0.488603
	c[4] *= 1.092548
	c[5] *= 1.092548
	c[6] *= 0.315392
	c[7] *= 1.092548
	c[8] *= 0.546274
	
	return c
