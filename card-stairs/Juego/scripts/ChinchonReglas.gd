extends Node
class_name ChinchonReglas

static func card_value(numero: int) -> int:
	return numero if numero < 10 else 10

static func cards_equal(a: Dictionary, b: Dictionary) -> bool:
	return a.get("palo") == b.get("palo") and a.get("numero") == b.get("numero")

static func _contains_card(lista: Array, carta: Dictionary) -> bool:
	for c in lista:
		if cards_equal(c, carta):
			return true
	return false

static func _restar(lista: Array, a_quitar: Array) -> Array:
	var resultado = lista.duplicate()
	for carta in a_quitar:
		for i in range(resultado.size()):
			if cards_equal(resultado[i], carta):
				resultado.remove_at(i)
				break
	return resultado

static func es_grupo(cartas: Array) -> bool:
	if cartas.size() < 3 or cartas.size() > 4:
		return false
	var numero = cartas[0].numero
	for c in cartas:
		if c.numero != numero:
			return false
	return true

static func es_escalera(cartas: Array) -> bool:
	if cartas.size() < 3:
		return false
	var palo = cartas[0].palo
	var cartas_ordenadas = cartas.duplicate()
	cartas_ordenadas.sort_custom(func(a, b): return a.numero < b.numero)
	for i in range(cartas_ordenadas.size()):
		if cartas_ordenadas[i].palo != palo:
			return false
		if i > 0 and cartas_ordenadas[i].numero != cartas_ordenadas[i - 1].numero + 1:
			return false
	return true

static func es_combinacion(cartas: Array) -> bool:
	return es_grupo(cartas) or es_escalera(cartas)

static func generar_combinaciones_posibles(mano: Array) -> Array:
	var combinaciones = []

	var por_numero = {}
	for c in mano:
		if not por_numero.has(c.numero):
			por_numero[c.numero] = []
		por_numero[c.numero].append(c)
	for numero in por_numero.keys():
		var cartas = por_numero[numero]
		if cartas.size() >= 3:
			combinaciones.append([cartas[0], cartas[1], cartas[2]])
		if cartas.size() >= 4:
			combinaciones.append([cartas[0], cartas[1], cartas[2], cartas[3]])
			combinaciones.append([cartas[0], cartas[1], cartas[3]])
			combinaciones.append([cartas[0], cartas[2], cartas[3]])
			combinaciones.append([cartas[1], cartas[2], cartas[3]])

	var por_palo = {}
	for c in mano:
		if not por_palo.has(c.palo):
			por_palo[c.palo] = []
		por_palo[c.palo].append(c)
	for palo in por_palo.keys():
		var cartas = por_palo[palo]
		cartas.sort_custom(func(a, b): return a.numero < b.numero)
		var i = 0
		while i < cartas.size():
			var j = i
			while j + 1 < cartas.size() and cartas[j + 1].numero == cartas[j].numero + 1:
				j += 1
			var largo_tirada = j - i + 1
			if largo_tirada >= 3:
				for inicio in range(i, j + 1):
					for longitud in range(3, largo_tirada + 1):
						var fin = inicio + longitud - 1
						if fin > j:
							break
						combinaciones.append(cartas.slice(inicio, fin + 1))
			i = j + 1

	return combinaciones

static func mejor_particion(mano: Array) -> Dictionary:
	var posibles = generar_combinaciones_posibles(mano)
	return _buscar_particion(mano, posibles)

static func _buscar_particion(restantes: Array, combinaciones_posibles: Array) -> Dictionary:
	var mejor = {"melds": [], "leftover": restantes.duplicate()}
	for combinacion in combinaciones_posibles:
		var entra = true
		for carta in combinacion:
			if not _contains_card(restantes, carta):
				entra = false
				break
		if not entra:
			continue
		var nuevo_restante = _restar(restantes, combinacion)
		var nuevas_posibles = []
		for comb in combinaciones_posibles:
			var sigue_entrando = true
			for carta in comb:
				if not _contains_card(nuevo_restante, carta):
					sigue_entrando = false
					break
			if sigue_entrando:
				nuevas_posibles.append(comb)
		var candidata = _buscar_particion(nuevo_restante, nuevas_posibles)
		var cubiertas_candidata = restantes.size() - candidata.leftover.size()
		var cubiertas_mejor = restantes.size() - mejor.leftover.size()
		if cubiertas_candidata > cubiertas_mejor:
			mejor = {"melds": [combinacion] + candidata.melds, "leftover": candidata.leftover}
	return mejor

static func puntos_sueltos(mano: Array) -> int:
	var particion = mejor_particion(mano)
	var total = 0
	for c in particion.leftover:
		total += card_value(c.numero)
	return total

static func evaluar_opciones_cierre(mano8: Array) -> Array:
	var opciones = []
	for i in range(mano8.size()):
		var descarte_candidato = mano8[i]
		var restantes = mano8.duplicate()
		restantes.remove_at(i)
		var particion = mejor_particion(restantes)
		var sobrante = particion.leftover
		if sobrante.size() == 0:
			opciones.append({"discard": descarte_candidato, "type": "limpio", "melds": particion.melds})
		elif sobrante.size() == 1 and card_value(sobrante[0].numero) <= 5:
			opciones.append({
				"discard": descarte_candidato,
				"type": "margen",
				"melds": particion.melds,
				"loose_value": card_value(sobrante[0].numero)
			})
	return opciones

static func puede_cerrar(mano8: Array) -> bool:
	return evaluar_opciones_cierre(mano8).size() > 0

static func es_cierre_chinchon(info_cierre: Dictionary) -> bool:
	return info_cierre.type == "limpio" and info_cierre.melds.size() == 1 and info_cierre.melds[0].size() == 7

static func es_chinchon(mano7: Array) -> bool:
	if mano7.size() != 7:
		return false
	return es_escalera(mano7)
