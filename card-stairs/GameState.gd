extends Node

var nombre_jugador: String = "Jugador"
var puntaje_jugador: int = 0
var puntaje_bot: int = 0

func reiniciar_puntajes() -> void:
	puntaje_jugador = 0
	puntaje_bot = 0

const RUTA_ESTADISTICAS := "user://estadisticas.json"

func _cargar_tabla() -> Dictionary:
	if not FileAccess.file_exists(RUTA_ESTADISTICAS):
		return {}
	var archivo = FileAccess.open(RUTA_ESTADISTICAS, FileAccess.READ)
	if archivo == null:
		return {}
	var datos = JSON.parse_string(archivo.get_as_text())
	if typeof(datos) == TYPE_DICTIONARY and typeof(datos.get("jugadores")) == TYPE_DICTIONARY:
		return datos["jugadores"]
	return {}

func _guardar_tabla(tabla: Dictionary) -> void:
	var archivo = FileAccess.open(RUTA_ESTADISTICAS, FileAccess.WRITE)
	if archivo == null:
		push_warning("No se pudo guardar %s" % RUTA_ESTADISTICAS)
		return
	archivo.store_string(JSON.stringify({"jugadores": tabla}, "\t"))

func _armar_fila(victorias: int, derrotas: int) -> Dictionary:
	var partidas = victorias + derrotas
	var porcentaje = snappedf(100.0 * victorias / partidas, 0.1) if partidas > 0 else 0.0
	return {
		"victorias": victorias,
		"derrotas": derrotas,
		"partidas": partidas,
		"porcentaje_victoria": porcentaje,
	}

func obtener_estadisticas() -> Dictionary:
	var fila = _cargar_tabla().get(nombre_jugador, {})
	return _armar_fila(int(fila.get("victorias", 0)), int(fila.get("derrotas", 0)))

func registrar_partida(gano: bool) -> void:
	var tabla = _cargar_tabla()
	var fila = tabla.get(nombre_jugador, {})
	var victorias = int(fila.get("victorias", 0))
	var derrotas = int(fila.get("derrotas", 0))
	if gano:
		victorias += 1
	else:
		derrotas += 1
	tabla[nombre_jugador] = _armar_fila(victorias, derrotas)
	_guardar_tabla(tabla)
