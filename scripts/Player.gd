extends CharacterBody2D

const GRAVITY = 980.0
const JUMP_VELOCITY = -550.0  # Увеличена сила прыжка
const JUMP_GRAVITY_MULTIPLIER = 0.5  # Множитель гравитации при удержании кнопки прыжка (меньше = выше прыжок)

@export var run_speed: float = 220.0

# Состояния персонажа
enum PlayerState {
	STAND,    # Стоит (до начала игры)
	RUN,      # Бежит
	FLY,      # Летит (в прыжке)
	DUCK      # Нагнулся (уворот в воздухе)
}

var ground_y: float = 300.0  # Позиция земли (динамическая)
var is_on_ground: bool = true
var current_state: PlayerState = PlayerState.STAND
var is_ducking: bool = false
var game_started: bool = false
var jump_held: bool = false  # Флаг удержания кнопки прыжка

# Кешируем ссылку на game для проверки паузы
var game_node = null

# Текстуры для состояний
@onready var sprite = $Sprite2D
var texture_stand = preload("res://assets/player/Group 827.png")
var texture_run = preload("res://assets/player/Group 828.png")
var texture_fly = preload("res://assets/player/Group (1).png")
var texture_duck = preload("res://assets/player/Group 829.png")

# Анимация бега
var run_animation_time: float = 0.0
var run_animation_speed: float = 8.0  # Скорость анимации

func _ready():
	# Добавляем игрока в группу для проверки столкновений
	add_to_group("player")
	
	# Кешируем ссылку на game
	game_node = get_tree().get_first_node_in_group("game")
	
	# Получаем начальную позицию земли
	var viewport = get_viewport()
	if viewport:
		var screen_height = viewport.get_visible_rect().size.y
		# Для горизонтального экрана 812x375: пол внизу, персонаж на высоте пола
		ground_y = screen_height - 59  # Высота пола 59px, персонаж на уровне пола
		position.y = ground_y
	
	# Начальное состояние - стоит
	_update_state(PlayerState.STAND)

func update_ground_position(screen_height: float):
	# Для горизонтального экрана: пол внизу (высота пола 59px)
	ground_y = screen_height - 59
	# Если игрок на земле, обновляем его позицию
	if is_on_ground:
		position.y = ground_y

func _physics_process(delta):
	# Проверяем паузу игры (используем кешированную ссылку)
	if game_node == null:
		game_node = get_tree().get_first_node_in_group("game")
	
	if game_node and game_node.is_paused:
		velocity.x = 0
		velocity.y = 0
		move_and_slide()
		return
	
	# Применяем гравитацию только если не на земле
	if not is_on_ground:
		# Если удерживаем кнопку прыжка и летим вверх - уменьшаем гравитацию (длинный прыжок)
		# Если отпустили кнопку или падаем вниз - полная гравитация (короткий прыжок)
		var gravity_multiplier = 1.0
		if jump_held and velocity.y < 0:
			gravity_multiplier = JUMP_GRAVITY_MULTIPLIER
		velocity.y += GRAVITY * delta * gravity_multiplier
	
	# В раннере персонаж стоит на месте, мир движется мимо него
	# Горизонтальная скорость = 0
	velocity.x = 0
	
	# Сохраняем позицию X, чтобы персонаж не двигался горизонтально
	var saved_x = position.x
	
	# Применяем движение ПЕРЕД проверкой приземления
	move_and_slide()
	
	# Восстанавливаем позицию X (персонаж не должен двигаться горизонтально)
	position.x = saved_x
	
	# Проверка на землю ПОСЛЕ move_and_slide()
	# КРИТИЧНО: сначала проверяем, летим ли мы вверх - если да, точно не на земле
	if velocity.y < 0:
		# Летим вверх - точно не на земле
		is_on_ground = false
	elif velocity.y >= 0.0 and position.y >= ground_y:
		# Падаем вниз И достигли земли - приземляемся
		position.y = ground_y
		is_on_ground = true
		velocity.y = 0
		jump_held = false  # Сбрасываем флаг прыжка при приземлении
		# НЕ сбрасываем is_ducking здесь - пусть игрок сам отпускает кнопку
	elif position.y < ground_y:
		# Мы выше земли - точно не на земле
		is_on_ground = false
	
	# Обновляем состояние в зависимости от позиции и действий
	# ВАЖНО: если is_ducking активен, НЕ вызываем _update_animation_state, чтобы не перезаписать DUCK
	# _update_animation_state вызывается только если duck не активен
	if is_ducking:
		# Если duck активен, ВСЕГДА устанавливаем состояние DUCK и текстуру
		# Это гарантирует, что состояние не будет перезаписано
		if current_state != PlayerState.DUCK:
			_update_state(PlayerState.DUCK)
		# Дополнительная проверка - если текстура не установлена, устанавливаем её принудительно
		if sprite.texture != texture_duck:
			sprite.texture = texture_duck
			sprite.position = Vector2(0, 0)
	else:
		_update_animation_state()
	
	# Анимация бега (покачивание вверх-вниз)
	if current_state == PlayerState.RUN:
		run_animation_time += delta * run_animation_speed
		sprite.position.y = sin(run_animation_time) * 3.0  # Покачивание на 3 пикселя
	else:
		sprite.position = Vector2(0, 0)  # Сбрасываем позицию спрайта

func _update_animation_state():
	if not game_started:
		_update_state(PlayerState.STAND)
		return
	
	# Duck может быть как на земле (slide), так и в воздухе
	# ВАЖНО: проверяем is_ducking ПЕРВЫМ, чтобы duck состояние имело приоритет
	if is_ducking:
		# Если duck активен, всегда показываем duck состояние
		if current_state != PlayerState.DUCK:
			_update_state(PlayerState.DUCK)
	elif not is_on_ground:
		# В воздухе и не duck - летим
		if current_state != PlayerState.FLY:
			_update_state(PlayerState.FLY)
	elif is_on_ground:
		# На земле и не duck - бежим
		if current_state != PlayerState.RUN:
			_update_state(PlayerState.RUN)

func _update_state(new_state: PlayerState):
	if current_state == new_state:
		return
	
	current_state = new_state
	
	match new_state:
		PlayerState.STAND:
			sprite.texture = texture_stand
			run_animation_time = 0.0
		PlayerState.RUN:
			sprite.texture = texture_run
			run_animation_time = 0.0
		PlayerState.FLY:
			sprite.texture = texture_fly
			sprite.position = Vector2(0, 0)  # Сбрасываем позицию спрайта
		PlayerState.DUCK:
			sprite.texture = texture_duck
			sprite.position = Vector2(0, 0)  # Сбрасываем позицию спрайта

func start_game():
	game_started = true
	_update_state(PlayerState.RUN)

func jump():
	print("=== JUMP CALLED ===")
	print("game_started: ", game_started, " is_on_ground: ", is_on_ground, " is_ducking: ", is_ducking)
	if game_started:
		if is_ducking and is_on_ground:
			# Если на земле в состоянии duck, отменяем duck и прыгаем
			stop_duck()
			is_on_ground = false
			velocity.y = JUMP_VELOCITY
			jump_held = true  # Устанавливаем флаг удержания прыжка
			_update_state(PlayerState.FLY)
			print("Jump from duck executed - velocity.y: ", velocity.y)
		elif is_on_ground:
			# Прыжок с земли
			is_on_ground = false
			velocity.y = JUMP_VELOCITY
			jump_held = true  # Устанавливаем флаг удержания прыжка
			_update_state(PlayerState.FLY)
			print("Jump executed - velocity.y: ", velocity.y)
		elif is_ducking:
			# Возврат из положения нагнулся в воздухе в исходное (летит)
			stop_duck()
			print("Stop duck called")

func stop_jump():
	# Отпускание кнопки прыжка - сбрасываем флаг для применения полной гравитации
	jump_held = false
	print("Jump released - jump_held: ", jump_held)

func duck():
	print("=== DUCK CALLED ===")
	print("BEFORE - game_started: ", game_started, " is_on_ground: ", is_on_ground, " is_ducking: ", is_ducking, " current_state: ", current_state)
	# Duck работает и на земле (slide под низкими препятствиями), и в воздухе
	if game_started:
		is_ducking = true
		print("is_ducking set to true, calling _update_state(DUCK)")
		_update_state(PlayerState.DUCK)
		print("AFTER - is_ducking: ", is_ducking, " current_state: ", current_state)
	else:
		print("Duck FAILED - game not started!")

func stop_duck():
	is_ducking = false
	# Обновляем состояние в зависимости от того, на земле или в воздухе
	if not is_on_ground:
		_update_state(PlayerState.FLY)
	else:
		_update_state(PlayerState.RUN)
