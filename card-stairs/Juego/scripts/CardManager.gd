extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_POZO = 8
const DEFAULT_CARD_MOVE_SPEED = 0.1

const DEFAULT_SCALE = Vector2(2.43, 2.43)
const HOVER_SCALE = Vector2(2.80, 2.80)
const DRAG_SCALE = Vector2(2.50, 3)
const HOVER_LIFT = 45.0
const HOVER_SPEED = 0.12

var tamano_pantalla
var card_being_dragged
var currently_hovered_card = null
var referencia_mano_jugador
@onready var audio_juego = $"../Juego_Musica"
@onready var audio_tomar_dejar = $"../Audio_TomarDejarCartas"
@onready var gestor_juego = $"../GameManager"

func _ready() -> void:
	audio_juego.play()
	tamano_pantalla = get_viewport_rect().size
	referencia_mano_jugador = $"../PlayerHand"
	$"../InputManager".connect("click_izquierdo_mouse_soltado", al_soltar_click_izquierdo)

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if card_being_dragged:
		var posicion_mouse = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(posicion_mouse.x, 0, tamano_pantalla.x),
			clamp(posicion_mouse.y, 0, tamano_pantalla.y))

func iniciar_arrastre(card):
	if gestor_juego and gestor_juego.en_fase_encaje():
		gestor_juego.al_click_carta_encaje(card)
		return
	if gestor_juego and not gestor_juego.puede_jugador_interactuar_mano():
		return
	card_being_dragged = card
	card.z_index = 200
	audio_tomar_dejar.play()
	card.animar_a({"scale": DRAG_SCALE, "rotation_degrees": 0}, 0.1)
	if card.ranura_actual:
		card.ranura_actual.remove_card()

func terminar_arrastre():
	var card = card_being_dragged
	card_being_dragged = null
	card.scale = DEFAULT_SCALE
	audio_tomar_dejar.play()

	var soltada_en_pozo = raycast_verificar_pozo()
	if soltada_en_pozo and gestor_juego and gestor_juego.intentar_descarte_jugador(card):
		return

	card.z_index = card.indice_z_base
	referencia_mano_jugador.add_card_to_hand(card, DEFAULT_CARD_MOVE_SPEED)

func cancelar_arrastre() -> void:
	if not card_being_dragged:
		return
	var card = card_being_dragged
	card_being_dragged = null
	card.z_index = card.indice_z_base
	card.scale = DEFAULT_SCALE
	referencia_mano_jugador.add_card_to_hand(card, DEFAULT_CARD_MOVE_SPEED)

func olvidar_carta(card) -> void:
	if card_being_dragged == card:
		card_being_dragged = null
	if currently_hovered_card == card:
		currently_hovered_card = null

func connect_card_signals(card):
	card.connect("resaltada", on_hovered_over_card)
	card.connect("resaltada_fin", on_hovered_off_card)

func al_soltar_click_izquierdo():
	if card_being_dragged:
		terminar_arrastre()

func on_hovered_over_card(card):
	if card_being_dragged:
		return
	if currently_hovered_card == card:
		return
	if currently_hovered_card:
		highlight_card(currently_hovered_card, false)
	currently_hovered_card = card
	highlight_card(card, true)

func on_hovered_off_card(card):
	if card_being_dragged:
		return
	if currently_hovered_card != card:
		return
	highlight_card(card, false)
	currently_hovered_card = null
	var new_card_hovered = raycast_check_for_card()
	if new_card_hovered:
		currently_hovered_card = new_card_hovered
		highlight_card(new_card_hovered, true)

func highlight_card(card, hovered):
	if hovered:
		card.z_index = card.indice_z_base + 100
		card.animar_a({
			"scale": HOVER_SCALE,
			"position": card.posicion_inicial + Vector2(0, -HOVER_LIFT)
		}, HOVER_SPEED)
	else:
		card.z_index = card.indice_z_base
		card.animar_a({
			"scale": DEFAULT_SCALE,
			"position": card.posicion_inicial
		}, HOVER_SPEED)

func raycast_check_for_card():
	var estado_espacio = get_world_2d().direct_space_state

	var parametros = PhysicsPointQueryParameters2D.new()
	parametros.position = get_global_mouse_position()
	parametros.collide_with_areas = true
	parametros.collision_mask = COLLISION_MASK_CARD

	var resultado = estado_espacio.intersect_point(parametros)

	if resultado.size() > 0:
		return get_card_with_highest_z_index(resultado)
	return null

func raycast_verificar_pozo() -> bool:
	var estado_espacio = get_world_2d().direct_space_state

	var parametros = PhysicsPointQueryParameters2D.new()
	parametros.position = get_global_mouse_position()
	parametros.collide_with_areas = true
	parametros.collision_mask = COLLISION_MASK_POZO

	var resultado = estado_espacio.intersect_point(parametros)
	return resultado.size() > 0

func get_card_with_highest_z_index(cards):
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index

	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card
