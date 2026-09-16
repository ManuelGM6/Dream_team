extends Node2D

const CARD_SCENE_PATH = "res://Juego/escenas/Card.tscn"
const POSICION_Y_CARTAS = 55.0
const ESPACIADO_X = 40.0
const ESCALA_CARTA_OCULTA = Vector2(1.0, 1.0)

var mano: Array = []
var nodos_visuales: Array = []

@onready var etiqueta = $CardCountLabel
@onready var mazo_referencia = $"../Deck"

func add_card(card_data: Dictionary) -> void:
	mano.append(card_data)
	_crear_card_visual(card_data)
	_actualizar_visual()

func remove_card(card_data: Dictionary) -> void:
	for i in range(mano.size()):
		if ChinchonReglas.cards_equal(mano[i], card_data):
			mano.remove_at(i)
			if i < nodos_visuales.size():
				nodos_visuales[i].queue_free()
				nodos_visuales.remove_at(i)
			break
	_actualizar_visual()
	_reordenar_visuales()

func card_count() -> int:
	return mano.size()

func connect_card_signals(_card) -> void:
	pass

# Da vuelta las cartas del bot para que se vean boca arriba (fin de ronda).
func revelar_mano() -> void:
	for nodo in nodos_visuales:
		nodo.get_node("AnimationPlayer").play("card_flip")

func limpiar_mano() -> void:
	for nodo in nodos_visuales:
		nodo.queue_free()
	nodos_visuales.clear()
	mano.clear()
	_actualizar_visual()

func _crear_card_visual(card_data: Dictionary) -> void:
	var escena = preload(CARD_SCENE_PATH)
	var nodo = escena.instantiate()
	add_child(nodo)
	nodo.set_card_data(card_data)
	nodo.establecer_textura_frente(mazo_referencia.get_card_texture(card_data))
	nodo.get_node("Area2D/CollisionShape2D").disabled = true
	nodos_visuales.append(nodo)
	_reordenar_visuales()

func _reordenar_visuales() -> void:
	var offset_inicial = -ESPACIADO_X * (nodos_visuales.size() - 1) / 2.0
	for i in range(nodos_visuales.size()):
		var nodo = nodos_visuales[i]
		nodo.scale = ESCALA_CARTA_OCULTA
		nodo.position = Vector2(offset_inicial + i * ESPACIADO_X, POSICION_Y_CARTAS)
		nodo.z_index = i

func _actualizar_visual() -> void:
	if etiqueta:
		etiqueta.text = "Bot: %d cartas" % mano.size()
