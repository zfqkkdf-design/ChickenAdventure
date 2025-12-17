extends Node2D

@onready var player = $GameplayLayer/Player
@onready var up_button = $UI/ControlsContainer/UpButton
@onready var down_button = $UI/ControlsContainer/DownButton
@onready var pause_button = $UI/PauseButton
@onready var score_label = $UI/TopBar/ScoreDisplay/ScoreLabel
@onready var hearts_sprite = $UI/HeartsContainer/HeartsSprite
# Панель паузы
@onready var pause_overlay = $UI/PauseOverlay
@onready var pause_panel = $UI/PausePanel
@onready var pause_current_score_label = $UI/PausePanel/ScoreContainer/CurrentScore/CurrentScoreLabel
@onready var pause_best_score_label = $UI/PausePanel/ScoreContainer/BestScore/BestScoreLabel
@onready var pause_home_button = $UI/PausePanel/ButtonsContainer/HomeButton
@onready var pause_restart_button = $UI/PausePanel/ButtonsContainer/RestartButton
@onready var pause_resume_button = $UI/PausePanel/ButtonsContainer/ResumeButton
@onready var pause_sound_button = $UI/PausePanel/BottomButtons/SoundButton
@onready var pause_music_button = $UI/PausePanel/BottomButtons/MusicButton
# Панель Game Over
@onready var game_over_overlay = $UI/GameOverOverlay
@onready var game_over_panel = $UI/GameOverPanel
@onready var game_over_current_score_label = $UI/GameOverPanel/ScoreContainer/CurrentScore/CurrentScoreLabel
@onready var game_over_best_score_label = $UI/GameOverPanel/ScoreContainer/BestScore/BestScoreLabel
@onready var game_over_home_button = $UI/GameOverPanel/ButtonsContainer/HomeButton
@onready var game_over_restart_button = $UI/GameOverPanel/ButtonsContainer/RestartButton
@onready var game_over_sound_button = $UI/GameOverPanel/BottomButtons/SoundButton
@onready var game_over_music_button = $UI/GameOverPanel/BottomButtons/MusicButton

# Проверка инициализации кнопок
var buttons_ready: bool = false
@onready var sky_background = $BackgroundLayer/SkyBackground
@onready var sky_gradient = $BackgroundLayer/SkyGradient
@onready var cloud = $BackgroundLayer/Cloud
@onready var sun = $BackgroundLayer/SunMoonLayer/Sun
@onready var moon = $BackgroundLayer/SunMoonLayer/Moon
@onready var night_overlay = $BackgroundLayer/NightOverlay
@onready var road = $BackgroundLayer/Road  # Пол/дорога для затемнения
@onready var ground_background = $BackgroundLayer/GroundBackground  # Фоновая текстура над землей для затемнения

const OBSTACLE_SCENE = preload("res://scenes/Obstacle.tscn")
const EGG_SCENE = preload("res://scenes/Egg.tscn")
const SEED_SCENE = preload("res://scenes/Seed.tscn")

var score: int = 0
var lives: int = 3  # 3 жизни
var max_lives: int = 3
var is_paused: bool = false
var spawn_timer: float = 0.0
var spawn_interval: float = 2.0
var screen_width: float = 1080.0
var screen_height: float = 1920.0
var game_started: bool = false
var hearts_texture_width: float = 0.0
var invulnerable: bool = false  # Неуязвимость после удара
# Настройки звука и музыки
var sound_enabled: bool = true
var music_enabled: bool = true

# Система скорости игры
var base_speed: float = 200.0  # Базовая скорость объектов
var current_speed: float = 200.0  # Текущая скорость (увеличивается со временем)
var speed_increase_rate: float = 5.0  # На сколько увеличивается скорость в секунду
var max_speed: float = 500.0  # Максимальная скорость
var game_time: float = 0.0  # Время игры для расчета скорости

# Система день/ночь
var is_day: bool = true
var sun_position: float = -100.0
var moon_position: float = 900.0
var day_night_timer: float = 0.0
var day_duration: float = 30.0  # Длительность дня в секундах
var transition_duration: float = 5.0  # Длительность перехода

func _ready():
	add_to_group("game")
	
	# Небольшая задержка для инициализации всех узлов
	await get_tree().process_frame
	
	# Подключаем кнопки с проверкой на существование
	if up_button:
		up_button.pressed.connect(_on_up_pressed)
		up_button.button_up.connect(_on_up_released)
		print("Up button connected")
	else:
		print("ERROR: Up button not found!")
	
	if down_button:
		down_button.pressed.connect(_on_down_pressed)
		# НЕ используем button_up - вместо этого проверяем состояние кнопки в _process
		print("Down button connected")
	else:
		print("ERROR: Down button not found!")
	
	if pause_button:
		pause_button.pressed.connect(_on_pause_pressed)
		print("Pause button connected")
	else:
		print("ERROR: Pause button not found!")
	
	# Подключаем кнопки панели паузы
	if pause_home_button:
		pause_home_button.pressed.connect(_on_pause_home_pressed)
	if pause_restart_button:
		pause_restart_button.pressed.connect(_on_pause_restart_pressed)
	if pause_resume_button:
		pause_resume_button.pressed.connect(_on_pause_resume_pressed)
	if pause_sound_button:
		pause_sound_button.pressed.connect(_on_pause_sound_pressed)
	if pause_music_button:
		pause_music_button.pressed.connect(_on_pause_music_pressed)
	
	# Подключаем кнопки панели Game Over
	if game_over_home_button:
		game_over_home_button.pressed.connect(_on_game_over_home_pressed)
	if game_over_restart_button:
		game_over_restart_button.pressed.connect(_on_game_over_restart_pressed)
	if game_over_sound_button:
		game_over_sound_button.pressed.connect(_on_game_over_sound_pressed)
	if game_over_music_button:
		game_over_music_button.pressed.connect(_on_game_over_music_pressed)
	
	buttons_ready = true
	
	# Получаем размер экрана
	_update_screen_size()
	
	# Подписываемся на изменение размера viewport
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	# Инициализация системы жизней
	_init_hearts()
	
	# Настройка игрового цикла
	set_process(true)
	set_process_input(true)  # Включаем обработку ввода
	
	# Запускаем игру через небольшую задержку
	await get_tree().create_timer(0.5).timeout
	start_game()

func _init_hearts():
	# Получаем ширину текстуры сердец для обрезки
	if hearts_sprite and hearts_sprite.texture:
		hearts_texture_width = hearts_sprite.texture.get_width()
		_update_hearts_display()

func start_game():
	game_started = true
	game_time = 0.0  # Сбрасываем время игры
	current_speed = base_speed  # Сбрасываем скорость
	# Убеждаемся, что кнопки управления включены
	if up_button:
		up_button.disabled = false
	if down_button:
		down_button.disabled = false
	if player:
		player.start_game()

func _update_screen_size():
	var viewport = get_viewport()
	var size = viewport.get_visible_rect().size
	screen_width = size.x
	screen_height = size.y
	
	# Обновляем позицию игрока относительно размера экрана
	if player:
		player.update_ground_position(screen_height)
	
	# Обновляем позицию игрока на экране (горизонтальная ориентация 812x375)
	if player:
		player.position.x = screen_width * 0.25  # 25% от ширины экрана (левее центра, чтобы не перекрывался кнопками)
		# Позиция Y будет установлена в update_ground_position

func _on_viewport_size_changed():
	_update_screen_size()

func _process(delta):
	if not is_paused and game_started:
		# Увеличиваем скорость игры со временем
		game_time += delta
		current_speed = min(base_speed + speed_increase_rate * game_time, max_speed)
		
		# Генерация препятствий и собираемых предметов
		spawn_timer += delta
		if spawn_timer >= spawn_interval:
			spawn_timer = 0.0
			spawn_objects()
		
		# Обновление системы день/ночь
		_update_day_night(delta)
		
		# Анимация облака (медленное движение)
		if cloud:
			cloud.position.x -= 20.0 * delta
			if cloud.position.x < -200:
				cloud.position.x = screen_width + 200
	
	# Проверяем удержание кнопки вниз каждый кадр через button_pressed
	# Это гарантирует, что duck состояние поддерживается, пока кнопка удерживается
	if down_button and down_button.button_pressed and player and game_started and not is_paused and not get_tree().paused:
		# Если кнопка удерживается, принудительно устанавливаем is_ducking и состояние DUCK
		# Это критически важно - без этого состояние может быть перезаписано
		if not down_button_pressed:
			# Кнопка только что была нажата
			down_button_pressed = true
			player.duck()
		else:
			# Кнопка продолжает удерживаться
			if not player.is_ducking:
				player.is_ducking = true
			if player.current_state != player.PlayerState.DUCK:
				player._update_state(player.PlayerState.DUCK)
			# Дополнительная проверка - принудительно устанавливаем текстуру
			if player.sprite and player.sprite.texture != player.texture_duck:
				player.sprite.texture = player.texture_duck
				player.sprite.position = Vector2(0, 0)
	elif down_button_pressed:
		# Кнопка была отпущена
		down_button_pressed = false
		if player:
			player.stop_duck()
			print("Stop duck from button (released) - is_ducking: ", player.is_ducking, " current_state: ", player.current_state)

func _unhandled_input(event):
	# Обработка тапов по экрану (для мобильных) и кликов мыши (для компьютера)
	var is_touch = event is InputEventScreenTouch
	var is_mouse = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT
	
	if is_touch or is_mouse:
		var pressed = false
		var pos = Vector2()
		
		if is_touch:
			pressed = event.pressed
			pos = event.position
		elif is_mouse:
			pressed = event.pressed
			pos = event.position
		
		# Проверяем состояние паузы и Game Over
		if is_paused or get_tree().paused:
			return
		
		# ВАЖНО: Если кнопка вниз удерживается, НЕ обрабатываем события в _unhandled_input
		# Это предотвращает конфликты между обработкой кнопки и тапом
		if down_button_pressed:
			return
		
		# Проверяем, не попал ли клик на UI элементы (кнопки, панели)
		# Если клик попал на кнопку или панель, не обрабатываем его здесь
		if _is_point_on_ui_element(pos):
			return
		
		# Проверяем, что игра началась и игрок существует
		if not game_started or not player:
			return
		
		print("Input detected - is_touch: ", is_touch, " is_mouse: ", is_mouse, " pressed: ", pressed, " player: ", player, " game_started: ", game_started)
		
		# Определяем, что делать по позиции тапа/клика
		# Верхняя часть экрана (50%) - прыжок, нижняя часть (50%) - наклон
		var viewport_height = get_viewport().get_visible_rect().size.y
		var jump_threshold = viewport_height * 0.5  # Граница между прыжком и наклоном (50/50)
		
		if pressed:
			# Нажатие
			if pos.y < jump_threshold:
				# Верхняя часть (50%) - прыжок
				player.jump()
				print("Jump from input called")
			else:
				# Нижняя часть (50%) - наклон
				player.duck()
				print("Duck from input called")
		else:
			# Отпускание
			if pos.y < jump_threshold:
				# Верхняя часть - отпускание прыжка
				player.stop_jump()
				print("Jump released from input")
			else:
				# Нижняя часть - отменяем duck
				player.stop_duck()
				print("Stop duck from input called")
		get_viewport().set_input_as_handled()

func _is_point_on_ui_element(pos: Vector2) -> bool:
	# Проверяем попадание на кнопки управления
	if down_button and down_button.visible and not down_button.disabled:
		var button_rect = down_button.get_global_rect()
		if button_rect.has_point(pos):
			return true
	
	if up_button and up_button.visible and not up_button.disabled:
		var button_rect = up_button.get_global_rect()
		if button_rect.has_point(pos):
			return true
	
	# Проверяем попадание на панель паузы
	if pause_panel and pause_panel.visible:
		var panel_rect = pause_panel.get_global_rect()
		if panel_rect.has_point(pos):
			return true
	
	# Проверяем попадание на панель Game Over
	if game_over_panel and game_over_panel.visible:
		var panel_rect = game_over_panel.get_global_rect()
		if panel_rect.has_point(pos):
			return true
	
	# Проверяем попадание на кнопку паузы
	if pause_button and pause_button.visible:
		var button_rect = pause_button.get_global_rect()
		if button_rect.has_point(pos):
			return true
	
	return false

func _on_up_pressed():
	print("Up button pressed")
	# Унифицируем проверки в том же порядке, что и в _unhandled_input
	# Проверяем состояние паузы и Game Over
	if is_paused or get_tree().paused:
		return
	
	# Проверяем, что игра началась и игрок существует
	if not game_started or not player:
		return
	
	# Все проверки пройдены - вызываем jump
	player.jump()
	print("Jump called")

func _on_up_released():
	print("Up button released")
	# Унифицируем проверки в том же порядке, что и в _unhandled_input
	# Проверяем состояние паузы и Game Over
	if is_paused or get_tree().paused:
		return
	
	# Проверяем, что игра началась и игрок существует
	if not game_started or not player:
		return
	
	# Все проверки пройдены - вызываем stop_jump
	player.stop_jump()
	print("Jump released")

# Флаг для отслеживания удержания кнопки вниз
var down_button_pressed: bool = false

func _on_down_pressed():
	print("=== DOWN BUTTON PRESSED ===")
	down_button_pressed = true
	# Копируем логику из _unhandled_input - вызываем player.duck() напрямую, как при тапе
	if player:
		player.duck()
		print("Duck from button called - is_ducking: ", player.is_ducking, " current_state: ", player.current_state)
	else:
		print("ERROR: player is null!")

# Удалено - теперь используем проверку button_pressed в _process вместо сигнала button_up



func _on_pause_pressed():
	if not game_started:
		return
	
	is_paused = not is_paused
	get_tree().paused = is_paused
	_update_pause_ui()

func _update_pause_ui():
	# Скрываем панель Game Over, если показываем паузу
	if game_over_overlay:
		game_over_overlay.visible = false
	if game_over_panel:
		game_over_panel.visible = false
	
	# Показываем/скрываем панель паузы
	if pause_overlay:
		pause_overlay.visible = is_paused
	if pause_panel:
		pause_panel.visible = is_paused
	
	# Отключаем/включаем кнопки управления во время паузы
	if up_button:
		up_button.disabled = is_paused
	if down_button:
		down_button.disabled = is_paused
	
	if is_paused:
		# Обновляем счет в панели паузы
		if pause_current_score_label:
			pause_current_score_label.text = str(score)
		if pause_best_score_label:
			var best_score = GameManager.get_high_score()
			pause_best_score_label.text = "BEST: " + str(best_score)
		
		# Обновляем визуальное состояние кнопок звука и музыки
		if pause_sound_button:
			if sound_enabled:
				pause_sound_button.modulate = Color(1, 1, 1, 1)
			else:
				pause_sound_button.modulate = Color(0.5, 0.5, 0.5, 1)
		if pause_music_button:
			if music_enabled:
				pause_music_button.modulate = Color(1, 1, 1, 1)
			else:
				pause_music_button.modulate = Color(0.5, 0.5, 0.5, 1)

func _on_pause_home_pressed():
	# Возврат в меню
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")

func _on_pause_restart_pressed():
	# Рестарт игры
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_pause_resume_pressed():
	# Продолжить игру
	is_paused = false
	get_tree().paused = false
	_update_pause_ui()

func _on_pause_sound_pressed():
	# Переключение звука
	sound_enabled = not sound_enabled
	# Обновляем визуальное состояние кнопки (как в меню)
	if pause_sound_button:
		if sound_enabled:
			pause_sound_button.modulate = Color(1, 1, 1, 1)  # Полная видимость
		else:
			pause_sound_button.modulate = Color(0.5, 0.5, 0.5, 1)  # Затемнённая
	print("Sound: ", "ON" if sound_enabled else "OFF")

func _on_pause_music_pressed():
	# Переключение музыки
	music_enabled = not music_enabled
	# Обновляем визуальное состояние кнопки (как в меню)
	if pause_music_button:
		if music_enabled:
			pause_music_button.modulate = Color(1, 1, 1, 1)  # Полная видимость
		else:
			pause_music_button.modulate = Color(0.5, 0.5, 0.5, 1)  # Затемнённая
	print("Music: ", "ON" if music_enabled else "OFF")

func lose_life():
	# Проверяем неуязвимость - защита от цепочки ударов
	if invulnerable:
		return
	
	# Проверяем, что дерево сцены еще существует
	if not is_inside_tree():
		return
	
	invulnerable = true
	lives -= 1
	_update_hearts_display()
	
	if lives <= 0:
		game_over()
	else:
		# Небольшая пауза при потере жизни (мягкий "стан")
		# Используем только is_paused, чтобы таймер работал
		is_paused = true
		await get_tree().create_timer(0.5).timeout
		if is_inside_tree():  # Проверяем, что объект еще в дереве
			is_paused = false
	
	# Неуязвимость на 0.8 секунды после удара
	if is_inside_tree():  # Проверяем, что объект еще в дереве
		await get_tree().create_timer(0.8).timeout
		if is_inside_tree():  # Проверяем еще раз перед изменением
			invulnerable = false

func restore_life():
	if lives < max_lives:
		lives += 1
		_update_hearts_display()

func _update_hearts_display():
	if not hearts_sprite or hearts_texture_width == 0:
		return
	
	# Защита от отрицательных значений
	lives = clamp(lives, 0, max_lives)
	
	# Вычисляем ширину для отображения (каждое сердце = 1/3 от общей ширины)
	var heart_width = hearts_texture_width / 3.0
	var display_width = heart_width * lives
	var texture_height = hearts_sprite.texture.get_height()
	
	# Обрезаем текстуру через region_rect (Sprite2D поддерживает это)
	hearts_sprite.region_enabled = true
	hearts_sprite.region_rect = Rect2(0, 0, display_width, texture_height)

func game_over():
	# Показываем экран Game Over
	print("Game Over! Score: ", score)
	# Ставим игру на паузу
	is_paused = true
	get_tree().paused = true
	# Показываем панель Game Over
	_update_game_over_ui()

func _update_game_over_ui():
	# Скрываем панель паузы, если показываем Game Over
	if pause_overlay:
		pause_overlay.visible = false
	if pause_panel:
		pause_panel.visible = false
	
	# Показываем панель Game Over
	if game_over_overlay:
		game_over_overlay.visible = true
	if game_over_panel:
		game_over_panel.visible = true
	
	# Отключаем кнопки управления во время Game Over
	if up_button:
		up_button.disabled = true
	if down_button:
		down_button.disabled = true
	
	# Обновляем счет в панели Game Over
	if game_over_current_score_label:
		game_over_current_score_label.text = str(score)
	if game_over_best_score_label:
		var best_score = GameManager.get_high_score()
		game_over_best_score_label.text = "BEST: " + str(best_score)
	
	# Обновляем визуальное состояние кнопок звука и музыки
	if game_over_sound_button:
		if sound_enabled:
			game_over_sound_button.modulate = Color(1, 1, 1, 1)
		else:
			game_over_sound_button.modulate = Color(0.5, 0.5, 0.5, 1)
	if game_over_music_button:
		if music_enabled:
			game_over_music_button.modulate = Color(1, 1, 1, 1)
		else:
			game_over_music_button.modulate = Color(0.5, 0.5, 0.5, 1)

func _on_game_over_home_pressed():
	# Возврат в меню
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")

func _on_game_over_restart_pressed():
	# Рестарт игры
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_game_over_sound_pressed():
	# Переключение звука
	sound_enabled = not sound_enabled
	# Обновляем визуальное состояние кнопки
	if game_over_sound_button:
		if sound_enabled:
			game_over_sound_button.modulate = Color(1, 1, 1, 1)
		else:
			game_over_sound_button.modulate = Color(0.5, 0.5, 0.5, 1)
	# Также обновляем в панели паузы, если она видна
	if pause_sound_button:
		if sound_enabled:
			pause_sound_button.modulate = Color(1, 1, 1, 1)
		else:
			pause_sound_button.modulate = Color(0.5, 0.5, 0.5, 1)
	print("Sound: ", "ON" if sound_enabled else "OFF")

func _on_game_over_music_pressed():
	# Переключение музыки
	music_enabled = not music_enabled
	# Обновляем визуальное состояние кнопки
	if game_over_music_button:
		if music_enabled:
			game_over_music_button.modulate = Color(1, 1, 1, 1)
		else:
			game_over_music_button.modulate = Color(0.5, 0.5, 0.5, 1)
	# Также обновляем в панели паузы, если она видна
	if pause_music_button:
		if music_enabled:
			pause_music_button.modulate = Color(1, 1, 1, 1)
		else:
			pause_music_button.modulate = Color(0.5, 0.5, 0.5, 1)
	print("Music: ", "ON" if music_enabled else "OFF")

func spawn_objects():
	# Случайно решаем, что спавнить
	var rand = randf()
	
	if rand < 0.25:  # 25% шанс на наземное препятствие
		spawn_obstacle()
	elif rand < 0.35:  # 10% шанс на воздушное препятствие (птица)
		spawn_air_obstacle()
	elif rand < 0.6:  # 25% шанс на яйцо
		spawn_egg()
	elif rand < 0.85:  # 25% шанс на семечко
		spawn_seed()
	# 15% шанс ничего не спавнить

func spawn_obstacle():
	var obstacle = OBSTACLE_SCENE.instantiate()
	obstacle.position.x = screen_width + 100
	# Устанавливаем текущую скорость игры
	obstacle.speed = current_speed
	# Устанавливаем тип как наземное препятствие (не BIRD)
	obstacle.is_air_obstacle = false
	# Добавляем препятствие в дерево
	$GameplayLayer.add_child(obstacle)
	# Устанавливаем позицию Y на том же уровне, что и игрок ПОСЛЕ добавления в дерево
	# Используем await для гарантии, что позиция установлена после _ready() препятствия
	if player:
		await get_tree().process_frame  # Ждем один кадр, чтобы _ready() выполнился
		var player_y = player.position.y
		obstacle.position.y = player_y
		# Дополнительно устанавливаем через call_deferred для гарантии
		obstacle.call_deferred("set_position_y", player_y)

func spawn_air_obstacle():
	# Спавним воздушное препятствие (птицу) на высоте прыжка
	var obstacle = OBSTACLE_SCENE.instantiate()
	obstacle.position.x = screen_width + 100
	# Устанавливаем текущую скорость игры
	obstacle.speed = current_speed
	# Устанавливаем тип как птицу (воздушное препятствие) ДО добавления в дерево
	# Это важно, чтобы _ready() правильно определил тип
	# BIRD = 12 (последний в enum ObstacleType)
	obstacle.obstacle_type = 12  # ObstacleType.BIRD
	obstacle.is_air_obstacle = true
	# Добавляем препятствие в дерево
	$GameplayLayer.add_child(obstacle)
	# Устанавливаем позицию Y на высоте прыжка (выше уровня игрока)
	# Высота прыжка примерно 100-150 пикселей от земли
	if player:
		await get_tree().process_frame  # Ждем один кадр, чтобы _ready() выполнился
		var player_ground_y = player.ground_y
		# Птица появляется на высоте прыжка (примерно 120 пикселей выше земли)
		# Это высота, на которой игрок может столкнуться с птицей во время прыжка
		var air_height = 120.0
		var bird_y = player_ground_y - air_height
		obstacle.position.y = bird_y
		# Дополнительно устанавливаем через call_deferred для гарантии
		obstacle.call_deferred("set_position_y", bird_y)

func spawn_egg():
	var egg = EGG_SCENE.instantiate()
	egg.position.x = screen_width + 100
	# Устанавливаем текущую скорость игры
	egg.speed = current_speed
	# Устанавливаем позицию Y - бонусы не должны быть выше середины экрана
	if player:
		var player_y = player.position.y
		var screen_middle = screen_height * 0.5  # Середина экрана
		# Бонусы появляются на уровне игрока, но не выше середины экрана
		egg.position.y = max(player_y, screen_middle)
	$GameplayLayer.add_child(egg)
	# Убеждаемся, что позиция Y установлена правильно после добавления
	if player:
		var player_y = player.position.y
		var screen_middle = screen_height * 0.5
		egg.position.y = max(player_y, screen_middle)

func spawn_seed():
	var seed_item = SEED_SCENE.instantiate()
	seed_item.position.x = screen_width + 100
	# Устанавливаем текущую скорость игры
	seed_item.speed = current_speed
	# Устанавливаем позицию Y - бонусы не должны быть выше середины экрана
	if player:
		var player_y = player.position.y
		var screen_middle = screen_height * 0.5  # Середина экрана
		# Бонусы появляются на уровне игрока, но не выше середины экрана
		seed_item.position.y = max(player_y, screen_middle)
	$GameplayLayer.add_child(seed_item)
	# Убеждаемся, что позиция Y установлена правильно после добавления
	if player:
		var player_y = player.position.y
		var screen_middle = screen_height * 0.5
		seed_item.position.y = max(player_y, screen_middle)

func add_score(points: int):
	score += points
	score_label.text = str(score)
	GameManager.update_high_score(score)

func _update_day_night(delta):
	day_night_timer += delta
	
	if is_day:
		# Движение солнца слева направо
		sun_position += (screen_width + 200) / day_duration * delta
		sun.position.x = sun_position
		
		# Когда солнце уходит за экран, начинается ночь
		if sun_position > screen_width + 100:
			is_day = false
			day_night_timer = 0.0
			# Луна появляется справа
			moon_position = screen_width + 100
			moon.position.x = moon_position
			moon.modulate.a = 1.0
			sun.modulate.a = 0.0
	else:
		# Движение луны справа налево
		moon_position -= (screen_width + 200) / day_duration * delta
		moon.position.x = moon_position
		
		# Когда луна уходит за экран, начинается день
		if moon_position < -100:
			is_day = true
			day_night_timer = 0.0
			# Солнце появляется слева
			sun_position = -100
			sun.position.x = sun_position
			sun.modulate.a = 1.0
			moon.modulate.a = 0.0
	
	# Плавное затемнение/осветление
	if is_day:
		# День - постепенно осветляем
		var progress = min(day_night_timer / transition_duration, 1.0)
		night_overlay.color.a = lerp(0.7, 0.0, progress)
		sky_background.color = Color(0.9, 0.95, 1, 1)  # Светлое небо
		# Пол и фоновая текстура - светлые
		if road:
			road.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Полная яркость
		if ground_background:
			ground_background.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Полная яркость
	else:
		# Ночь - постепенно затемняем
		var progress = min(day_night_timer / transition_duration, 1.0)
		night_overlay.color.a = lerp(0.0, 0.7, progress)
		sky_background.color = Color(0.3, 0.3, 0.4, 1)  # Темное небо
		sky_gradient.modulate.a = lerp(1.0, 0.2, progress)  # Затемняем градиент
		# Пол и фоновая текстура - темные (затемняем до 40% яркости)
		if road:
			var road_brightness = lerp(1.0, 0.4, progress)
			road.modulate = Color(road_brightness, road_brightness, road_brightness, 1.0)
		if ground_background:
			var ground_brightness = lerp(1.0, 0.4, progress)
			ground_background.modulate = Color(ground_brightness, ground_brightness, ground_brightness, 1.0)
