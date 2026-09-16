extends Node2D

const CARD_SCENE_PATH = "res://Juego/escenas/Card.tscn"
const CARD_DRAW_SPEED = 0.2

var mazo = []
var card_database_reference

@onready var audio_mezclar = $"../Audio_MezclarCartas"
@onready var pozo = $"../Pozo"

func _ready() -> void:
	card_database_reference = preload("res://Juego/scripts/CardDatabase.gd")
	crear_mazo()

func crear_mazo() -> void:
	mazo.clear()
	for palo in card_database_reference.CARDS.keys():
		for numero in card_database_reference.CARDS[palo]:
			mazo.append({"palo": palo, "numero": numero})
	mazo.shuffle()
	audio_mezclar.play()
	_actualizar_etiqueta()

func draw_card_data() -> Dictionary:
	if mazo.is_empty():
		_rebarajar_desde_pozo()
	if mazo.is_empty():
		return {}
	var card = mazo.pop_front()
	_actualizar_visibilidad()
	_actualizar_etiqueta()
	return card

func _rebarajar_desde_pozo() -> void:
	var reciclado = pozo.tomar_todo_menos_arriba()
	if reciclado.is_empty():
		return
	mazo = reciclado
	mazo.shuffle()

func robar_visual_a_mano(target_hand) -> Node2D:
	var data = draw_card_data()
	if data.is_empty():
		return null
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	new_card.set_card_data(data)
	new_card.establecer_textura_frente(get_card_texture(data))
	$"../CardManager".add_child(new_card)
	target_hand.add_card_to_hand(new_card, CARD_DRAW_SPEED)
	new_card.get_node("AnimationPlayer").play("card_flip")
	return new_card

func _actualizar_visibilidad() -> void:
	if mazo.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$Mazo.visible = false
	else:
		$Area2D/CollisionShape2D.disabled = false
		$Mazo.visible = true

func _actualizar_etiqueta() -> void:
	$RichTextLabel.text = str(mazo.size())

func get_card_texture(card: Dictionary) -> Texture2D:
	var ruta = "res://Juego/imgs/Cards/%s/%s_%d.jpg" % [
		card.palo,
		card.palo,
		card.numero
	]
	return load(ruta)
