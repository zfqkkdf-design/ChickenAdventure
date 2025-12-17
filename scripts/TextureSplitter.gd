@tool
extends EditorScript

# Скрипт для разделения текстуры с камнями на 9 частей
# Запустите через Project -> Tools -> TextureSplitter в редакторе Godot

func _run():
	var texture_path = "res://assets/obstacle ground/stones.png"  # Укажите путь к файлу с камнями
	var output_dir = "res://assets/obstacle ground/stones/"  # Папка для сохранения
	
	# Проверяем существование файла
	if not ResourceLoader.exists(texture_path):
		print("ERROR: Файл не найден: ", texture_path)
		print("Пожалуйста, укажите правильный путь к файлу с камнями")
		return
	
	# Загружаем текстуру
	var texture = load(texture_path) as Texture2D
	if not texture:
		print("ERROR: Не удалось загрузить текстуру: ", texture_path)
		return
	
	var image = texture.get_image()
	if not image:
		print("ERROR: Не удалось получить изображение из текстуры")
		return
	
	var img_width = image.get_width()
	var img_height = image.get_height()
	
	# Предполагаем, что камни расположены в сетке 3x3
	var cols = 3
	var rows = 3
	var cell_width = img_width / cols
	var cell_height = img_height / rows
	
	print("Размер изображения: ", img_width, "x", img_height)
	print("Размер одной ячейки: ", cell_width, "x", cell_height)
	
	# Создаем папку для сохранения (если не существует)
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(output_dir):
		dir.make_dir_recursive(output_dir)
		print("Создана папка: ", output_dir)
	
	# Разрезаем на части
	for row in range(rows):
		for col in range(cols):
			var x = col * cell_width
			var y = row * cell_height
			
			# Извлекаем часть изображения
			var sub_image = image.get_region(Rect2i(x, y, cell_width, cell_height))
			
			# Сохраняем как PNG
			var filename = output_dir + "stone_" + str(row * cols + col + 1) + ".png"
			sub_image.save_png(filename)
			print("Сохранено: ", filename)
	
	print("Готово! Все 9 камней сохранены в: ", output_dir)

