extends Area2D

enum ObstacleType {
	HAY,     # Сено
	BARREL,  # Бочка с сеном
	FOX,     # Лиса
	STONE_1, # Камень 1
	STONE_2, # Камень 2
	STONE_3, # Камень 3
	STONE_4, # Камень 4
	STONE_5, # Камень 5
	STONE_6, # Камень 6
	STONE_7, # Камень 7
	STONE_8, # Камень 8
	STONE_9, # Камень 9
	BIRD     # Птица (воздушное препятствие)
}

var obstacle_type: ObstacleType = ObstacleType.HAY
var ground_y: float = 300.0
var speed: float = 200.0  # Скорость будет устанавливаться из Game.gd
var is_air_obstacle: bool = false  # Флаг для воздушных препятствий

# Текстуры для разных типов препятствий
var texture_hay = preload("res://assets/obstacle ground/Group (3).png")
var texture_barrel = preload("res://assets/obstacle ground/Group 2.png")
var texture_fox = preload("res://assets/obstacle ground/Group (4).png")

# Текстуры камней (загружаются динамически, если файлы существуют)
var texture_stones = []

# Текстуры для птицы (анимация)
var texture_bird_1 = preload("res://assets/obstacle air/enemybird1.png")
var texture_bird_2 = preload("res://assets/obstacle air/enemybird2.png")

# Анимация птицы
var bird_animation_timer: float = 0.0
var bird_animation_speed: float = 0.15  # Скорость переключения кадров (секунды)
var bird_frame: int = 0  # Текущий кадр (0 или 1)

@onready var sprite = $Sprite2D

func _ready():
	# Загружаем текстуры камней (если они существуют)
	if texture_stones.is_empty():
		for i in range(1, 10):  # 9 камней
			var stone_path = "res://assets/obstacle ground/stones/stone_" + str(i) + ".png"
			if ResourceLoader.exists(stone_path):
				texture_stones.append(load(stone_path))
			else:
				# Если файл не найден, добавляем null
				texture_stones.append(null)
	
	# Тип препятствия устанавливается из Game.gd при спавне
	# Если тип не установлен, определяем случайно (для наземных препятствий)
	if obstacle_type == ObstacleType.HAY and not is_air_obstacle:
		# Определяем тип препятствия случайно для наземных
		# Считаем количество доступных типов (3 базовых + камни)
		var available_types = 3
		if not texture_stones.is_empty() and texture_stones[0] != null:
			available_types = 3 + texture_stones.size()  # 3 базовых + камни
		
		var rand_type = randi() % available_types
		obstacle_type = rand_type as ObstacleType
	
	# Устанавливаем соответствующую текстуру
	match obstacle_type:
		ObstacleType.HAY:
			sprite.texture = texture_hay
			is_air_obstacle = false
		ObstacleType.BARREL:
			sprite.texture = texture_barrel
			is_air_obstacle = false
		ObstacleType.FOX:
			sprite.texture = texture_fox
			is_air_obstacle = false
		ObstacleType.STONE_1, ObstacleType.STONE_2, ObstacleType.STONE_3, \
		ObstacleType.STONE_4, ObstacleType.STONE_5, ObstacleType.STONE_6, \
		ObstacleType.STONE_7, ObstacleType.STONE_8, ObstacleType.STONE_9:
			# Индекс камня (STONE_1 = 3, STONE_2 = 4, и т.д.)
			var stone_index = obstacle_type - ObstacleType.STONE_1
			if stone_index < texture_stones.size() and texture_stones[stone_index] != null:
				sprite.texture = texture_stones[stone_index]
			else:
				# Если камень не загружен, используем сено по умолчанию
				sprite.texture = texture_hay
			is_air_obstacle = false
		ObstacleType.BIRD:
			# Птица - воздушное препятствие
			sprite.texture = texture_bird_1
			is_air_obstacle = true
			bird_frame = 0
			bird_animation_timer = 0.0
	
	# Позиция Y устанавливается при спавне в Game.gd
	# Не устанавливаем position.y здесь, чтобы не перезаписывать позицию из Game.gd
	body_entered.connect(_on_body_entered)
	# Настраиваем collision layer для обнаружения персонажа
	collision_layer = 0
	collision_mask = 1  # Обнаруживаем объекты на слое 1 (Player)

# Функция для установки позиции Y (вызывается из Game.gd через call_deferred)
func set_position_y(y: float):
	position.y = y

func _process(delta):
	position.x -= speed * delta
	
	# Анимация птицы (переключение между двумя текстурами)
	if is_air_obstacle and obstacle_type == ObstacleType.BIRD:
		bird_animation_timer += delta
		if bird_animation_timer >= bird_animation_speed:
			bird_animation_timer = 0.0
			bird_frame = (bird_frame + 1) % 2  # Переключаем между 0 и 1
			if bird_frame == 0:
				sprite.texture = texture_bird_1
			else:
				sprite.texture = texture_bird_2
	
	# Удаляем препятствие, когда оно уходит за экран
	if position.x < -100:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Игрок столкнулся с препятствием - теряет жизнь
		var game = get_tree().get_first_node_in_group("game")
		if game:
			# Отключаем коллизию перед удалением, чтобы избежать повторных срабатываний
			# Используем call_deferred, так как нельзя изменять коллизию во время обработки запросов
			var collision = get_node_or_null("CollisionShape2D")
			if collision:
				collision.set_deferred("disabled", true)
			# Вызываем lose_life через call_deferred, чтобы избежать проблем с удалением
			game.call_deferred("lose_life")
		# Удаляем объект через call_deferred
		call_deferred("queue_free")
