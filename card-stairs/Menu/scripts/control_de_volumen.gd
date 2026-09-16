extends HSlider

@export var nombre_bus_audio: String

var id_bus_audio
func _ready():
	id_bus_audio = AudioServer.get_bus_index(nombre_bus_audio)

func _on_value_changed(valor: float):
	var db = linear_to_db(valor)
	AudioServer.set_bus_volume_db(id_bus_audio, db)
