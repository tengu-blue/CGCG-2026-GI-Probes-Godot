extends Node3D

@onready var viewport: Viewport = $SubViewport
@onready var cam: Camera3D = $SubViewport/Camera3D

@export var material: Node3D

func _ready():
	var map = await capture_cubemap(global_transform.origin)
	
	var mat = material.get_active_material(0)
	mat.set_shader_parameter("source_panorama", map)


func capture_cubemap(pos: Vector3) -> ImageTextureLayered:
	global_transform.origin = pos

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

		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw  # wait for render

		var img = viewport.get_texture().get_image()
		images.push_back(img)

	var cubemap = Cubemap.new()
	cubemap.create_from_images(images)
	
	return cubemap
