class_name MiniMapTexture
extends RefCounted

const EXPLORED_SHADE := 0.45
const FOG_STATES := 3

var map: LevelMap
var fog: FogOfWar
var image: Image
var texture: ImageTexture
var _bytes := PackedByteArray()
var _palette: Array[Color] = []
var _map_version := -1
var _fog_version := -1


func _init(p_map: LevelMap, p_fog: FogOfWar) -> void:
	map = p_map
	fog = p_fog
	for tile in LevelMap.Tile.size():
		for high in 2:
			for fog_state in FOG_STATES:
				_palette.append(shade(tile_color(tile, high == 1), fog_state))
	_bytes.resize(map.width * map.height * 4)
	image = Image.create_from_data(map.width, map.height, false, Image.FORMAT_RGBA8, _bytes)
	texture = ImageTexture.create_from_image(image)
	refresh()


static func tile_color(tile: int, high: bool) -> Color:
	match tile:
		LevelMap.Tile.RAMP:
			return AppTheme.GROUND_LIGHT.lerp(AppTheme.GROUND_HIGH_LIGHT, 0.55)
		LevelMap.Tile.CLIFF:
			return AppTheme.CLIFF
		LevelMap.Tile.CHASM:
			return AppTheme.CHASM
		LevelMap.Tile.TREE:
			return AppTheme.TREE_DARK
		LevelMap.Tile.ROCK:
			return AppTheme.ROCK
		LevelMap.Tile.POND:
			return AppTheme.WATER
	return AppTheme.GROUND_HIGH_LIGHT if high else AppTheme.GROUND_LIGHT


static func shade(color: Color, fog_state: int) -> Color:
	match fog_state:
		FogOfWar.HIDDEN:
			return AppTheme.FOG
		FogOfWar.EXPLORED:
			return color.darkened(EXPLORED_SHADE)
	return color


func color_at(cell: Vector2i) -> Color:
	return _color(map.index(cell))


func _color(index: int) -> Color:
	return _palette[(map.tiles[index] * 2 + mini(map.heights[index], 1)) * FOG_STATES + fog.cells[index]]


func refresh() -> bool:
	if map.version == _map_version and fog.version == _fog_version:
		return false
	_map_version = map.version
	_fog_version = fog.version
	for index in map.width * map.height:
		var color := _color(index)
		var at := index * 4
		_bytes[at] = color.r8
		_bytes[at + 1] = color.g8
		_bytes[at + 2] = color.b8
		_bytes[at + 3] = 255
	image.set_data(map.width, map.height, false, Image.FORMAT_RGBA8, _bytes)
	texture.update(image)
	return true
