class_name SlimeTexture
extends RefCounted

const ALPHA := 0.58

var width: int
var height: int
var texture: ImageTexture
var image: Image
var covered := 0


func _init(map: LevelMap) -> void:
	width = map.width
	height = map.height
	image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	texture = ImageTexture.create_from_image(image)


func update(mask: PackedByteArray) -> void:
	var color := Color(AppTheme.SLIME, ALPHA)
	var data := PackedByteArray()
	data.resize(width * height * 4)
	covered = 0
	for i in mini(mask.size(), width * height):
		if mask[i] == 0:
			continue
		covered += 1
		var offset := i * 4
		data[offset] = color.r8
		data[offset + 1] = color.g8
		data[offset + 2] = color.b8
		data[offset + 3] = color.a8
	image = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, data)
	texture.update(image)
