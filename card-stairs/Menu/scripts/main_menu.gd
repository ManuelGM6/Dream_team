extends Control

@onready var audio_player = $audio_music
@onready var audio_btn = $audio_btn
@onready var anim_init = $AnimationPlayer
@onready var audio_menu = $main_menu_music

func _on_body_entered(cuerpo):
	if cuerpo.is_in_group("player"):
		audio_player.play()

func _ready():
	$"Blur".visible = false
	$"Salir".visible = false
	$"Jugar".visible = false
	$Opciones.visible = false
	anim_init.play("logo_appear")
	audio_menu.play()

func _on_jugar_boton_pressed():
	audio_btn.play()
	var interpolador = create_tween()
	$"Jugar".visible = true
	$"Blur".visible = true
	$"Jugar".modulate.a = 0
	$"Blur".modulate.a = 0
	
	interpolador.tween_property($Jugar, "modulate:a", 1.0 , 0.5)
	interpolador.tween_property($"Blur", "modulate:a", 0.7 , 0.5)

func _on_partida_pressed() -> void:
	audio_btn.play()
	var nombre = $"Jugar/NombreJugador".text.strip_edges()
	if nombre != "":
		GameState.nombre_jugador = nombre
	GameState.reiniciar_puntajes()
	get_tree().change_scene_to_file("res://Juego/escenas/jugar.tscn")

func cancelar_animacion_jugar():
	$"Jugar".visible = false
	$"Blur".visible = false
	$"Jugar".modulate.a = 1
	$"Blur".modulate.a = 0.5

func _on_flecha_salir_pressed():
	audio_btn.play()
	var interpolador = create_tween()
	interpolador.tween_property($"Jugar", "modulate:a", 0.0 , 0.5)
	interpolador.tween_property($"Blur", "modulate:a", 0.0, 0.3)
	interpolador.tween_callback(cancelar_animacion_jugar)

func _on_opciones_boton_pressed():
	audio_btn.play()
	var interpolador = create_tween()
	$Opciones.visible = true
	$"Blur".visible = true
	$Opciones.modulate.a = 0
	$"Blur".modulate.a = 0
	
	interpolador.tween_property($Opciones, "modulate:a", 1.0 , 0.5)
	interpolador.tween_property($"Blur", "modulate:a", 0.7 , 0.5)
	
func _on_pantalla_conpleta_toggled(activado: bool) -> void:
	if activado == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
func cancelar_animacion_opciones():
	$"Opciones".visible = false
	$"Blur".visible = false
	$"Opciones".modulate.a = 1
	$"Blur".modulate.a = 0.5
	
func _on_flecha_salir2_pressed():
	audio_btn.play()
	var interpolador = create_tween()
	
	interpolador.tween_property($"Opciones", "modulate:a", 0.0, 0.5)
	interpolador.tween_property($"Blur", "modulate:a", 0.0, 0.3)
	interpolador.tween_callback(cancelar_animacion_opciones)

func _on_salir_boton_pressed():
	audio_btn.play()
	var interpolador = create_tween()
	$"Salir".visible = true
	$"Blur".visible = true
	$"Salir".modulate.a = 0
	$"Blur".modulate.a = 0
	
	interpolador.tween_property($"Salir", "modulate:a", 1.0 , 0.5)
	interpolador.tween_property($"Blur", "modulate:a", 0.7 , 0.5)

func _on_confirmar_pressed():
	get_tree().quit()

func cancelar_animacion_salida():
	$"Salir".visible = false
	$"Blur".visible = false
	$"Salir".modulate.a = 1
	$"Blur".modulate.a = 0.5

func _on_cancelar_pressed():
	audio_btn.play()
	var interpolador = create_tween()
	
	interpolador.tween_property($"Salir", "modulate:a", 0.0, 0.5)
	interpolador.tween_property($"Blur", "modulate:a", 0.0, 0.3)
	interpolador.tween_callback(cancelar_animacion_salida)
