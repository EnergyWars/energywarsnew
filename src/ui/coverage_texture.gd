class_name CoverageTexture
extends RefCounted

const ALPHA := 0.32

var width: int
var height: int
var texture: ImageTexture
var image: Image
var _palette: Array[PackedByteArray] = []


func _init(map: LevelMap) -> void:
	width = map.width
	height = map.height
	image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	texture = ImageTexture.create_from_image(image)
	for color in palette():
		var bytes := PackedByteArray([color.r8, color.g8, color.b8, color.a8])
		_palette.append(bytes)


static func palette() -> Array[Color]:
	return [Color.TRANSPARENT, Color(AppTheme.DANGER, ALPHA), Color(AppTheme.WARNING, ALPHA), Color(AppTheme.SUCCESS, ALPHA), Color(AppTheme.SHIELD_BLUE, ALPHA)]


func update(levels: PackedByteArray) -> void:
	var data := PackedByteArray()
	data.resize(width * height * 4)
	for i in mini(levels.size(), width * height):
		var level := levels[i]
		if level == Coverage.NONE:
			continue
		var bytes := _palette[mini(level, _palette.size() - 1)]
		var offset := i * 4
		data[offset] = bytes[0]
		data[offset + 1] = bytes[1]
		data[offset + 2] = bytes[2]
		data[offset + 3] = bytes[3]
	image = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, data)
	texture.update(image)
