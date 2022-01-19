extends TileMap

export(int) var obfuscation_tile_id = -1

# corner points of the tilemap.
var map_min_x: int
var map_max_x: int
var map_min_y: int
var map_max_y: int

# numerical representation of the tilemap. 2D Array.
# 0: empty tile, 1: affecting visibility (wall), 2: visible tile
var matrix: Array

# matching obfuscation to cells in matrix
var obfuscation: Array

var obfuscation_sprite: Sprite
var obfuscation_tween: Tween

func _ready():
	_get_map_extends()
	obfuscation_sprite = _make_obfuscation_sprite()
	obfuscation_tween = Tween.new()
	add_child(obfuscation_tween)
	_create_obfuscation()

#	obfuscation_tween.interpolate_property(sprite, "modulate:a", 0.0, 1.0, 10.0)
#	obfuscation_tween.start()

func _get_map_extends():
	"""
	set the corner points of the tilemap based on tile coordinates.
	"""
	var rec = get_used_rect()
	map_min_x = rec.position.x
	map_max_x = map_min_x + rec.size.x - 1
	map_min_y = rec.position.y
	map_max_y = map_min_y + rec.size.y - 1

func _make_obfuscation_sprite():
	"""
	make a sprite (from the selected obfuscation tile)
	that is used to cover invisible areas of the tilemap.
	"""
	assert(obfuscation_tile_id != -1, "obfuscation_tile_id needs to be set.")
	var sprite = Sprite.new()
	sprite.region_rect = tile_set.tile_get_region(obfuscation_tile_id)
	sprite.region_enabled = true
	sprite.texture = tile_set.tile_get_texture(obfuscation_tile_id)
	# sprites texture is centered by default. the position then would be tile_size / 2
	sprite.centered = false
	# set transparancy (alpha) (0: fully transparent, 1: not transparent)
	sprite.modulate.a = 0
	return sprite

func _create_obfuscation():
	"""
	Add the obfuscation layer above the tilemap.
	The set obfuscation_sprite will be drawn on top of each tile.
	"""
	var tween = Tween.new()
	for y in range(0, map_max_y - map_min_y + 1):
		var row = []
		for x in range(0, map_max_x - map_min_x + 1):
			var sprite = obfuscation_sprite.duplicate()
			sprite.global_position = map_to_world(_matrix_to_tilemap(Vector2(x, y)))
			add_child(sprite)
			row.append(sprite)
		obfuscation.append(row)

func _show_matrix():
	for row in matrix:
		print(row)

func _init_matrix():
	"""
	Build numerical representation matrix of the used tiles in tilemap.
	0: empty tile, 1: affecting visibility (wall), 2: visible tile
	Every tile id except -1 (empty) and the obfuscation_tile_id 
	in the tileset will affect visibility.
	Also used to clear the matrix, if visibility ranges have changed.
	"""
	var rec = get_used_rect()
	matrix = []
	for y in range(rec.size.y):
		var row = []
		for x in range(rec.size.x):
			var tile_loc = _matrix_to_tilemap(Vector2(x, y))
			var cell = get_cell(tile_loc.x, tile_loc.y)
			if cell == -1:
				cell = 0
			elif cell != obfuscation_tile_id:
				cell = 1 
			row.append(cell)
		matrix.append(row)

func _set_matrix_cells_visible(around: Vector2, radius_px: float):
	"""
	Set cells in matrix connected to around visible.
	TODO: will break if source is outside the tilemap corners.
	"""
	var queue = [around]
	var node
	while queue:
		node = queue.pop_front()
		if matrix[node.y][node.x] == 0:
			matrix[node.y][node.x] = 2
			for n in _get_neighbour_cells(node):
				var dist = (n - around) * cell_size
				if dist.length() <= radius_px:
					queue.append(n)

func _get_neighbour_cells(matrix_cell: Vector2):
	"""
	Returns an array holding the neighbours of the given cell in the matrix.
	"""
	var neigh = []
	for y in [0, 1, -1]:
		for x in [0, 1, -1]:
			if x == 0 and y == 0:
				continue
			var xm = x + matrix_cell.x
			var ym = y + matrix_cell.y
			# neighbour outside of matrix.
			if xm < 0 or ym < 0 or xm >= len(matrix[0]) or ym >= len(matrix):
				continue
			neigh.append(Vector2(xm, ym))
	return neigh

func _matrix_to_tilemap(cell: Vector2) -> Vector2:
	return Vector2(cell.x + map_min_x, cell.y + map_min_y)

func _tilemap_to_matrix(tile: Vector2) -> Vector2:
	return Vector2(tile.x - map_min_x, tile.y - map_min_y)

func _update_obfuscation(around: Vector2, radius_px: float):
	"""
	TODO: do or don't check/update over the whole matrix every time?
	TODO: time for interpolation is fixed, but current_alpha might not,
		  what will result in a wrong duration of the effect.
	"""
	for y in range(0, len(matrix)):
		for x in range(0, len(matrix[y])):
			var neighs = _get_neighbour_cells(Vector2(x, y))
			var types = []
			for n in neighs:
				types.append(matrix[n.y][n.x])
			var current_alpha = obfuscation[y][x].modulate.a
			# tile not (not more) visible
			if not 2 in types:
				# if tile was visible, obfuscate it.
				if current_alpha != 1.0:
					obfuscation_tween.interpolate_property(obfuscation[y][x], "modulate:a", current_alpha, 1.0, 0.5)
			# tile (got) visible
			elif current_alpha != 0.0:
				obfuscation_tween.interpolate_property(obfuscation[y][x], "modulate:a", current_alpha, 0.0, 0.5)
			obfuscation_tween.start()

func _get_visibility_radius(area: Area2D) -> float:
	var radius: float
	for child in area.get_children():
		if child.is_class("CollisionShape2D"):
			if child.shape.is_class("CircleShape2D"):
				radius = child.shape.radius
				break
	assert(radius > 0, "Shape of visibility Area2d needs to be a CircleShape2D with a radius > 0.")
	return radius

func add_update_visibility_range(area: Area2D):
	_init_matrix()
	var radius = _get_visibility_radius(area)
	var around = _tilemap_to_matrix(world_to_map(area.global_position))
	_set_matrix_cells_visible(around, radius)
	_update_obfuscation(around, radius)




