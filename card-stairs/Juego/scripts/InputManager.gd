extends Node2D

signal click_izquierdo_mouse
signal click_izquierdo_mouse_soltado

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_MAZO = 4
const COLLISION_MASK_POZO = 8

var card_manager_reference
var referencia_gestor_juego

func _ready() -> void:
	card_manager_reference = $"../CardManager"
	referencia_gestor_juego = $"../GameManager"

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			emit_signal("click_izquierdo_mouse")
			raycast_en_cursor()
		else:
			emit_signal("click_izquierdo_mouse_soltado")

func raycast_en_cursor():
	var estado_espacio = get_world_2d().direct_space_state
	var parametros = PhysicsPointQueryParameters2D.new()

	parametros.position = get_global_mouse_position()
	parametros.collide_with_areas = true
	var resultado = estado_espacio.intersect_point(parametros)

	if resultado.size() > 0:
		var mascara_colision_resultado = resultado[0].collider.collision_mask
		if mascara_colision_resultado == COLLISION_MASK_CARD:
			var card_found = resultado[0].collider.get_parent()
			if card_found:
				card_manager_reference.iniciar_arrastre(card_found)
		elif mascara_colision_resultado == COLLISION_MASK_MAZO:
			referencia_gestor_juego.al_click_mazo()
		elif mascara_colision_resultado == COLLISION_MASK_POZO:
			referencia_gestor_juego.al_click_pozo()
