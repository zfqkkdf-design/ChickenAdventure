extends Area2D

enum CollectibleType {
	EGG,    # Яйцо - даёт очки
	SEED    # Семечко - восстанавливает жизнь
}

const SCORE_VALUE = 1

var collectible_type: CollectibleType = CollectibleType.EGG
var ground_y: float = 300.0
var collected: bool = false
var speed: float = 200.0  # Скорость будет устанавливаться из Game.gd

func _ready():
	# Определяем тип по имени сцены
	if name.contains("Egg") or name == "Egg":
		collectible_type = CollectibleType.EGG
	elif name.contains("Seed") or name == "Seed":
		collectible_type = CollectibleType.SEED
	
	# Позиция Y устанавливается при спавне в Game.gd
	# Не устанавливаем position.y здесь, чтобы не перезаписывать позицию из Game.gd
	body_entered.connect(_on_body_entered)
	# Настраиваем collision layer для обнаружения персонажа
	collision_layer = 0
	collision_mask = 1  # Обнаруживаем объекты на слое 1 (Player)

func _process(delta):
	position.x -= speed * delta
	
	# Удаляем предмет, когда он уходит за экран
	if position.x < -100:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player") and not collected:
		collected = true
		# Уведомляем игру о собранном предмете
		var game = get_tree().get_first_node_in_group("game")
		if game:
			match collectible_type:
				CollectibleType.EGG:
					game.add_score(SCORE_VALUE)
				CollectibleType.SEED:
					game.restore_life()
		queue_free()
