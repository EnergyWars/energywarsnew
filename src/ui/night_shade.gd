class_name NightShade
extends RefCounted

const SHADER := preload("res://src/ui/night.gdshader")
const MAX_LIGHTS := 32

var material := ShaderMaterial.new()
var lights := PackedVector3Array()
var strength := 0.0
var lighting: Lighting
var glow_image: Image
var glow_texture: ImageTexture
var _glow_version := -1


func _init() -> void:
	material.shader = SHADER
	material.set_shader_parameter("tint", Color(AppTheme.FOG, 1.0))
	lights.resize(MAX_LIGHTS)
	apply(PackedVector3Array(), 0.0)


func bind(p_lighting: Lighting) -> void:
	lighting = p_lighting
	var map := lighting.state.map
	glow_image = Image.create_from_data(map.width, map.height, false, Image.FORMAT_R8, lighting.glow)
	glow_texture = ImageTexture.create_from_image(glow_image)
	_glow_version = lighting.glow_version
	material.set_shader_parameter("glow_mask", glow_texture)
	material.set_shader_parameter("world_size", map.size)


func refresh_glow() -> bool:
	if lighting == null or lighting.glow_version == _glow_version:
		return false
	_glow_version = lighting.glow_version
	var map := lighting.state.map
	glow_image.set_data(map.width, map.height, false, Image.FORMAT_R8, lighting.glow)
	glow_texture.update(glow_image)
	return true


func apply(sources: PackedVector3Array, p_strength: float) -> int:
	strength = clampf(p_strength, 0.0, 1.0)
	var count := mini(sources.size(), MAX_LIGHTS)
	lights.fill(Vector3.ZERO)
	for i in count:
		lights[i] = sources[i]
	material.set_shader_parameter("strength", strength)
	material.set_shader_parameter("light_count", count)
	material.set_shader_parameter("lights", lights)
	return count
