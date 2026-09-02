extends Node2D

signal hovered
signal hovered_off

var starting_position
var starting_rotation = 0.0
var current_slot = null
var active_tween: Tween = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_parent().connect_card_signals(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func animate_to(properties: Dictionary, speed: float) -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	active_tween = create_tween()
	active_tween.set_parallel(true)
	for property_name in properties.keys():
		active_tween.tween_property(self, property_name, properties[property_name], speed)

func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)

func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
