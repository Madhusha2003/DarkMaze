extends Node

# Maze Cell Types
const CELL_PATH = 0
const CELL_WALL = 1
const CELL_DOOR = 2
const CELL_EXIT = 3
const CELL_ITEM = 4

func _ready():
	# Increase the general game volume
	# 0.0 is the default. +6.0 dB is approximately double the perceived volume.
	var master_bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus_index, 6.0)
