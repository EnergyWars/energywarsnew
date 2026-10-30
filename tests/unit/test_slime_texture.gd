extends GutTest


func test_slimed_cells_become_translucent_green() -> void:
	var map := LevelMap.blank(Vector2i(5, 4))
	var texture := SlimeTexture.new(map)
	var mask := PackedByteArray()
	mask.resize(20)
	mask[map.index(Vector2i(2, 1))] = 1
	mask[map.index(Vector2i(4, 3))] = 1
	texture.update(mask)
	assert_eq(texture.covered, 2)
	assert_eq(texture.image.get_width(), 5)
	assert_eq(texture.image.get_height(), 4)
	var pixel := texture.image.get_pixel(2, 1)
	assert_almost_eq(pixel.a, SlimeTexture.ALPHA, 0.01)
	assert_almost_eq(pixel.g, AppTheme.SLIME.g, 0.01)
	assert_eq(texture.image.get_pixel(0, 0).a, 0.0)


func test_clearing_the_mask_clears_the_texture() -> void:
	var map := LevelMap.blank(Vector2i(3, 3))
	var texture := SlimeTexture.new(map)
	var mask := PackedByteArray()
	mask.resize(9)
	mask.fill(1)
	texture.update(mask)
	assert_eq(texture.covered, 9)
	mask.fill(0)
	texture.update(mask)
	assert_eq(texture.covered, 0)
	assert_eq(texture.image.get_pixel(1, 1).a, 0.0)


func test_short_masks_leave_the_rest_empty() -> void:
	var map := LevelMap.blank(Vector2i(4, 4))
	var texture := SlimeTexture.new(map)
	texture.update(PackedByteArray([1, 1]))
	assert_eq(texture.covered, 2)
	assert_eq(texture.image.get_pixel(3, 3).a, 0.0)
