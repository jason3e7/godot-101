extends Control

const BoardScript = preload("res://scripts/Board.gd")

# ── Layout constants ───────────────────────────────────────────────────────────
const TILE_SIZE  := 106
const GAP        := 10
const STEP       := TILE_SIZE + GAP          # 116
const BOARD_SIZE := 4 * STEP + GAP           # 474

# ── Animation durations (seconds) ─────────────────────────────────────────────
const T_SLIDE := 0.10
const T_POP   := 0.08
const T_SPAWN := 0.18

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

# ── State ──────────────────────────────────────────────────────────────────────
var board: Node
var tile_layer: Control
var active_tiles: Dictionary = {}  # Vector2i(r,c) -> Panel
var pending_spawn := {}            # {row, col} of the newly spawned tile
var animating := false
var best_score := 0

var score_label: Label
var best_label: Label
var result_label: Label

# ── Helpers ────────────────────────────────────────────────────────────────────

func _tile_pos(r: int, c: int) -> Vector2:
	return Vector2(c * STEP + GAP, r * STEP + GAP)

func _make_tile(r: int, c: int, val: int) -> Panel:
	var panel := Panel.new()
	panel.size         = Vector2(TILE_SIZE, TILE_SIZE)
	panel.position     = _tile_pos(r, c)
	panel.pivot_offset = Vector2(TILE_SIZE, TILE_SIZE) * 0.5

	var sb := StyleBoxFlat.new()
	sb.bg_color = TILE_COLORS.get(val, Color("#3c3a32"))
	sb.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", sb)

	var lbl := Label.new()
	lbl.text = str(val)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.add_theme_font_size_override("font_size", 28 if val >= 1000 else 36)
	lbl.add_theme_color_override("font_color",
		Color("#776e65") if val <= 4 else Color.WHITE)
	panel.add_child(lbl)
	return panel

func _rebuild_tiles() -> void:
	for tile in active_tiles.values():
		if is_instance_valid(tile):
			tile.queue_free()
	active_tiles.clear()

	var grid: Array = board.get_grid()
	for r in 4:
		for c in 4:
			var val: int = grid[r][c]
			if val == 0:
				continue
			var tile := _make_tile(r, c, val)
			tile_layer.add_child(tile)
			active_tiles[Vector2i(r, c)] = tile

# ── Scene setup ────────────────────────────────────────────────────────────────

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Background
	var bg := ColorRect.new()
	bg.color = Color("#faf8ef")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)

	# ── Header ────────────────────────────────────────────────────────────────
	var hm := MarginContainer.new()
	for s: String in ["left", "right", "top"]:
		hm.add_theme_constant_override("margin_" + s, 16)
	vbox.add_child(hm)

	var header := HBoxContainer.new()
	hm.add_child(header)

	var title := Label.new()
	title.text = "2048"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color("#776e65"))
	header.add_child(title)

	score_label = Label.new()
	score_label.text = "Score\n0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 17)
	header.add_child(score_label)

	best_label = Label.new()
	best_label.text = "Best\n0"
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_label.add_theme_font_size_override("font_size", 17)
	header.add_child(best_label)

	# ── Board panel ───────────────────────────────────────────────────────────
	var bm := MarginContainer.new()
	for s: String in ["left", "right"]:
		bm.add_theme_constant_override("margin_" + s, 16)
	bm.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(bm)

	var board_panel := Panel.new()
	board_panel.custom_minimum_size = Vector2(BOARD_SIZE, BOARD_SIZE)
	var board_sb := StyleBoxFlat.new()
	board_sb.bg_color = Color("#bbada0")
	board_sb.set_corner_radius_all(8)
	board_panel.add_theme_stylebox_override("panel", board_sb)
	bm.add_child(board_panel)

	# Empty cell backgrounds
	for r: int in 4:
		for c: int in 4:
			var cell := ColorRect.new()
			cell.color    = Color("#cdc1b4")
			cell.size     = Vector2(TILE_SIZE, TILE_SIZE)
			cell.position = _tile_pos(r, c)
			board_panel.add_child(cell)

	# Tile layer (above empty cells)
	tile_layer = Control.new()
	tile_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_panel.add_child(tile_layer)

	# ── Footer ────────────────────────────────────────────────────────────────
	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 20)
	result_label.add_theme_color_override("font_color", Color("#f65e3b"))
	vbox.add_child(result_label)

	var new_game_btn := Button.new()
	new_game_btn.text = "New Game"
	new_game_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	new_game_btn.pressed.connect(_on_new_game)
	vbox.add_child(new_game_btn)

	# ── Board logic ───────────────────────────────────────────────────────────
	board = BoardScript.new()
	add_child(board)
	board.board_moved.connect(_on_board_moved)
	board.tile_spawned.connect(func(r, c, _v): pending_spawn = {row = r, col = c})
	board.score_changed.connect(_on_score_changed)
	board.game_won.connect(func(): result_label.text = "You Win!  Keep going?")
	board.game_over.connect(func(): result_label.text = "Game Over!")

	_on_new_game()

# ── Animation ──────────────────────────────────────────────────────────────────

func _on_board_moved(moves: Array) -> void:
	animating = true

	# Collect merge-target positions (where a secondary tile lands)
	var merge_targets: Dictionary = {}
	for m: Dictionary in moves:
		if m.secondary:
			merge_targets[Vector2i(m.tr, m.tc)] = true

	# Lower z-index of secondary tiles so they slide UNDER primaries
	for m: Dictionary in moves:
		if m.secondary:
			var t = active_tiles.get(Vector2i(m.fr, m.fc))
			if t:
				t.z_index = 0

	# ── Phase 1: slide ────────────────────────────────────────────────────────
	var slide := create_tween()
	slide.set_parallel(true)
	for m: Dictionary in moves:
		var tile = active_tiles.get(Vector2i(m.fr, m.fc))
		if not tile:
			continue
		var tp := _tile_pos(m.tr, m.tc)
		if not (m.fr == m.tr and m.fc == m.tc):
			slide.tween_property(tile, "position", tp, T_SLIDE) \
				.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		if m.secondary:
			# Fade as it slides under the primary
			slide.tween_property(tile, "modulate:a", 0.0, T_SLIDE)
	await slide.finished

	# ── Phase 2: rebuild + pop merges ─────────────────────────────────────────
	_rebuild_tiles()

	if not merge_targets.is_empty():
		var pop_out := create_tween()
		pop_out.set_parallel(true)
		for pos: Vector2i in merge_targets:
			var tile = active_tiles.get(pos)
			if tile and is_instance_valid(tile):
				pop_out.tween_property(tile, "scale", Vector2(1.18, 1.18), T_POP) \
					.set_ease(Tween.EASE_OUT)
		await pop_out.finished

		var pop_in := create_tween()
		pop_in.set_parallel(true)
		for pos: Vector2i in merge_targets:
			var tile = active_tiles.get(pos)
			if tile and is_instance_valid(tile):
				pop_in.tween_property(tile, "scale", Vector2.ONE, T_POP) \
					.set_ease(Tween.EASE_IN)
		await pop_in.finished

	# ── Phase 3: spawn new tile ───────────────────────────────────────────────
	if not pending_spawn.is_empty():
		var spawn_tile = active_tiles.get(Vector2i(pending_spawn.row, pending_spawn.col))
		if spawn_tile and is_instance_valid(spawn_tile):
			spawn_tile.scale = Vector2.ZERO
			var sp := create_tween()
			sp.tween_property(spawn_tile, "scale", Vector2.ONE, T_SPAWN) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			await sp.finished
		pending_spawn = {}

	animating = false

# ── Input & game events ────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if animating:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var dir := -1
		match event.keycode:
			KEY_UP,    KEY_W: dir = 0
			KEY_RIGHT, KEY_D: dir = 1
			KEY_DOWN,  KEY_S: dir = 2
			KEY_LEFT,  KEY_A: dir = 3
		if dir >= 0:
			board.move(dir)

func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score\n%d" % new_score
	if new_score > best_score:
		best_score = new_score
		best_label.text = "Best\n%d" % best_score

func _on_new_game() -> void:
	if animating:
		return
	board.new_game()
	result_label.text  = ""
	score_label.text   = "Score\n0"
	pending_spawn      = {}

	# Build tiles at scale 0, then pop them in
	for tile in active_tiles.values():
		if is_instance_valid(tile):
			tile.queue_free()
	active_tiles.clear()

	var grid: Array = board.get_grid()
	for r: int in 4:
		for c: int in 4:
			var val: int = grid[r][c]
			if val == 0:
				continue
			var tile := _make_tile(r, c, val)
			tile.scale = Vector2.ZERO
			tile_layer.add_child(tile)
			active_tiles[Vector2i(r, c)] = tile

	var sp := create_tween()
	sp.set_parallel(true)
	for tile in active_tiles.values():
		sp.tween_property(tile, "scale", Vector2.ONE, T_SPAWN) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
