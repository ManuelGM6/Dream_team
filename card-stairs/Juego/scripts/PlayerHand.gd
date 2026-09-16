extends Node2D

const POSICION_Y_MANO = 775
const DEFAULT_CARD_MOVE_SPEED = 0.1
const PASO_ANGULO_ABANICO = 5.0
const RADIO_ABANICO = 1500.0
const ORDEN_PALO = {"oros": 0, "copas": 1, "espadas": 2, "bastos": 3, "mundial": 4}

var mano = []
var centro_pantalla_x

@onready var boton_ordenar_valor = $"../BotonOrdenarValor"
@onready var boton_ordenar_palo = $"../BotonOrdenarPalo"

func _ready() -> void:
	centro_pantalla_x = get_viewport().size.x / 2
	boton_ordenar_valor.pressed.connect(ordenar_por_valor_desc)
	boton_ordenar_palo.pressed.connect(ordenar_por_palo)

func ordenar_por_valor_desc() -> void:
	mano.sort_custom(func(a, b): return a.card_data.numero > b.card_data.numero)
	actualizar_posiciones_mano(DEFAULT_CARD_MOVE_SPEED)

func ordenar_por_palo() -> void:
	mano.sort_custom(func(a, b):
		var pa = ORDEN_PALO.get(a.card_data.palo, 99)
		var pb = ORDEN_PALO.get(b.card_data.palo, 99)
		if pa == pb:
			return a.card_data.numero < b.card_data.numero
		return pa < pb
	)
	actualizar_posiciones_mano(DEFAULT_CARD_MOVE_SPEED)

func add_card_to_hand(card, speed):
	if card not in mano:
		mano.insert(0, card)
		actualizar_posiciones_mano(speed)
	else:
		card.animar_a({
			"position": card.posicion_inicial,
			"rotation_degrees": card.rotacion_inicial
		}, DEFAULT_CARD_MOVE_SPEED)

func actualizar_posiciones_mano(speed):
	for i in range(mano.size()):
		var transformacion_abanico = calcular_transformacion_abanico(i)
		var card = mano[i]
		card.posicion_inicial = transformacion_abanico.position
		card.rotacion_inicial = transformacion_abanico.rotation
		card.indice_z_base = i
		card.z_index = i
		card.animar_a({
			"position": transformacion_abanico.position,
			"rotation_degrees": transformacion_abanico.rotation
		}, speed)

func calcular_transformacion_abanico(index) -> Dictionary:
	var indice_central = (mano.size() - 1) / 2.0
	var angulo_grados = (index - indice_central) * PASO_ANGULO_ABANICO
	var angulo_rad = deg_to_rad(angulo_grados)
	var x = centro_pantalla_x + sin(angulo_rad) * RADIO_ABANICO
	var y = POSICION_Y_MANO + RADIO_ABANICO * (1 - cos(angulo_rad))
	return {"position": Vector2(x, y), "rotation": angulo_grados}

func remove_card_from_hand(card):
	if card in mano:
		mano.erase(card)
		actualizar_posiciones_mano(DEFAULT_CARD_MOVE_SPEED)
