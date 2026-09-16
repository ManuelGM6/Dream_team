extends Node2D

enum Fase { ROBO, DESCARTE, TERMINADO }
enum Turno { JUGADOR, BOT }

var fase = Fase.ROBO
var turno = Turno.JUGADOR

const CARD_SCENE_PATH = "res://Juego/escenas/Card.tscn"

@onready var mazo = $"../Deck"
@onready var pozo = $"../Pozo"
@onready var mano_jugador = $"../PlayerHand"
@onready var mano_bot = $"../BotHand"
@onready var bot = $"../Bot"
@onready var etiqueta_estado = $"../EstadoLabel"
@onready var boton_cortar = $"../BotonCortar"
@onready var panel_puntajes = $"../PanelPuntajes"
@onready var etiqueta_resultado = $"../PanelPuntajes/ResultadoLabel"
@onready var etiqueta_puntajes = $"../PanelPuntajes/PuntajesLabel"
@onready var boton_siguiente_ronda = $"../PanelPuntajes/BotonSiguienteRonda"

func _ready() -> void:
	boton_cortar.pressed.connect(intentar_cierre_jugador)
	boton_siguiente_ronda.pressed.connect(_iniciar_nueva_ronda)
	call_deferred("_iniciar_partida")

func _iniciar_partida() -> void:
	for i in range(7):
		mazo.robar_visual_a_mano(mano_jugador)
	for i in range(7):
		var datos = mazo.draw_card_data()
		if not datos.is_empty():
			mano_bot.add_card(datos)
	turno = Turno.JUGADOR
	fase = Fase.ROBO
	_refrescar_ui()

func puede_jugador_interactuar_mano() -> bool:
	return turno == Turno.JUGADOR and fase != Fase.TERMINADO

func al_click_mazo() -> void:
	if turno != Turno.JUGADOR or fase != Fase.ROBO:
		return
	var card_node = mazo.robar_visual_a_mano(mano_jugador)
	if card_node:
		fase = Fase.DESCARTE
		_refrescar_ui()

func al_click_pozo() -> void:
	if turno != Turno.JUGADOR or fase != Fase.ROBO:
		return
	if not pozo.has_cards():
		return
	var datos = pozo.draw_top_card_data()
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	new_card.set_card_data(datos)
	new_card.establecer_textura_frente(mazo.get_card_texture(datos))
	$"../CardManager".add_child(new_card)
	mano_jugador.add_card_to_hand(new_card, 0.2)
	new_card.get_node("AnimationPlayer").play("card_flip")
	fase = Fase.DESCARTE
	_refrescar_ui()

func intentar_descarte_jugador(card_node: Node2D) -> bool:
	if turno != Turno.JUGADOR or fase != Fase.DESCARTE:
		return false
	mano_jugador.remove_card_from_hand(card_node)
	pozo.discard_card_data(card_node.card_data)
	card_node.queue_free()
	fase = Fase.ROBO
	turno = Turno.BOT
	_refrescar_ui()
	call_deferred("_iniciar_turno_bot")
	return true

func intentar_cierre_jugador() -> void:
	if turno != Turno.JUGADOR or fase != Fase.DESCARTE:
		return
	var datos_mano = _datos_de_mano(mano_jugador)
	var opciones = ChinchonReglas.evaluar_opciones_cierre(datos_mano)
	if opciones.is_empty():
		return
	var elegida = _preferir_limpio(opciones)
	var card_node = _find_card_node_by_data(mano_jugador, elegida.discard)
	if not card_node:
		return
	mano_jugador.remove_card_from_hand(card_node)
	card_node.queue_free()
	fase = Fase.TERMINADO
	_terminar_ronda("jugador", elegida)

func _iniciar_turno_bot() -> void:
	if fase == Fase.TERMINADO:
		return
	bot.jugar_turno()

func terminar_descarte_bot(card_data: Dictionary) -> void:
	pozo.discard_card_data(card_data)
	fase = Fase.ROBO
	turno = Turno.JUGADOR
	_refrescar_ui()

func terminar_cierre_bot(info_cierre: Dictionary) -> void:
	fase = Fase.TERMINADO
	_terminar_ronda("bot", info_cierre)

func _datos_de_mano(nodo_mano) -> Array:
	var datos = []
	for card_node in nodo_mano.mano:
		datos.append(card_node.card_data)
	return datos

func _find_card_node_by_data(nodo_mano, card_data: Dictionary) -> Node2D:
	for card_node in nodo_mano.mano:
		if ChinchonReglas.cards_equal(card_node.card_data, card_data):
			return card_node
	return null

func _preferir_limpio(opciones: Array) -> Dictionary:
	for opcion in opciones:
		if opcion.type == "limpio":
			return opcion
	return opciones[0]

func _terminar_ronda(ganador: String, info_cierre: Dictionary) -> void:
	boton_cortar.visible = false
	mano_bot.revelar_mano()

	if ChinchonReglas.es_cierre_chinchon(info_cierre):
		_mostrar_chinchon(ganador)
		return

	var datos_mano_perdedor: Array
	if ganador == "jugador":
		datos_mano_perdedor = mano_bot.mano
	else:
		datos_mano_perdedor = _datos_de_mano(mano_jugador)
	var puntos_sueltos = ChinchonReglas.puntos_sueltos(datos_mano_perdedor)

	if ganador == "jugador":
		if info_cierre.type == "limpio":
			GameState.puntaje_jugador -= 10
		GameState.puntaje_bot += puntos_sueltos
	else:
		if info_cierre.type == "limpio":
			GameState.puntaje_bot -= 10
		GameState.puntaje_jugador += puntos_sueltos

	var quien = GameState.nombre_jugador if ganador == "jugador" else "El bot"
	etiqueta_resultado.text = "%s cortó (%s)" % [quien, info_cierre.type]
	_refrescar_etiqueta_puntajes()
	panel_puntajes.visible = true

func _mostrar_chinchon(ganador: String) -> void:
	var quien = GameState.nombre_jugador if ganador == "jugador" else "El bot"
	etiqueta_resultado.text = "¡Chinchón verdadero de %s! Gana la partida." % quien
	etiqueta_puntajes.text = ""
	panel_puntajes.visible = true
	GameState.reiniciar_puntajes()

func _refrescar_etiqueta_puntajes() -> void:
	etiqueta_puntajes.text = "%s: %d puntos\nBot: %d puntos" % [
		GameState.nombre_jugador,
		GameState.puntaje_jugador,
		GameState.puntaje_bot
	]

func _iniciar_nueva_ronda() -> void:
	panel_puntajes.visible = false
	for card in mano_jugador.mano.duplicate():
		card.queue_free()
		
	mano_jugador.mano.clear()
	mano_bot.limpiar_mano()
	pozo.pila_descarte.clear()

func _refrescar_ui() -> void:
	if fase == Fase.TERMINADO:
		return
	if turno == Turno.JUGADOR:
		if fase == Fase.ROBO:
			etiqueta_estado.text = "Tu turno: robá del mazo o del pozo"
		else:
			etiqueta_estado.text = "Tu turno: descartá una carta (arrastrala al pozo)"
	else:
		etiqueta_estado.text = "Turno del bot..."

	var datos_mano = _datos_de_mano(mano_jugador)
	if turno == Turno.JUGADOR and fase == Fase.DESCARTE:
		boton_cortar.visible = ChinchonReglas.puede_cerrar(datos_mano)
	else:
		boton_cortar.visible = false
