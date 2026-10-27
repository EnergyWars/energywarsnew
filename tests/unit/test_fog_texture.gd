extends GutTest


func test_alpha_follows_fog_states() -> void:
	var state := BattleState.create(0)
	var fog := state.fog
	fog.cells.fill(FogOfWar.HIDDEN)
	fog.cells[fog.map.index(Vector2i(1, 0))] = FogOfWar.EXPLORED
	fog.cells[fog.map.index(Vector2i(2, 0))] = FogOfWar.VISIBLE
	fog.version += 1
	var texture := FogTexture.new(fog)
	assert_eq(texture.image.get_size(), Vector2i(fog.map.width, fog.map.height))
	assert_eq(texture.alpha_at(Vector2i(0, 0)), 255)
	assert_eq(texture.alpha_at(Vector2i(1, 0)), 130)
	assert_eq(texture.alpha_at(Vector2i(2, 0)), 0)
	assert_false(texture.refresh())
	fog.reveal(fog.map.center_of(Vector2i(0, 0)), 10.0)
	assert_true(texture.refresh())
	assert_eq(texture.alpha_at(Vector2i(0, 0)), 0)
	assert_not_null(texture.texture)
