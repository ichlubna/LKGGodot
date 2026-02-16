@tool
extends Node3D
## Support for Looking Glass Factory displays.
##
## The script generates a SubViewport that contains rows x cols other SubVieworts with cameras.
## The cameras capture a quilt that is processed in a shader to produce the LKG native format.

@export_group("Camera Settings")
## Number of rows in the quilt
@export var rows := 2:
	set(v):
		rows = max(1, v)
		_safe_rebuild()

## Number of columns in the quilt
@export var cols := 2:
	set(v):
		cols = max(1, v)
		_safe_rebuild()

## Distance between two neghboring cameras
@export var spacing := 0.1:
	set(v):
		spacing = v
		_safe_rebuild()

## The coordinates of the selected object override the focus distance
## (the object must be set before running the game anc cannot be changed in runtime)
@export var focusObject : Node3D:
	set(v):
		focusObject = v
		_safe_rebuild()

## Distance from the HoloCamera object where the scene is supposed to be in focus
@export var focusDistance := 5.0:
	set(v):
		focusDistance = max(0.001, v)
		_safe_rebuild()

## The quilt is rendered in the screen resolution multiplied by this parameter
## (higher means higher quality but also higher performance demand)
@export_range(0.01, 10.0, 0.01)
var renderSize := 1.0:
	set(v):
		renderSize = max(0, v)
		_safe_rebuild()

## Amount of the depth-of-field blur to mitigate out-of-focus artifacts
@export var dofAmount := 0.0:
	set(v):
		dofAmount = max(0.0, v)
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
@export_range(-1000.0, 1000.0, 0.000001)
var tilt := 0.0:
	set(v):
		tilt = v
		_safe_rebuild()

@export_range(-5000.0, 5000.0, 0.000001)		
var pitch := 0.0:
	set(v):
		pitch = v
		_safe_rebuild()

@export_range(-5.0, 5.0, 0.000001)
var center : float = 0.0:
	set(v):
		center = v
		_safe_rebuild()

@export_range(-10.0, 10.0, 0.000001)
var viewPortionElement := 0.0:
	set(v):
		viewPortionElement = v
		_safe_rebuild()

@export_range(-1.0, 1.0, 0.000001)
var subp : float = 0.0:
	set(v):
		subp = v
		_safe_rebuild()

var uiRoot: Control
var mat: ShaderMaterial
var shader := preload("res://holo.gdshader")

func _process(_delta: float):
	if focusObject:
		focusDistance = global_position.distance_to(focusObject.global_position)

func updateShaderUniforms(screenSize, texture):
	mat.set_shader_parameter("mode", mode)
	mat.set_shader_parameter("tilt", -tilt)
	mat.set_shader_parameter("pitch", pitch)
	mat.set_shader_parameter("center", center)
	mat.set_shader_parameter("viewPortionElement", viewPortionElement)
	mat.set_shader_parameter("subp", subp)
	mat.set_shader_parameter("viewCount", cols*rows)
	mat.set_shader_parameter("cols", cols)
	mat.set_shader_parameter("rows", rows)
	mat.set_shader_parameter("quiltAspect", float(cols)/rows)
	mat.set_shader_parameter("invertedScreenAspect", float(screenSize.y)/screenSize.x)
	mat.set_shader_parameter("screenTexture", texture)

func _init():
	rows = rows
	cols = cols
	spacing = spacing
	renderSize = renderSize
	focusDistance = focusDistance
	focusObject = focusObject
	dofAmount = dofAmount
	mode = mode
	tilt = tilt
	pitch = pitch
	center = center
	viewPortionElement = viewPortionElement
	subp = subp

func _ready():
	mat = ShaderMaterial.new()
	mat.shader = shader
	set_process(true)
	_safe_rebuild()

func _safe_rebuild():
	if not is_inside_tree():
		return
	if mat == null:
		return 
	rebuild()

func postProcess(screenSize, texture):
	var overlayLayer := CanvasLayer.new()
	add_child(overlayLayer)

	var overlayRect := ColorRect.new()
	overlayRect.anchor_left = 0
	overlayRect.anchor_top = 0
	overlayRect.anchor_right = 1
	overlayRect.anchor_bottom = 1
	overlayRect.color = Color(1, 1, 1, 1)

	updateShaderUniforms(screenSize, texture)
	overlayRect.material = mat

	overlayLayer.add_child(overlayRect)

func rebuild():
	for c in get_children():
		c.queue_free()
	uiRoot = null

	uiRoot = Control.new()
	uiRoot.anchor_right = 1
	uiRoot.anchor_bottom = 1
	add_child(uiRoot)

	var screenSize := get_viewport().get_visible_rect().size
	if screenSize == Vector2.ZERO:
		return

	var quiltContainer := SubViewportContainer.new()
	var quiltVp := SubViewport.new()
	quiltVp.size = screenSize*renderSize
	add_child(quiltContainer)
	quiltContainer.add_child(quiltVp)
	
	@warning_ignore("integer_division")
	var viewSize = quiltVp.size/Vector2i(cols, rows)
	var camCount = cols*rows
	var cam_index = camCount
	var halfDistance = camCount*spacing/2
	for r in range(rows):
		for c in range(cols):
			var container := SubViewportContainer.new()
			container.position = Vector2((cols-1-c) * viewSize.x, r * viewSize.y)
			container.size = viewSize
			container.stretch = true

			var vp := SubViewport.new()
			vp.size = viewSize
			vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS

			var cam := Camera3D.new()
			if(cols > rows):
				cam.keep_aspect = Camera3D.KEEP_WIDTH
			else:
				cam.keep_aspect = Camera3D.KEEP_HEIGHT
			
			cam.position = Vector3(cam_index * spacing - halfDistance, 0, 0)
			cam.projection = Camera3D.PROJECTION_FRUSTUM
			cam.size = 1
			cam.near = 1.0
			cam.frustum_offset[0] = -(cam_index - camCount/2.0)/(focusDistance*2.0)*spacing*2
			
			var physicalAttributes := CameraAttributesPhysical.new()
			physicalAttributes.frustum_focus_distance = focusDistance 
			physicalAttributes.frustum_focal_length = dofAmount*100
			physicalAttributes.frustum_far = 4000.0
			physicalAttributes.frustum_near = 1.0
			cam.attributes = physicalAttributes

			var remoteTransform := RemoteTransform3D.new()
			
			vp.add_child(cam)
			container.add_child(vp)
			quiltVp.add_child(container)
			add_child(remoteTransform)
			remoteTransform.position = cam.position
			remoteTransform.remote_path = cam.get_path()
			remoteTransform.use_global_coordinates = true

			cam_index += -1

	postProcess(screenSize, quiltVp.get_texture())
