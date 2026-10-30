extends GutTest


func test_clear_detaches_children_immediately() -> void:
	var parent := VBoxContainer.new()
	add_child_autofree(parent)
	var first := Label.new()
	var second := Label.new()
	parent.add_child(first)
	parent.add_child(second)
	UiKit.clear(parent)
	assert_eq(parent.get_child_count(), 0)
	assert_null(first.get_parent())
	assert_true(first.is_queued_for_deletion())
	assert_true(second.is_queued_for_deletion())


func test_clear_on_an_empty_parent_does_nothing() -> void:
	var parent := HBoxContainer.new()
	add_child_autofree(parent)
	UiKit.clear(parent)
	assert_eq(parent.get_child_count(), 0)
