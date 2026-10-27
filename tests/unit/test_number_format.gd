extends GutTest


func test_grouped() -> void:
	assert_eq(NumberFormat.grouped(0), "0")
	assert_eq(NumberFormat.grouped(999), "999")
	assert_eq(NumberFormat.grouped(1000), "1,000")
	assert_eq(NumberFormat.grouped(1234567), "1,234,567")
	assert_eq(NumberFormat.grouped(-4200), "-4,200")


func test_clock() -> void:
	assert_eq(NumberFormat.clock(0.0), "0:00")
	assert_eq(NumberFormat.clock(59.2), "1:00")
	assert_eq(NumberFormat.clock(125.0), "2:05")
	assert_eq(NumberFormat.clock(-3.0), "0:00")
