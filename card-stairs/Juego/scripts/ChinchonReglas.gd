extends Node
class_name ChinchonReglas

const BaseCartas = preload("res://Juego/scripts/CardDatabase.gd")

const TAMANO_MANO := 7
const MINIMO_COMBINACION := 3
const LIMITE_MARGEN := 5
const LIMITE_PUNTOS := 100
const BONIFICACION_LIMPIO := 10
const TAMANO_GRUPO_ESPECIAL := 5
const PRIORIDAD_TIPO := {"limpio": 0, "margen": 1, "grupo_cinco": 2}

static func cantidad_palos() -> int:
	return BaseCartas.CARDS.size()

static func card_value(numero: int) -> int:
	return numero if numero < 10 else 10

static func cards_equal(a: Dictionary, b: Dictionary) -> bool:
	return a.get("palo") == b.get("palo") and a.get("numero") == b.get("numero")

static func _valor_total(cartas: Array) -> int:
	var total := 0
	for c in cartas:
		total += card_value(c.numero)
	return total

static func _cartas_de(mano: Array, indices: Array) -> Array:
	var cartas: Array = []
	for i in indices:
		cartas.append(mano[i])
	return cartas

static func es_grupo(cartas: Array) -> bool:
	if cartas.size() < MINIMO_COMBINACION or cartas.size() > cantidad_palos():
		return false
	var numero = cartas[0].numero
	var palos := {}
	for c in cartas:
		if c.numero != numero or palos.has(c.palo):
			return false
		palos[c.palo] = true
	return true

static func es_escalera(cartas: Array) -> bool:
	if cartas.size() < MINIMO_COMBINACION:
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

static func puede_encajar(carta: Dictionary, combinacion: Array) -> bool:
	var extendida: Array = combinacion.duplicate()
	extendida.append(carta)
	return es_combinacion(extendida)

static func indice_combinacion_para(carta: Dictionary, combinaciones: Array) -> int:
	for i in range(combinaciones.size()):
		if puede_encajar(carta, combinaciones[i]):
			return i
	return -1

static func ordenar_combinacion(combinacion: Array) -> void:
	if es_escalera(combinacion):
		combinacion.sort_custom(func(a, b): return a.numero < b.numero)

static func _subconjuntos(items: Array, k: int, desde: int, actual: Array) -> Array:
	if actual.size() == k:
		return [actual.duplicate()]
	var resultado: Array = []
	for i in range(desde, items.size()):
		actual.append(items[i])
		resultado.append_array(_subconjuntos(items, k, i + 1, actual))
		actual.pop_back()
	return resultado

static func _grupos_indices(mano: Array) -> Array:
	var por_numero := {}
	for i in range(mano.size()):
		var numero = mano[i].numero
		if not por_numero.has(numero):
			por_numero[numero] = []
		por_numero[numero].append(i)
	var resultado: Array = []
	for numero in por_numero.keys():
		var indices: Array = por_numero[numero]
		var tamano_maximo: int = mini(indices.size(), cantidad_palos())
		for tamano in range(MINIMO_COMBINACION, tamano_maximo + 1):
			for subconjunto in _subconjuntos(indices, tamano, 0, []):
				if es_grupo(_cartas_de(mano, subconjunto)):
					resultado.append(subconjunto)
	return resultado

static func _escaleras_indices(mano: Array) -> Array:
	var por_palo := {}
	for i in range(mano.size()):
		var palo = mano[i].palo
		if not por_palo.has(palo):
			por_palo[palo] = []
		por_palo[palo].append(i)
	var resultado: Array = []
	for palo in por_palo.keys():
		var indices: Array = por_palo[palo]
		indices.sort_custom(func(a, b): return mano[a].numero < mano[b].numero)
		var unicos: Array = []
		for i in indices:
			if unicos.is_empty() or mano[unicos[unicos.size() - 1]].numero != mano[i].numero:
				unicos.append(i)
		var inicio_tirada := 0
		while inicio_tirada < unicos.size():
			var fin_tirada := inicio_tirada
			while fin_tirada + 1 < unicos.size() and mano[unicos[fin_tirada + 1]].numero == mano[unicos[fin_tirada]].numero + 1:
				fin_tirada += 1
			for desde in range(inicio_tirada, fin_tirada + 1):
				for hasta in range(desde + MINIMO_COMBINACION - 1, fin_tirada + 1):
					resultado.append(unicos.slice(desde, hasta + 1))
			inicio_tirada = fin_tirada + 1
	return resultado

static func _combinaciones_indices(mano: Array) -> Array:
	var resultado: Array = []
	resultado.append_array(_grupos_indices(mano))
	resultado.append_array(_escaleras_indices(mano))
	return resultado

static func generar_combinaciones_posibles(mano: Array) -> Array:
	var resultado: Array = []
	for indices in _combinaciones_indices(mano):
		resultado.append(_cartas_de(mano, indices))
	return resultado

static func _mascara(indices: Array) -> int:
	var mascara := 0
	for i in indices:
		mascara |= 1 << i
	return mascara

static func _expandir(datos: Array, desde: int, usadas: int, elegidas: Array, salida: Array) -> void:
	salida.append({"melds": elegidas.duplicate(), "mascara": usadas})
	for i in range(desde, datos.size()):
		if (datos[i].mascara & usadas) == 0:
			elegidas.append(datos[i].indices)
			_expandir(datos, i + 1, usadas | datos[i].mascara, elegidas, salida)
			elegidas.pop_back()

static func _enumerar_particiones(mano: Array) -> Array:
	var datos: Array = []
	for indices in _combinaciones_indices(mano):
		datos.append({"indices": indices, "mascara": _mascara(indices)})
	var salida: Array = []
	_expandir(datos, 0, 0, [], salida)
	var particiones: Array = []
	for p in salida:
		var melds_cartas: Array = []
		for indices in p.melds:
			melds_cartas.append(_cartas_de(mano, indices))
		var sobrantes: Array = []
		for i in range(mano.size()):
			if ((p.mascara >> i) & 1) == 0:
				sobrantes.append(mano[i])
		particiones.append({"melds": melds_cartas, "leftover": sobrantes})
	return particiones

static func mejor_particion(mano: Array) -> Dictionary:
	var mejor := {}
	var mejores_puntos := 1000000
	for particion in _enumerar_particiones(mano):
		var puntos := _valor_total(particion.leftover)
		if mejor.is_empty() or puntos < mejores_puntos or (puntos == mejores_puntos and particion.leftover.size() < mejor.leftover.size()):
			mejor = particion
			mejores_puntos = puntos
	return mejor

static func puntos_sueltos(mano: Array) -> int:
	return _valor_total(mejor_particion(mano).leftover)

static func puntos_minimos_tras_descarte(mano8: Array) -> int:
	var mejor := 1000000
	for i in range(mano8.size()):
		var restantes = mano8.duplicate()
		restantes.remove_at(i)
		mejor = mini(mejor, puntos_sueltos(restantes))
	return mejor

static func _condicion_limpio(particion: Dictionary) -> Dictionary:
	if particion.leftover.is_empty():
		return {"type": "limpio", "loose_value": 0}
	return {}

static func _condicion_margen(particion: Dictionary) -> Dictionary:
	if particion.leftover.size() == 1:
		var valor: int = card_value(particion.leftover[0].numero)
		if valor <= LIMITE_MARGEN:
			return {"type": "margen", "loose_value": valor}
	return {}

static func _condicion_grupo_especial(particion: Dictionary) -> Dictionary:
	var hay_grupo := false
	for meld in particion.melds:
		if meld.size() == TAMANO_GRUPO_ESPECIAL and es_grupo(meld):
			hay_grupo = true
	if not hay_grupo or particion.leftover.size() != TAMANO_MANO - TAMANO_GRUPO_ESPECIAL:
		return {}
	var suma: int = _valor_total(particion.leftover)
	if suma <= LIMITE_MARGEN:
		return {"type": "grupo_cinco", "loose_value": suma}
	return {}

static func _condiciones_cumplidas(particion: Dictionary) -> Array:
	var cumplidas: Array = []
	for resultado in [
		_condicion_limpio(particion),
		_condicion_margen(particion),
		_condicion_grupo_especial(particion),
	]:
		if not resultado.is_empty():
			cumplidas.append(resultado)
	return cumplidas

static func _clave_opcion(opcion: Dictionary) -> int:
	var base_chinchon := 0 if opcion.get("chinchon", false) else 1000
	return base_chinchon + int(PRIORIDAD_TIPO.get(opcion.type, 9)) * 100 + int(opcion.loose_value)

static func elegir_mejor_opcion(opciones: Array) -> Dictionary:
	if opciones.is_empty():
		return {}
	var mejor: Dictionary = opciones[0]
	for opcion in opciones:
		if _clave_opcion(opcion) < _clave_opcion(mejor):
			mejor = opcion
	return mejor

static func mejor_cierre_de_mano(mano7: Array) -> Dictionary:
	if mano7.size() != TAMANO_MANO:
		return {}
	var es_mano_chinchon := es_chinchon(mano7)
	var mejor := {}
	for particion in _enumerar_particiones(mano7):
		for resultado in _condiciones_cumplidas(particion):
			resultado["melds"] = particion.melds
			resultado["leftover"] = particion.leftover
			resultado["chinchon"] = es_mano_chinchon and resultado.type == "limpio"
			if mejor.is_empty() or _clave_opcion(resultado) < _clave_opcion(mejor):
				mejor = resultado
	return mejor

static func evaluar_opciones_cierre(mano8: Array) -> Array:
	var opciones: Array = []
	for i in range(mano8.size()):
		var restantes = mano8.duplicate()
		restantes.remove_at(i)
		var cierre := mejor_cierre_de_mano(restantes)
		if not cierre.is_empty():
			cierre["discard"] = mano8[i]
			opciones.append(cierre)
	return opciones

static func puede_cerrar(mano8: Array) -> bool:
	return not evaluar_opciones_cierre(mano8).is_empty()

static func es_cierre_chinchon(info_cierre: Dictionary) -> bool:
	return info_cierre.get("chinchon", false)

static func es_chinchon(mano7: Array) -> bool:
	if mano7.size() != TAMANO_MANO:
		return false
	return es_escalera(mano7)
