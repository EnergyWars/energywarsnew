extends SceneTree

const SOURCES := "res://tools/store_assets/src/"
const JOBS := [
	{"source": "res://assets/icon.svg", "native": 512, "size": 192, "target": "res://assets/android/launcher_main_192.png"},
	{"source": SOURCES + "launcher_foreground.svg", "native": 432, "size": 432, "target": "res://assets/android/launcher_foreground_432.png"},
	{"source": SOURCES + "launcher_background.svg", "native": 432, "size": 432, "target": "res://assets/android/launcher_background_432.png"},
	{"source": SOURCES + "launcher_monochrome.svg", "native": 432, "size": 432, "target": "res://assets/android/launcher_monochrome_432.png"},
	{"source": SOURCES + "store_icon.svg", "native": 512, "size": 512, "target": "res://docs/store/icon-512.png"},
	{"source": SOURCES + "launcher_foreground.svg", "native": 432, "size": 540, "target": "res://build/store/feature_art.png"},
]


const IGNORED_DIR := "res://build/"


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(IGNORED_DIR))
	FileAccess.open(IGNORED_DIR + ".gdignore", FileAccess.WRITE)
	var failed := 0
	for job: Dictionary in JOBS:
		if not _render(job):
			failed += 1
	quit(failed)


func _render(job: Dictionary) -> bool:
	var svg := FileAccess.get_file_as_string(job.source)
	if svg.is_empty():
		printerr("missing source: ", job.source)
		return false
	var image := Image.new()
	if image.load_svg_from_string(svg, float(job.size) / float(job.native)) != OK:
		printerr("cannot rasterize: ", job.source)
		return false
	var target := ProjectSettings.globalize_path(job.target)
	DirAccess.make_dir_recursive_absolute(target.get_base_dir())
	if image.save_png(target) != OK:
		printerr("cannot write: ", target)
		return false
	print("%s -> %s (%dx%d)" % [job.source, job.target, image.get_width(), image.get_height()])
	return true
