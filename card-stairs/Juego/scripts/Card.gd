extends Node2D

signal resaltada
signal resaltada_fin

var posicion_inicial
var rotacion_inicial = 0.0
var ranura_actual = null
var tween_activo: Tween = null
var card_data: Dictionary = {}
var indice_z_base: int = 0

const REFERENCE_TEXTURE_SIZE = Vector2(855, 1300)
const CARD_IMAGE_BASE_SCALE = Vector2(0.083449, 0.077692)

func set_card_data(data: Dictionary) -> void:
	card_data = data

func establecer_textura_frente(tex: Texture2D) -> void:
	var card_image = $CardImage
	card_image.texture = tex
	if tex == null:
		return
	var tex_size = tex.get_size()
	card_image.scale = Vector2(
		CARD_IMAGE_BASE_SCALE.x * REFERENCE_TEXTURE_SIZE.x / tex_size.x,
		CARD_IMAGE_BASE_SCALE.y * REFERENCE_TEXTURE_SIZE.y / tex_size.y
	)

func _ready() -> void:
	get_parent().connect_card_signals(self)

func _process(delta: float) -> void:
	pass

func animar_a(propiedades: Dictionary, velocidad: float) -> void:
	if tween_activo and tween_activo.is_valid():
		tween_activo.kill()
	tween_activo = create_tween()
	tween_activo.set_parallel(true)
	for nombre_propiedad in propiedades.keys():
		tween_activo.tween_property(self, nombre_propiedad, propiedades[nombre_propiedad], velocidad)

func _al_entrar_mouse_en_area() -> void:
	emit_signal("resaltada", self)

func _al_salir_mouse_de_area() -> void:
	emit_signal("resaltada_fin", self)
