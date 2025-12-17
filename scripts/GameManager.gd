extends Node

const SAVE_FILE_PATH = "user://savegame.save"
const HIGH_SCORE_KEY = "high_score"

var high_score: int = 0

func _ready():
	load_high_score()

func get_high_score() -> int:
	return high_score

func update_high_score(new_score: int):
	if new_score > high_score:
		high_score = new_score
		save_high_score()

func save_high_score():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_var({HIGH_SCORE_KEY: high_score})
		file.close()

func load_high_score():
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if file:
			var data = file.get_var()
			if data and data.has(HIGH_SCORE_KEY):
				high_score = data[HIGH_SCORE_KEY]
			file.close()
