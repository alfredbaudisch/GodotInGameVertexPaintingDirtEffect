extends Spatial

var recheck := false
var ray_length = 1000

var brush_size:float = .3
var brush_opacity:float = .25
var brush_hardness:float = 0.2

var paint_color = Color(1, 1, 1, 1)

var click_position
export var mesh_path : NodePath
var current_mesh : MeshInstance

func _ready():
	current_mesh = get_node(mesh_path) as MeshInstance

func _unhandled_input(event):		
	if event is InputEventMouseMotion:
		recheck = true

func _physics_process(delta):
	if recheck:
		var position2D = get_tree().root.get_mouse_position()
		
		var camera = $Camera
		var from = camera.project_ray_origin(position2D)
		var to = from + camera.project_ray_normal(position2D) * ray_length

		var space_state = get_world().direct_space_state
		# use global coordinates, not local to node
		var result = space_state.intersect_ray(from, to, [self], 1, true, true)	
		
		if result.size() > 0:
			click_position = result.position
			_paint_tool()
			
		recheck = false	

#
# This code segment is taken from https://github.com/tomankirilov/VPainter
# Copyright (c) 2020 toman kirilov (MIT License)
# 
func _paint_tool() -> void:
	var data = MeshDataTool.new()
	data.create_from_surface(current_mesh.mesh, 0)	

	for i in range(data.get_vertex_count()):
		var vertex := current_mesh.to_global(data.get_vertex(i))
		var vertex_distance:float = vertex.distance_to(click_position)

		if vertex_distance < brush_size/2:
			var linear_distance = 1 - (vertex_distance / (brush_size/2))
			var calculated_hardness = linear_distance * brush_hardness			
			data.set_vertex_color(i, data.get_vertex_color(i).linear_interpolate(paint_color, brush_opacity))

	current_mesh.mesh.surface_remove(0)
	data.commit_to_surface(current_mesh.mesh)
