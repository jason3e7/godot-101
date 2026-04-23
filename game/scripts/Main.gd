extends Control

const BoardScript = preload("res://scripts/Board.gd")

var board: Node
var score_label: Label
var best_label: Label
var grid_container: GridContainer
var result_label: Label
var cells: Array = []
var best_score: int = 0

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

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color("#faf8ef")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)
	add_child(vbox)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	vbox.add_child(margin)

	var header := HBoxContainer.new()
	margin.add_child(header)

	var title := Label.new()
	title.text = "2048"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color("#776e65"))
	header.add_child(title)

	var score_box := VBoxContainer.new()
	score_label = Label.new()
	score_label.text = "Score\n0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 18)
	score_box.add_child(score_label)
	header.add_child(score_box)

	var best_box := VBoxContainer.new()
	best_label = Label.new()
	best_label.text = "Best\n0"
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_label.add_theme_font_size_override("font_size", 18)
	best_box.add_child(best_label)
	header.add_child(best_box)

	var board_margin := MarginContainer.new()
	for side in ["left", "right"]:
		board_margin.add_theme_constant_override("margin_" + side, 20)
	vbox.add_child(board_margin)

	grid_container = GridContainer.new()
	grid_container.columns = 4
	grid_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid_container.add_theme_constant_override("h_separation", 10)
	grid_container.add_theme_constant_override("v_separation", 10)
	board_margin.add_child(grid_container)

	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 24)
	result_label.add_theme_color_override("font_color", Color("#f65e3b"))
	vbox.add_child(result_label)

	var new_game_btn := Button.new()
	new_game_btn.text = "New Game"
	new_game_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	new_game_btn.pressed.connect(_on_new_game)
	vbox.add_child(new_game_btn)

	board = BoardScript.new()
	add_child(board)
	board.score_changed.connect(_on_score_changed)
	board.game_won.connect(_on_game_won)
	board.game_over.connect(_on_game_over)

	_build_grid()
	_on_new_game()

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
			var font_color := Color("#776e65") if val <= 4 else Color.WHITE
			cell.label.add_theme_color_override("font_color", font_color)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var dir := -1
		match event.keycode:
			KEY_UP,    KEY_W: dir = 0
			KEY_RIGHT, KEY_D: dir = 1
			KEY_DOWN,  KEY_S: dir = 2
			KEY_LEFT,  KEY_A: dir = 3
		if dir >= 0:
			board.move(dir)
			_refresh_grid()

func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score\n%d" % new_score
	if new_score > best_score:
		best_score = new_score
		best_label.text = "Best\n%d" % best_score

func _on_new_game() -> void:
	board.new_game()
	result_label.text = ""
	score_label.text = "Score\n0"
	_refresh_grid()

func _on_game_won() -> void:
	result_label.text = "You Win!  Keep going?"

func _on_game_over() -> void:
	result_label.text = "Game Over!"
