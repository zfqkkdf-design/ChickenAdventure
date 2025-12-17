extends Control

@onready var play_button = $UILayer/PlayButton
@onready var sound_button = $UILayer/SoundButton
@onready var music_button = $UILayer/MusicButton

var sound_enabled: bool = true
var music_enabled: bool = true

func _ready():
	play_button.pressed.connect(_on_play_pressed)
	sound_button.pressed.connect(_on_sound_pressed)
	music_button.pressed.connect(_on_music_pressed)
	
	# Применяем наклон к текстовым подсказкам
	_apply_text_rotation()

func _apply_text_rotation():
	# Наклон текста "Collect the eggs" (вверх влево)
	var collect_label = $UILayer/CollectEggsLabel
	if collect_label:
		collect_label.rotation_degrees = -15.0
	
	# Наклон текста "Don't fall for the fox" (вверх вправо)
	var dont_fall_label = $UILayer/DontFallLabel
	if dont_fall_label:
		dont_fall_label.rotation_degrees = 15.0

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_sound_pressed():
	sound_enabled = not sound_enabled
	# TODO: Включить/выключить звуковые эффекты
	if sound_enabled:
		sound_button.text = "🔊"
	else:
		sound_button.text = "🔇"
	print("Sound: ", "ON" if sound_enabled else "OFF")

func _on_music_pressed():
	music_enabled = not music_enabled
	# TODO: Включить/выключить музыку
	if music_enabled:
		music_button.modulate = Color(1, 1, 1, 1)  # Полная видимость
	else:
		music_button.modulate = Color(0.5, 0.5, 0.5, 1)  # Затемнённая
	print("Music: ", "ON" if music_enabled else "OFF")
