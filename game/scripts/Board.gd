class_name Board
extends Node

const SIZE = 4

var grid: Array = []
var score: int = 0

signal tile_spawned(row: int, col: int, value: int)
signal score_changed(new_score: int)
signal game_won()
signal game_over()

func new_game() -> void:
	score = 0
	grid = []
	for _i in SIZE:
		grid.append([0, 0, 0, 0])
	_spawn_tile()
	_spawn_tile()

func move(direction: int) -> bool:
	var moved := false
	match direction:
		0: moved = _slide_up()
		1: moved = _slide_right()
		2: moved = _slide_down()
		3: moved = _slide_left()
	if moved:
		_spawn_tile()
		if _check_win():
			game_won.emit()
		elif _check_game_over():
			game_over.emit()
	return moved

func get_grid() -> Array:
	return grid

func get_score() -> int:
	return score

func is_game_over() -> bool:
	return _check_game_over()

func is_won() -> bool:
	return _check_win()

func _spawn_tile() -> void:
	var empty: Array = []
	for r in SIZE:
		for c in SIZE:
			if grid[r][c] == 0:
				empty.append([r, c])
	if empty.is_empty():
		return
	var pos: Array = empty[randi() % empty.size()]
	var val := 4 if randf() < 0.1 else 2
	grid[pos[0]][pos[1]] = val
	tile_spawned.emit(pos[0], pos[1], val)

func _compress(line: Array) -> Array:
	var out: Array = line.filter(func(x): return x != 0)
	while out.size() < SIZE:
		out.append(0)
	return out

func _merge(line: Array) -> Array:
	for i in range(SIZE - 1):
		if line[i] != 0 and line[i] == line[i + 1]:
			line[i] *= 2
			score += line[i]
			score_changed.emit(score)
			line[i + 1] = 0
	return line

func _process_line(line: Array) -> Array:
	line = _compress(line)
	line = _merge(line)
	line = _compress(line)
	return line

func _slide_left() -> bool:
	var moved := false
	for r in SIZE:
		var src: Array = grid[r]
		var new_row: Array = _process_line(src.duplicate())
		if new_row != grid[r]:
			moved = true
		grid[r] = new_row
	return moved

func _slide_right() -> bool:
	var moved := false
	for r in SIZE:
		var row: Array = (grid[r] as Array).duplicate()
		row.reverse()
		row = _process_line(row)
		row.reverse()
		if row != grid[r]:
			moved = true
		grid[r] = row
	return moved

func _slide_up() -> bool:
	var moved := false
	for c in SIZE:
		var col: Array = []
		for r in SIZE:
			col.append(grid[r][c])
		col = _process_line(col)
		for r in SIZE:
			if grid[r][c] != col[r]:
				moved = true
			grid[r][c] = col[r]
	return moved

func _slide_down() -> bool:
	var moved := false
	for c in SIZE:
		var col: Array = []
		for r in SIZE:
			col.append(grid[r][c])
		col.reverse()
		col = _process_line(col)
		col.reverse()
		for r in SIZE:
			if grid[r][c] != col[r]:
				moved = true
			grid[r][c] = col[r]
	return moved

func _check_win() -> bool:
	for r in SIZE:
		for c in SIZE:
			if grid[r][c] == 2048:
				return true
	return false

func _check_game_over() -> bool:
	for r in SIZE:
		for c in SIZE:
			if grid[r][c] == 0:
				return false
	for r in SIZE:
		for c in range(SIZE - 1):
			if grid[r][c] == grid[r][c + 1]:
				return false
	for c in SIZE:
		for r in range(SIZE - 1):
			if grid[r][c] == grid[r + 1][c]:
				return false
	return true
