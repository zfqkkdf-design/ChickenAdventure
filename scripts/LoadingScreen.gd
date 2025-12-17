extends Control

@onready var progress_bar = $UILayer/ProgressBar
@onready var logo = $LogoLayer/Logo

var loading_progress: float = 0.0
var target_progress: float = 0.0

func _ready():
	# Явно отключаем процесс перед инициализацией
	set_process(false)
	
	# Настройка прогресс бара
	if progress_bar:
		progress_bar.min_value = 0.0
		progress_bar.max_value = 100.0
		progress_bar.value = 0.0
	
	# Начинаем загрузку
	start_loading()

func start_loading():
	# Симулируем загрузку ресурсов
	load_resources()

func load_resources():
	# Предзагрузка основных ресурсов (используем простую загрузку для надежности на мобильных)
	# На мобильных устройствах threaded loading может работать некорректно
	var menu_scene = load("res://scenes/Menu.tscn")
	var game_scene = load("res://scenes/Game.tscn")
	
	# Запускаем процесс загрузки
	set_process(true)

var loading_time: float = 0.0
var min_loading_time: float = 1.5  # Минимальное время показа загрузочного экрана

func _process(delta):
	loading_time += delta
	
	# Обновляем прогресс загрузки
	update_loading_progress()
	
	# Плавно обновляем значение прогресс бара
	if progress_bar:
		var current_value = progress_bar.value
		var new_value = lerp(current_value, target_progress, delta * 2.0)
		progress_bar.value = new_value
		
		# Если загрузка завершена и прошло минимальное время, переходим в меню
		# Используем более надежную проверку: либо прогресс достиг 100%, либо прошло достаточно времени
		if (new_value >= 99.5 or target_progress >= 100.0) and loading_time >= min_loading_time:
			_on_loading_complete()

func update_loading_progress():
	# Простой прогресс на основе времени для надежности на мобильных устройствах
	# Ресурсы уже загружены в load_resources(), поэтому просто показываем прогресс по времени
	var time_progress = (loading_time / min_loading_time) * 100.0
	
	# Ограничиваем прогресс до 100%
	if time_progress > 100.0:
		time_progress = 100.0
	
	# Устанавливаем целевой прогресс
	target_progress = time_progress

func _on_loading_complete():
	set_process(false)
	
	# Небольшая задержка перед переходом
	await get_tree().create_timer(0.2).timeout
	
	# Переходим в главное меню
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")

