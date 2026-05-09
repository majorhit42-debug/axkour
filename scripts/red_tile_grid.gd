extends Node3D

const HAZARD_TILE := preload("res://scenes/hazard/hazard_tile.tscn")
const TILE_SIZE := 2.0

# Pattern: rows separated by newlines, cells separated by spaces.
# 'R' = red (lethal), 'S' (or anything else non-empty) = safe.
@export_multiline var pattern: String = """
S S R R S S
R S S R S S
R S R S S R
S S S S R S
S R R S S S
S S S R S S
"""

func _ready() -> void:
	_build_grid()

func _build_grid() -> void:
	var rows := pattern.strip_edges().split("\n", false)
	for z_idx in rows.size():
		var row_str: String = rows[z_idx].strip_edges()
		if row_str.is_empty():
			continue
		var cells := row_str.split(" ", false)
		for x_idx in cells.size():
			var ch: String = cells[x_idx].strip_edges().to_upper()
			if ch.is_empty():
				continue
			var tile := HAZARD_TILE.instantiate()
			tile.is_red = (ch == "R")
			add_child(tile)
			tile.position = Vector3(x_idx * TILE_SIZE, 0, z_idx * TILE_SIZE)
