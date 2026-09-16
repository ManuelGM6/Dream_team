extends Node2D

const COLLISION_MASK_POZO = 8
const REFERENCE_TEXTURE_SIZE = Vector2(855, 1300)
const CARD_IMAGE_BASE_SCALE = Vector2(0.202781, 0.188791)

signal pozo_clickeado

var pila_descarte: Array = []

@onready var card_image = $CardImage
@onready var area = $Area2D

func _ready() -> void:
	card_image.visible = false
	area.collision_layer = COLLISION_MASK_POZO
	area.collision_mask = COLLISION_MASK_POZO

func discard_card_data(card_data: Dictionary) -> void:
	pila_descarte.append(card_data)
	_actualizar_visual()

func peek_top_card_data():
	if pila_descarte.is_empty():
		return null
	return pila_descarte[pila_descarte.size() - 1]

func draw_top_card_data() -> Dictionary:
	if pila_descarte.is_empty():
		return {}
	var data = pila_descarte.pop_back()
	_actualizar_visual()
	return data

func has_cards() -> bool:
	return not pila_descarte.is_empty()

func tomar_todo_menos_arriba() -> Array:
	if pila_descarte.size() <= 1:
		return []
	var arriba = pila_descarte.pop_back()
	var resto = pila_descarte.duplicate()
	pila_descarte = [arriba]
	_actualizar_visual()
	return resto

func _actualizar_visual() -> void:
	if pila_descarte.is_empty():
		card_image.visible = false
	else:
		card_image.visible = true
		var tex = _get_card_texture(pila_descarte[pila_descarte.size() - 1])
		card_image.texture = tex
		if tex:
			var tex_size = tex.get_size()
			card_image.scale = Vector2(
				CARD_IMAGE_BASE_SCALE.x * REFERENCE_TEXTURE_SIZE.x / tex_size.x,
				CARD_IMAGE_BASE_SCALE.y * REFERENCE_TEXTURE_SIZE.y / tex_size.y
			)

func _get_card_texture(card: Dictionary) -> Texture2D:
	var ruta = "res://Juego/imgs/Cards/%s/%s_%d.jpg" % [card.palo, card.palo, card.numero]
	return load(ruta)
