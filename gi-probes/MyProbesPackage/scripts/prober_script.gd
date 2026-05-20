extends Node3D
class_name Prober

@onready var viewport: Viewport = $SubViewport
@onready var cam: Camera3D = $SubViewport/Camera3D

func capture(capture_at : Vector3, min_dist : float ) -> Array[Vector3]:
	var cubemap := await capture_cubemap(capture_at, min_dist)
	
	var mat = $CubemapTo2D/ColorRect.material
	mat.set_shader_parameter("source_panorama",  cubemap)
	$CubemapTo2D.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	
	var img : Image = $CubemapTo2D.get_texture().get_image()
	
	var SH = spherical_harmonics(img) 
	return SH

func capture_env(capture_at : Vector3, min_dist : float) -> Cubemap:
	return await capture_cubemap(capture_at, min_dist)

func capture_cubemap(pos: Vector3, min_dist : float) -> Cubemap:
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
	
	cam.near = min_dist
	for d in directions:
		cam.transform = Transform3D().looking_at(d.dir, d.up)
		cam.global_position = pos

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
	
	var dθ = PI / sphere.get_height()
	var dφ = 2.0 * PI / sphere.get_width()
	
	# numerical integration
	for px in sphere.get_width():
		for py in sphere.get_height():
			var φ = float(px) / sphere.get_width() * 2 * PI
			var θ = float(py) / sphere.get_height() * PI

			var dir = Vector3(sin(θ) * cos(φ), sin(θ) * sin(φ), cos(θ));
			
			var p := sphere.get_pixel(px, py)
			var G := Vector3(p.r, p.g, p.b)
			
			var weight = sin(θ) * dθ * dφ
			
			var x = dir.x
			var y = dir.y
			var z = dir.z

			Y[0] = 0.282095;

			Y[1] = 0.488603 * y;
			Y[2] = 0.488603 * z;
			Y[3] = 0.488603 * x;

			Y[4] = 1.092548 * x * y;
			Y[5] = 1.092548 * y * z;
			Y[6] = 0.315392 * (3.0 * z * z - 1.0);
			Y[7] = 1.092548 * x * z;
			Y[8] = 0.546274 * (x * x - y * y);

			for i in range(9):
				c[i] += G * Y[i] * weight
	
	return c
