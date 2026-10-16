extends Node

@onready var gestor_juego = $"../GameManager"
@onready var mano_bot = $"../BotHand"
@onready var pozo = $"../Pozo"
@onready var mazo = $"../Deck"

const PAUSA_PENSAR := 1.0
const PAUSA_TRAS_ROBAR := 1.3

func jugar_turno() -> void:
	gestor_juego.anunciar_accion_bot("El bot está pensando...")
	await get_tree().create_timer(PAUSA_PENSAR).timeout
	var robo_del_pozo = _robar()
	gestor_juego.anunciar_accion_bot("El bot agarró del pozo" if robo_del_pozo else "El bot agarró del mazo")
	await get_tree().create_timer(PAUSA_TRAS_ROBAR).timeout
	_descartar_o_cerrar()

func _robar() -> bool:
	var mano = mano_bot.mano
	var tope_pozo = pozo.peek_top_card_data()
	var robar_del_pozo = false

	if tope_pozo != null:
		var puntos_sueltos_actuales = ChinchonReglas.puntos_sueltos(mano)
		var con_pozo = mano.duplicate()
		con_pozo.append(tope_pozo)
		var puntos_sueltos_con_pozo = ChinchonReglas.puntos_minimos_tras_descarte(con_pozo)
		if puntos_sueltos_con_pozo < puntos_sueltos_actuales:
			robar_del_pozo = true

	var robada: Dictionary
	if robar_del_pozo:
		robada = pozo.draw_top_card_data()
	else:
		robada = mazo.draw_card_data()

	if not robada.is_empty():
		mano_bot.add_card(robada)
	return robar_del_pozo and not robada.is_empty()

func _descartar_o_cerrar() -> void:
	var mano = mano_bot.mano
	var opciones = []
	if gestor_juego.bot_puede_cortar():
		opciones = ChinchonReglas.evaluar_opciones_cierre(mano)

	if not opciones.is_empty():
		var elegida = ChinchonReglas.elegir_mejor_opcion(opciones)
		mano_bot.remove_card(elegida.discard)
		gestor_juego.terminar_cierre_bot(elegida)
		return

	var mejor_descarte = mano[0]
	var mejores_puntos_sueltos_restantes = 9999
	for carta in mano:
		var restantes = mano.duplicate()
		for i in range(restantes.size()):
			if ChinchonReglas.cards_equal(restantes[i], carta):
				restantes.remove_at(i)
				break
		var psueltos = ChinchonReglas.puntos_sueltos(restantes)
		if psueltos < mejores_puntos_sueltos_restantes:
			mejores_puntos_sueltos_restantes = psueltos
			mejor_descarte = carta

	mano_bot.remove_card(mejor_descarte)
	gestor_juego.terminar_descarte_bot(mejor_descarte)
