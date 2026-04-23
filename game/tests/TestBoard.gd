extends SceneTree

var BoardScript = load("res://scripts/Board.gd")

var passed := 0
var failed := 0

func _init() -> void:
	print("=== 2048 Board Logic Tests ===")
	print("")

	test_new_game_tile_count()
	test_new_game_score()
	test_slide_left_merge()
	test_slide_right_merge()
	test_slide_up_merge()
	test_slide_down_merge()
	test_no_double_merge()
	test_score_accumulation()
	test_win_detection()
	test_game_over_detection()
	test_no_move_on_immovable()

	print("")
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)

func ok(desc: String) -> void:
	print("  PASS  " + desc)
	passed += 1

func fail(desc: String, got: Variant, expected: Variant) -> void:
	print("  FAIL  " + desc + " | got=" + str(got) + " expected=" + str(expected))
	failed += 1

func expect_eq(desc: String, got: Variant, expected: Variant) -> void:
	if got == expected:
		ok(desc)
	else:
		fail(desc, got, expected)

func expect_true(desc: String, value: bool) -> void:
	if value:
		ok(desc)
	else:
		fail(desc, value, true)

func make_board(grid_data: Array) -> Node:
	var b: Node = BoardScript.new()
	root.add_child(b)
	b.grid = []
	for row in grid_data:
		b.grid.append((row as Array).duplicate())
	b.score = 0
	return b

func test_new_game_tile_count() -> void:
	print("[new_game] starts with exactly 2 tiles")
	var b: Node = BoardScript.new()
	root.add_child(b)
	b.new_game()
	var count := 0
	for r in 4:
		for c in 4:
			if b.grid[r][c] != 0:
				count += 1
	expect_eq("2 tiles on new game", count, 2)
	b.queue_free()

func test_new_game_score() -> void:
	print("[new_game] score initialises to 0")
	var b: Node = BoardScript.new()
	root.add_child(b)
	b.new_game()
	expect_eq("score is 0", b.get_score(), 0)
	b.queue_free()

func test_slide_left_merge() -> void:
	print("[slide_left] adjacent equal tiles merge")
	var b := make_board([
		[0, 2, 0, 2],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	b.move(3)
	expect_eq("merged tile at [0][0] = 4", b.grid[0][0], 4)
	b.queue_free()

func test_slide_right_merge() -> void:
	print("[slide_right] adjacent equal tiles merge to rightmost")
	var b := make_board([
		[2, 2, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	b.move(1)
	expect_eq("merged tile at [0][3] = 4", b.grid[0][3], 4)
	b.queue_free()

func test_slide_up_merge() -> void:
	print("[slide_up] tiles in column merge to top")
	var b := make_board([
		[2, 0, 0, 0],
		[2, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	b.move(0)
	expect_eq("merged tile at [0][0] = 4", b.grid[0][0], 4)
	b.queue_free()

func test_slide_down_merge() -> void:
	print("[slide_down] tiles in column merge to bottom")
	var b := make_board([
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[2, 0, 0, 0],
		[2, 0, 0, 0],
	])
	b.move(2)
	expect_eq("merged tile at [3][0] = 4", b.grid[3][0], 4)
	b.queue_free()

func test_no_double_merge() -> void:
	print("[merge] [2,2,2,2] left -> [4,4,...] no double merge")
	var b := make_board([
		[2, 2, 2, 2],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	b.move(3)
	expect_eq("first merged pair = 4",  b.grid[0][0], 4)
	expect_eq("second merged pair = 4", b.grid[0][1], 4)
	b.queue_free()

func test_score_accumulation() -> void:
	print("[score] accumulates from merges")
	var b := make_board([
		[2, 2, 4, 4],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	b.move(3)  # -> [4, 8, 0, 0], score = 4 + 8 = 12
	expect_eq("score = 12 after two merges", b.get_score(), 12)
	b.queue_free()

func test_win_detection() -> void:
	print("[win] game_won emits and is_won() returns true after 1024+1024")
	var b := make_board([
		[1024, 1024, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
	])
	# Use a Dictionary (reference type) so the lambda can mutate shared state
	var state := {"won": false}
	b.game_won.connect(func(): state["won"] = true)
	b.move(3)
	expect_true("game_won signal emitted", state["won"])
	expect_true("is_won() returns true", b.is_won())
	b.queue_free()

func test_game_over_detection() -> void:
	print("[game_over] is_game_over() on full board with no merges")
	var b := make_board([
		[2,  4,  2,  4],
		[4,  2,  4,  2],
		[2,  4,  2,  4],
		[4,  2,  4,  2],
	])
	expect_true("is_game_over() = true on locked board", b.is_game_over())
	b.queue_free()

func test_no_move_on_immovable() -> void:
	print("[move] returns false when board cannot move")
	var b := make_board([
		[2,  4,  2,  4],
		[4,  2,  4,  2],
		[2,  4,  2,  4],
		[4,  2,  4,  2],
	])
	var moved: bool = b.move(3)
	expect_eq("move returns false on immovable board", moved, false)
	b.queue_free()
