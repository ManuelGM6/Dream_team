extends Control

@onready var audio_player = $audio_music
@onready var audio_btn = $audio_btn
@onready var anim_init = $AnimationPlayer
@onready var audio_menu = $main_menu_music

func _on_body_entered(body):
	if body.is_in_group("player"):
		audio_player.play()

func _ready():
	$"Blur".visible = false
	$"Salir".visible = false
	$"Jugar".visible = false
	$Opciones.visible = false
	anim_init.play("logo_appear")

func _process(delta: float) -> void:
	audio_menu.play()

func _on_jugar_boton_pressed():
	var tween = create_tween()
	$"Jugar".visible = true
	$"Jugar".modulate.a = 0
	tween.tween_property($"Jugar", "modulate:a", 1.0 , 0.5)

func cancelar_animacion_jugar():
	$"Jugar".visible = false
	$"Jugar".modulate.a = 1

func _on_flecha_salir_pressed():
	var tween = create_tween()
	tween.tween_property($"Jugar", "modulate:a", 0.0 , 0.5)
	tween.tween_callback(cancelar_animacion_jugar)

func _on_opciones_boton_pressed():
	$Opciones.visible = true
	
func _on_pantalla_conpleta_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
func _on_flecha_salir2_pressed():
	$Opciones.visible = false

func _on_salir_boton_pressed():
	var tween = create_tween()
	$"Salir".visible = true
	$"Blur".visible = true
	$"Salir".modulate.a = 0
	$"Blur".modulate.a = 0
	
	tween.tween_property($"Salir", "modulate:a", 1.0 , 0.5)
	tween.tween_property($"Blur", "modulate:a", 0.7 , 0.5)

func _on_confirmar_pressed():
	get_tree().quit()

func cancelar_animacion_salida():
	$"Salir".visible = false
	$"Blur".visible = false
	$"Salir".modulate.a = 1
	$"Blur".modulate.a = 0.5

func _on_cancelar_pressed():
	var tween = create_tween()
	
	tween.tween_property($"Salir", "modulate:a", 0.0, 0.5)
	tween.tween_property($"Blur", "modulate:a", 0.0, 0.3)
	tween.tween_callback(cancelar_animacion_salida)
