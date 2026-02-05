@tool
extends Node3D

@export_group("Camera Settings")
@export var rows := 2:
	set(v):
		rows = max(1, v)
		_safe_rebuild()

@export var cols := 2:
	set(v):
		cols = max(1, v)
		_safe_rebuild()

@export var spacing := 0.1:
	set(v):
		spacing = v
		_safe_rebuild()

@export var focusDistance := 5.0:
	set(v):
		focusDistance = max(0.001, v)
		_safe_rebuild()
		
@export var shrinkRender := 1:
	set(v):
		shrinkRender = max(0, v)
		_safe_rebuild()
		
enum Mode {
	CENTER,
	QUILT,
	DISPLAY
}

@export var mode : Mode = Mode.QUILT:
	set(v):
		mode = v
		_safe_rebuild()

@export_group("Display Calibration")
@export_range(-1000.0, 1000.0, 0.0000000001)
var tilt := 0.0:
	set(v):
		tilt = v
		_safe_rebuild()

@export_range(-5000.0, 5000.0, 0.0000000001)		
var pitch := 0.0:
	set(v):
		pitch = v
		_safe_rebuild()

@export_range(-5.0, 5.0, 0.0000000001)
var center : float = 0.0:
	set(v):
		center = v
		_safe_rebuild()

@export_range(-10.0, 10.0, 0.0000000001)
var viewPortionElement := 0.0:
	set(v):
		viewPortionElement = v
		_safe_rebuild()

@export_range(-1.0, 1.0, 0.0000000001)
var subp : float = 0.0:
	set(v):
		subp = v
		_safe_rebuild()

var ui_root: Control
var overlay_layer: CanvasLayer
var overlay_rect: ColorRect
var mat: ShaderMaterial
var shader := preload("res://holo.gdshader")

func updateShaderUniforms():
	mat.set_shader_parameter("mode", mode)
	mat.set_shader_parameter("tilt", -tilt)
	mat.set_shader_parameter("pitch", pitch)
	mat.set_shader_parameter("center", center)
	mat.set_shader_parameter("viewPortionElement", viewPortionElement)
	mat.set_shader_parameter("subp", subp)
	mat.set_shader_parameter("viewCount", cols*rows)
	mat.set_shader_parameter("cols", cols)
	mat.set_shader_parameter("rows", rows)

func _init():
	rows = rows
	cols = cols
	spacing = spacing
	shrinkRender = shrinkRender

func _ready():
	mat = ShaderMaterial.new()
	mat.shader = shader
	_safe_rebuild()

func _safe_rebuild():
	if not is_inside_tree():
		return
	if mat == null:
		return 
	rebuild()

func rebuild():
	for c in get_children():
		c.queue_free()
	ui_root = null
	overlay_layer = null
	overlay_rect = null

	ui_root = Control.new()
	ui_root.anchor_right = 1
	ui_root.anchor_bottom = 1
	add_child(ui_root)

	var screen_size := get_viewport().get_visible_rect().size
	if screen_size == Vector2.ZERO:
		return

	var cell_size := Vector2(
		screen_size.x / cols,
		screen_size.y / rows
	)

	var viewSize = DisplayServer.window_get_size()/Vector2i(cols, rows)
	var camCount = cols*rows;
	var cam_index = camCount
	var halfDistance = camCount*spacing/2
	for r in range(rows):
		for c in range(cols):
			var container := SubViewportContainer.new()
			container.position = Vector2((cols-1-c) * cell_size.x, r * cell_size.y)
			container.size = cell_size
			container.stretch = true
			container.stretch_shrink = shrinkRender

			var vp := SubViewport.new()
			vp.size = viewSize
			vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS

			var cam := Camera3D.new()
			cam.position = Vector3(cam_index * spacing - halfDistance, 0, 0)
			cam.projection = Camera3D.PROJECTION_FRUSTUM
			cam.size = 1.0
			cam.near = 1.0
			cam.frustum_offset[0] = -(cam_index - camCount/2.0)/(focusDistance*2.0)*spacing*2

			vp.add_child(cam)
			container.add_child(vp)
			ui_root.add_child(container)

			cam_index += -1

	overlay_layer = CanvasLayer.new()
	add_child(overlay_layer)

	overlay_rect = ColorRect.new()
	overlay_rect.anchor_left = 0
	overlay_rect.anchor_top = 0
	overlay_rect.anchor_right = 1
	overlay_rect.anchor_bottom = 1
	overlay_rect.color = Color(1, 1, 1, 1)

	updateShaderUniforms()
	overlay_rect.material = mat

	overlay_layer.add_child(overlay_rect)
