class_name FogTexture
extends RefCounted

const ALPHA := [255, 130, 0]
const SHADER := preload("res://src/ui/fog.gdshader")

var fog: FogOfWar
var image: Image
var texture: ImageTexture
var material: ShaderMaterial
var _version := -1


func _init(p_fog: FogOfWar) -> void:
	fog = p_fog
	image = Image.create_from_data(fog.map.width, fog.map.height, false, Image.FORMAT_R8, fog.cells)
	texture = ImageTexture.create_from_image(image)
	material = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("fog_color", AppTheme.FOG)
	material.set_shader_parameter("explored_alpha", ALPHA[FogOfWar.EXPLORED] / 255.0)
	refresh()


func refresh() -> bool:
	if fog.version == _version:
		return false
	_version = fog.version
	image.set_data(fog.map.width, fog.map.height, false, Image.FORMAT_R8, fog.cells)
	texture.update(image)
	return true


func alpha_at(cell: Vector2i) -> int:
	return ALPHA[image.get_pixelv(cell).r8]
