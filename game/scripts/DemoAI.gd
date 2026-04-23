extends Control

const BoardScript = preload("res://scripts/Board.gd")

var board: Node
var cells: Array = []
var score_label: Label
var move_label: Label
var status_label: Label
var grid_container: GridContainer
var move_count: int = 0
var game_ended: bool = false

const TILE_COLORS := {
	0:    Color("#cdc1b4"),
	2:    Color("#eee4da"),
	4:    Color("#ede0c8"),
	8:    Color("#f2b179"),
	16:   Color("#f59563"),
	32:   Color("#f67c5f"),
	64:   Color("#f65e3b"),
	128:  Color("#edcf72"),
	256:  Color("#edcc61"),
	512:  Color("#edc850"),
	1024: Color("#edc53f"),
	2048: Color("#edc22e"),
}

const MOVE_NAMES  := ["UP", "RIGHT", "DOWN", "LEFT"]
const MOVE_DELAY  := 0.8  # seconds between AI moves

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color("#faf8ef")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)

	var m := MarginContainer.new()
	for s in ["left", "right", "top"]:
		m.add_theme_constant_override("margin_" + s, 20)
	vbox.add_child(m)

	var header := HBoxContainer.new()
	m.add_child(header)

	var title := Label.new()
	title.text = "2048  —  AI Demo"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("#776e65"))
	header.add_child(title)

	score_label = Label.new()
	score_label.text = "Score: 0"
	score_label.add_theme_font_size_override("font_size", 20)
	header.add_child(score_label)

	var bm := MarginContainer.new()
	for s in ["left", "right"]:
		bm.add_theme_constant_override("margin_" + s, 20)
	vbox.add_child(bm)

	grid_container = GridContainer.new()
	grid_container.columns = 4
	grid_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid_container.add_theme_constant_override("h_separation", 10)
	grid_container.add_theme_constant_override("v_separation", 10)
	bm.add_child(grid_container)

	move_label = Label.new()
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_label.add_theme_font_size_override("font_size", 18)
	move_label.add_theme_color_override("font_color", Color("#776e65"))
	vbox.add_child(move_label)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.add_theme_color_override("font_color", Color("#f65e3b"))
	vbox.add_child(status_label)

	board = BoardScript.new()
	add_child(board)
	board.score_changed.connect(func(s): score_label.text = "Score: %d" % s)
	board.game_won.connect(_on_game_won)
	board.game_over.connect(_on_game_over)

	_build_grid()
	board.new_game()
	_refresh_grid()

	var timer := Timer.new()
	timer.wait_time = MOVE_DELAY
	timer.autostart = true
	timer.timeout.connect(_ai_move)
	add_child(timer)

func _build_grid() -> void:
	cells = []
	for r in 4:
		var row: Array = []
		for c in 4:
			var panel := PanelContainer.new()
			panel.custom_minimum_size = Vector2(110, 110)
			var label := Label.new()
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 36)
			panel.add_child(label)
			grid_container.add_child(panel)
			row.append({panel = panel, label = label})
		cells.append(row)

func _refresh_grid() -> void:
	var grid: Array = board.get_grid()
	for r in 4:
		for c in 4:
			var val: int = grid[r][c]
			var cell: Dictionary = cells[r][c]
			cell.label.text = "" if val == 0 else str(val)
			var color: Color = TILE_COLORS.get(val, Color("#3c3a32"))
			var sb := StyleBoxFlat.new()
			sb.bg_color = color
			sb.set_corner_radius_all(6)
			cell.panel.add_theme_stylebox_override("panel", sb)
			cell.label.add_theme_color_override(
				"font_color",
				Color("#776e65") if val <= 4 else Color.WHITE
			)

func _ai_move() -> void:
	if game_ended:
		return
	var dir := randi() % 4
	var moved: bool = board.move(dir)
	move_count += 1
	var suffix := "" if moved else "  (blocked)"
	move_label.text = "Move #%d  ←→↑↓  %s%s" % [move_count, MOVE_NAMES[dir], suffix]
	_refresh_grid()

func _on_game_won() -> void:
	game_ended = true
	status_label.text = "AI reached 2048 in %d moves!" % move_count

func _on_game_over() -> void:
	game_ended = true
	status_label.text = "Game over after %d moves." % move_count
