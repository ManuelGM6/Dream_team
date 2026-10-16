extends Node2D

enum Fase { ROBO, DESCARTE, ENCAJE, TERMINADO }
enum Turno { JUGADOR, BOT }

var fase = Fase.ROBO
var turno = Turno.JUGADOR
var temp_jugador
var temp_bot

const CARD_SCENE_PATH = "res://Juego/escenas/Card.tscn"
const TIEMPO_TURNO_JUGADOR := 30.0
const TIEMPO_AVISO := 10.0
const PAUSA_AUTO_DESCARTE := 0.8
const PAUSA_ENCAJE_BOT := 1.0
const ANCHO_CARTA_COMBINACION := 90.0
const ALTO_CARTA_COMBINACION := 137.0
const SEPARACION_CARTAS_COMBINACION := 42.0
const SEPARACION_FILAS_COMBINACION := 170.0

var tiempo_restante := TIEMPO_TURNO_JUGADOR
var temporizador_activo := false
var etiqueta_temporizador: Label
var etiqueta_bot: Label
var etiqueta_combinaciones: Label
var nodo_combinaciones: Node2D
var boton_terminar_encaje: Button
var boton_salir: Button
var capa_salir: CanvasLayer
var raiz_salir: Control
var panel_salir: Panel
var sonido_boton: AudioStreamPlayer
var salida_abierta := false
var etiqueta_estadisticas: Label

var ganador_ronda := ""
var info_cierre_actual: Dictionary = {}
var combinaciones_cortador: Array = []
var cartas_encajadas := 0
var turnos_jugados_jugador := 0
var turnos_jugados_bot := 0

@onready var mazo = $"../Deck"
@onready var pozo = $"../Pozo"
@onready var mano_jugador = $"../PlayerHand"
@onready var mano_bot = $"../BotHand"
@onready var bot = $"../Bot"
@onready var card_manager = $"../CardManager"
@onready var etiqueta_estado = $"../EstadoLabel"
@onready var boton_cortar = $"../BotonCortar"
@onready var panel_puntajes = $"../PanelPuntajes"
@onready var etiqueta_resultado = $"../PanelPuntajes/ResultadoLabel"
@onready var etiqueta_puntajes = $"../PanelPuntajes/PuntajesLabel"
@onready var boton_siguiente_ronda = $"../PanelPuntajes/BotonSiguienteRonda"

func _ready() -> void:
	_crear_etiquetas_extra()
	boton_cortar.pressed.connect(intentar_cierre_jugador)
	boton_siguiente_ronda.pressed.connect(_iniciar_nueva_ronda)
	call_deferred("_iniciar_partida")

func _crear_etiquetas_extra() -> void:
	etiqueta_temporizador = Label.new()
	etiqueta_temporizador.position = Vector2(1400, 20)
	etiqueta_temporizador.size = Vector2(480, 50)
	etiqueta_temporizador.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	etiqueta_temporizador.add_theme_font_size_override("font_size", 40)
	etiqueta_temporizador.z_index = 300
	etiqueta_temporizador.visible = false
	add_child(etiqueta_temporizador)

	etiqueta_bot = Label.new()
	etiqueta_bot.position = Vector2(40, 20)
	etiqueta_bot.size = Vector2(620, 50)
	etiqueta_bot.add_theme_font_size_override("font_size", 32)
	etiqueta_bot.z_index = 300
	add_child(etiqueta_bot)

	etiqueta_combinaciones = Label.new()
	etiqueta_combinaciones.position = Vector2(60, 215)
	etiqueta_combinaciones.size = Vector2(600, 40)
	etiqueta_combinaciones.add_theme_font_size_override("font_size", 26)
	etiqueta_combinaciones.z_index = 10
	add_child(etiqueta_combinaciones)

	nodo_combinaciones = Node2D.new()
	nodo_combinaciones.position = Vector2(110, 330)
	nodo_combinaciones.z_index = 10
	add_child(nodo_combinaciones)

	boton_terminar_encaje = Button.new()
	boton_terminar_encaje.text = "Listo, sumar puntos"
	boton_terminar_encaje.position = Vector2(1620, 850)
	boton_terminar_encaje.size = Vector2(260, 50)
	boton_terminar_encaje.z_index = 300
	boton_terminar_encaje.visible = false
	boton_terminar_encaje.pressed.connect(_finalizar_encaje)
	add_child(boton_terminar_encaje)

	boton_salir = Button.new()
	boton_salir.text = "Salir"
	boton_salir.position = Vector2(1780, 20)
	boton_salir.size = Vector2(120, 44)
	boton_salir.z_index = 300
	boton_salir.pressed.connect(_pedir_confirmacion_salir)
	add_child(boton_salir)

	_crear_dialogo_salir()

	etiqueta_estadisticas = Label.new()
	etiqueta_estadisticas.position = Vector2(40, 1010)
	etiqueta_estadisticas.size = Vector2(900, 40)
	etiqueta_estadisticas.add_theme_font_size_override("font_size", 26)
	etiqueta_estadisticas.z_index = 10
	add_child(etiqueta_estadisticas)
	_actualizar_etiqueta_estadisticas()

func anunciar_accion_bot(texto: String) -> void:
	etiqueta_bot.text = texto

func _process(delta: float) -> void:
	if not temporizador_activo or salida_abierta:
		return
	tiempo_restante -= delta
	_actualizar_etiqueta_temporizador()
	if tiempo_restante <= 0.0:
		temporizador_activo = false
		_tiempo_agotado()

func _reiniciar_temporizador() -> void:
	tiempo_restante = TIEMPO_TURNO_JUGADOR
	temporizador_activo = true
	etiqueta_temporizador.visible = true
	_actualizar_etiqueta_temporizador()

func _detener_temporizador() -> void:
	temporizador_activo = false
	etiqueta_temporizador.visible = false

func _actualizar_etiqueta_temporizador() -> void:
	etiqueta_temporizador.text = "Tiempo: %d" % ceili(maxf(tiempo_restante, 0.0))
	var color = Color(1.0, 0.3, 0.3) if tiempo_restante <= TIEMPO_AVISO else Color(1.0, 1.0, 1.0)
	etiqueta_temporizador.add_theme_color_override("font_color", color)

func _tiempo_agotado() -> void:
	if turno != Turno.JUGADOR or fase == Fase.TERMINADO:
		return
	card_manager.cancelar_arrastre()
	if fase == Fase.ROBO:
		var card_node = mazo.robar_visual_a_mano(mano_jugador)
		if not card_node:
			_reiniciar_temporizador()
			return
		fase = Fase.DESCARTE
		_refrescar_ui()
		await get_tree().create_timer(PAUSA_AUTO_DESCARTE).timeout
		if turno != Turno.JUGADOR or fase != Fase.DESCARTE:
			return
	if mano_jugador.mano.is_empty():
		return
	var elegida = mano_jugador.mano[randi() % mano_jugador.mano.size()]
	card_manager.olvidar_carta(elegida)
	intentar_descarte_jugador(elegida)

func _iniciar_partida() -> void:
	turnos_jugados_jugador = 0
	turnos_jugados_bot = 0
	for i in range(ChinchonReglas.TAMANO_MANO):
		mazo.robar_visual_a_mano(mano_jugador)
	for i in range(ChinchonReglas.TAMANO_MANO):
		var datos = mazo.draw_card_data()
		if not datos.is_empty():
			mano_bot.add_card(datos)
	var carta_inicial = mazo.draw_card_data()
	if not carta_inicial.is_empty():
		pozo.discard_card_data(carta_inicial)
	turno = Turno.JUGADOR
	fase = Fase.ROBO
	_refrescar_ui()
	_reiniciar_temporizador()

func puede_jugador_interactuar_mano() -> bool:
	return turno == Turno.JUGADOR and fase != Fase.TERMINADO and fase != Fase.ENCAJE

func _crear_dialogo_salir() -> void:
	var fuente = load("res://fonts/Sancreek-Regular.ttf")

	sonido_boton = AudioStreamPlayer.new()
	sonido_boton.stream = load("res://sound/btn_sound.wav")
	add_child(sonido_boton)

	capa_salir = CanvasLayer.new()
	capa_salir.layer = 100
	capa_salir.visible = false
	add_child(capa_salir)

	raiz_salir = Control.new()
	raiz_salir.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa_salir.add_child(raiz_salir)

	var oscuro = ColorRect.new()
	oscuro.color = Color(0.012, 0.012, 0.012, 0.7)
	oscuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	oscuro.mouse_filter = Control.MOUSE_FILTER_STOP
	raiz_salir.add_child(oscuro)

	panel_salir = Panel.new()
	panel_salir.size = Vector2(640, 508)
	raiz_salir.add_child(panel_salir)

	var fondo = Sprite2D.new()
	fondo.texture = load("res://Menu/imgs/fondo.png")
	fondo.position = Vector2(319, 257)
	fondo.scale = Vector2(0.623, 0.9195)
	panel_salir.add_child(fondo)

	var pregunta = Label.new()
	pregunta.text = "Estas seguro que quieres salir?"
	pregunta.position = Vector2(1, 100)
	pregunta.size = Vector2(637, 86)
	pregunta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pregunta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pregunta.add_theme_font_override("font", fuente)
	pregunta.add_theme_font_size_override("font_size", 40)
	pregunta.add_theme_constant_override("outline_size", 9)
	panel_salir.add_child(pregunta)

	var boton_si = Button.new()
	boton_si.text = "Si"
	boton_si.flat = true
	boton_si.position = Vector2(384, 220)
	boton_si.size = Vector2(128, 128)
	boton_si.add_theme_font_override("font", fuente)
	boton_si.add_theme_font_size_override("font_size", 80)
	boton_si.add_theme_constant_override("outline_size", 9)
	boton_si.pressed.connect(_volver_al_menu)
	panel_salir.add_child(boton_si)

	var boton_no = Button.new()
	boton_no.text = "No"
	boton_no.flat = true
	boton_no.position = Vector2(120, 224)
	boton_no.size = Vector2(136, 126)
	boton_no.add_theme_font_override("font", fuente)
	boton_no.add_theme_font_size_override("font_size", 80)
	boton_no.add_theme_constant_override("outline_size", 9)
	boton_no.pressed.connect(_cancelar_salida)
	panel_salir.add_child(boton_no)

func _pedir_confirmacion_salir() -> void:
	if salida_abierta:
		return
	salida_abierta = true
	sonido_boton.play()
	panel_salir.position = (get_viewport_rect().size - panel_salir.size) / 2.0
	raiz_salir.modulate.a = 0.0
	capa_salir.visible = true
	create_tween().tween_property(raiz_salir, "modulate:a", 1.0, 0.3)

func _cancelar_salida() -> void:
	sonido_boton.play()
	salida_abierta = false
	var interpolador = create_tween()
	interpolador.tween_property(raiz_salir, "modulate:a", 0.0, 0.3)
	interpolador.tween_callback(_ocultar_salida)

func _ocultar_salida() -> void:
	if not salida_abierta:
		capa_salir.visible = false

func _actualizar_etiqueta_estadisticas() -> void:
	var e = GameState.obtener_estadisticas()
	etiqueta_estadisticas.text = "%s - Ganadas: %d | Perdidas: %d | Victorias: %.1f%%" % [
		GameState.nombre_jugador, e.victorias, e.derrotas, e.porcentaje_victoria
	]

func _volver_al_menu() -> void:
	GameState.reiniciar_puntajes()
	get_tree().change_scene_to_file("res://Menu/start_game.tscn")

func jugador_puede_cortar() -> bool:
	return turnos_jugados_jugador >= 1

func bot_puede_cortar() -> bool:
	return turnos_jugados_bot >= 1

func en_fase_encaje() -> bool:
	return fase == Fase.ENCAJE

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
	_detener_temporizador()
	mano_jugador.remove_card_from_hand(card_node)
	pozo.discard_card_data(card_node.card_data)
	card_node.queue_free()
	turnos_jugados_jugador += 1
	fase = Fase.ROBO
	turno = Turno.BOT
	_refrescar_ui()
	call_deferred("_iniciar_turno_bot")
	return true

func intentar_cierre_jugador() -> void:
	if turno != Turno.JUGADOR or fase != Fase.DESCARTE or not jugador_puede_cortar():
		return
	var datos_mano = _datos_de_mano(mano_jugador)
	var opciones = ChinchonReglas.evaluar_opciones_cierre(datos_mano)
	if opciones.is_empty():
		return
	var elegida = ChinchonReglas.elegir_mejor_opcion(opciones)
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
	turnos_jugados_bot += 1
	fase = Fase.ROBO
	turno = Turno.JUGADOR
	_refrescar_ui()
	_reiniciar_temporizador()

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

func _terminar_ronda(ganador: String, info_cierre: Dictionary) -> void:
	_detener_temporizador()
	boton_cortar.visible = false
	mano_bot.revelar_mano()

	if ChinchonReglas.es_cierre_chinchon(info_cierre):
		_mostrar_chinchon(ganador)
		return

	ganador_ronda = ganador
	info_cierre_actual = info_cierre
	cartas_encajadas = 0
	combinaciones_cortador = _copiar_combinaciones(info_cierre.get("melds", []))
	_dibujar_combinaciones()
	_iniciar_encaje()

func _copiar_combinaciones(combinaciones: Array) -> Array:
	var copia: Array = []
	for combinacion in combinaciones:
		copia.append(combinacion.duplicate())
	return copia

func _nombre_carta(datos: Dictionary) -> String:
	return "%d de %s" % [datos.numero, datos.palo]

func _dibujar_combinaciones() -> void:
	for hijo in nodo_combinaciones.get_children():
		hijo.queue_free()
	for fila in range(combinaciones_cortador.size()):
		var combinacion: Array = combinaciones_cortador[fila]
		for columna in range(combinacion.size()):
			var sprite = Sprite2D.new()
			var tex = mazo.get_card_texture(combinacion[columna])
			sprite.texture = tex
			if tex:
				var tamano = tex.get_size()
				sprite.scale = Vector2(ANCHO_CARTA_COMBINACION / tamano.x, ALTO_CARTA_COMBINACION / tamano.y)
			sprite.position = Vector2(columna * SEPARACION_CARTAS_COMBINACION, fila * SEPARACION_FILAS_COMBINACION)
			sprite.z_index = columna
			nodo_combinaciones.add_child(sprite)

func _limpiar_combinaciones() -> void:
	combinaciones_cortador.clear()
	_dibujar_combinaciones()
	etiqueta_combinaciones.text = ""

func _iniciar_encaje() -> void:
	fase = Fase.ENCAJE
	etiqueta_combinaciones.text = "Juego del bot" if ganador_ronda == "bot" else "Tu juego"
	if ganador_ronda == "bot":
		if not _jugador_puede_encajar():
			_finalizar_encaje()
			return
		etiqueta_estado.text = "El bot cortó: hacé clic en una carta tuya para meterla en su juego"
		boton_terminar_encaje.visible = true
	else:
		etiqueta_estado.text = "Cortaste: el bot intenta meter cartas en tu juego..."
		await _encaje_automatico_bot()
		_finalizar_encaje()

func _jugador_puede_encajar() -> bool:
	for card_node in mano_jugador.mano:
		if ChinchonReglas.indice_combinacion_para(card_node.card_data, combinaciones_cortador) != -1:
			return true
	return false

func al_click_carta_encaje(card_node: Node2D) -> void:
	if fase != Fase.ENCAJE or ganador_ronda != "bot":
		return
	var indice = ChinchonReglas.indice_combinacion_para(card_node.card_data, combinaciones_cortador)
	if indice == -1:
		etiqueta_estado.text = "El %s no encaja en el juego del bot" % _nombre_carta(card_node.card_data)
		return
	var datos = card_node.card_data
	card_manager.olvidar_carta(card_node)
	mano_jugador.remove_card_from_hand(card_node)
	card_node.queue_free()
	combinaciones_cortador[indice].append(datos)
	ChinchonReglas.ordenar_combinacion(combinaciones_cortador[indice])
	cartas_encajadas += 1
	_dibujar_combinaciones()
	if _jugador_puede_encajar():
		etiqueta_estado.text = "Metiste el %s. Podés meter más o tocar \"Listo\"" % _nombre_carta(datos)
	else:
		_finalizar_encaje()

func _quitar_de_array(cartas: Array, carta: Dictionary) -> void:
	for i in range(cartas.size()):
		if ChinchonReglas.cards_equal(cartas[i], carta):
			cartas.remove_at(i)
			return

func _mejor_encaje_bot() -> Dictionary:
	var mano = mano_bot.mano
	var mejores_puntos = ChinchonReglas.puntos_sueltos(mano)
	var mejor := {}
	for carta in mano:
		var indice = ChinchonReglas.indice_combinacion_para(carta, combinaciones_cortador)
		if indice == -1:
			continue
		var restantes = mano.duplicate()
		_quitar_de_array(restantes, carta)
		var puntos = ChinchonReglas.puntos_sueltos(restantes)
		if puntos < mejores_puntos:
			mejores_puntos = puntos
			mejor = {"carta": carta, "indice": indice}
	return mejor

func _encaje_automatico_bot() -> void:
	await get_tree().create_timer(PAUSA_ENCAJE_BOT).timeout
	while fase == Fase.ENCAJE:
		var elegido = _mejor_encaje_bot()
		if elegido.is_empty():
			break
		var carta: Dictionary = elegido.carta
		mano_bot.remove_card(carta)
		combinaciones_cortador[elegido.indice].append(carta)
		ChinchonReglas.ordenar_combinacion(combinaciones_cortador[elegido.indice])
		cartas_encajadas += 1
		_dibujar_combinaciones()
		anunciar_accion_bot("El bot metió el %s en tu juego" % _nombre_carta(carta))
		await get_tree().create_timer(PAUSA_ENCAJE_BOT).timeout

func _finalizar_encaje() -> void:
	if fase != Fase.ENCAJE:
		return
	boton_terminar_encaje.visible = false
	fase = Fase.TERMINADO
	_calcular_y_mostrar_puntajes()

func _calcular_y_mostrar_puntajes() -> void:
	var ganador = ganador_ronda
	var info_cierre = info_cierre_actual
	var datos_mano_perdedor: Array
	if ganador == "jugador":
		datos_mano_perdedor = mano_bot.mano
	else:
		datos_mano_perdedor = _datos_de_mano(mano_jugador)
	var puntos_sueltos = ChinchonReglas.puntos_sueltos(datos_mano_perdedor)

	var puntos_cierre = int(info_cierre.get("loose_value", 0))
	if info_cierre.type == "limpio":
		puntos_cierre -= ChinchonReglas.BONIFICACION_LIMPIO

	if ganador == "jugador":
		GameState.puntaje_jugador += puntos_cierre
		GameState.puntaje_bot += puntos_sueltos
		temp_jugador = puntos_cierre
		temp_bot = puntos_sueltos
	else:
		GameState.puntaje_bot += puntos_cierre
		GameState.puntaje_jugador += puntos_sueltos
		temp_jugador = puntos_sueltos
		temp_bot = puntos_cierre
		

	var quien = GameState.nombre_jugador if ganador == "jugador" else "El bot"
	etiqueta_resultado.text = "%s cortó (%s)" % [quien, info_cierre.type]
	_refrescar_etiqueta_puntajes()
	panel_puntajes.visible = true
	_revisar_fin_de_partida()

func _revisar_fin_de_partida() -> void:
	var jugador_fuera = GameState.puntaje_jugador > ChinchonReglas.LIMITE_PUNTOS
	var bot_fuera = GameState.puntaje_bot > ChinchonReglas.LIMITE_PUNTOS
	if not jugador_fuera and not bot_fuera:
		return
	if jugador_fuera and bot_fuera and GameState.puntaje_jugador == GameState.puntaje_bot:
		return
	var gana_jugador: bool
	if jugador_fuera and bot_fuera:
		gana_jugador = GameState.puntaje_jugador < GameState.puntaje_bot
	else:
		gana_jugador = bot_fuera
	var quien = GameState.nombre_jugador if gana_jugador else "El bot"
	etiqueta_resultado.text += "\n¡%s gana la partida!" % quien
	GameState.registrar_partida(gana_jugador)
	_actualizar_etiqueta_estadisticas()
	GameState.reiniciar_puntajes()

func _mostrar_chinchon(ganador: String) -> void:
	var quien = GameState.nombre_jugador if ganador == "jugador" else "El bot"
	etiqueta_resultado.text = "¡Chinchón verdadero de %s! Gana la partida." % quien
	GameState.registrar_partida(ganador == "jugador")
	_actualizar_etiqueta_estadisticas()
	etiqueta_puntajes.text = ""
	panel_puntajes.visible = true
	GameState.reiniciar_puntajes()

func _refrescar_etiqueta_puntajes() -> void:
	etiqueta_puntajes.text = "%s: %d puntos (%s) \nBot: %d puntos (%s)"  %  [
		GameState.nombre_jugador,
		GameState.puntaje_jugador,
		temp_jugador,
		GameState.puntaje_bot,
		temp_bot,
	]
	if cartas_encajadas > 0:
		var quien_encajo = "El bot" if ganador_ronda == "jugador" else GameState.nombre_jugador
		etiqueta_puntajes.text += "\n%s metió %d carta(s) en el juego del que cortó" % [quien_encajo, cartas_encajadas]

func _iniciar_nueva_ronda() -> void:
	panel_puntajes.visible = false
	etiqueta_bot.text = ""
	cartas_encajadas = 0
	boton_terminar_encaje.visible = false
	_limpiar_combinaciones()
	for card in mano_jugador.mano.duplicate():
		card.queue_free()
		
	mano_jugador.mano.clear()
	mano_bot.limpiar_mano()
	pozo.reiniciar()
	mazo.crear_mazo()
	_iniciar_partida()

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
		boton_cortar.visible = jugador_puede_cortar() and ChinchonReglas.puede_cerrar(datos_mano)
	else:
		boton_cortar.visible = false
