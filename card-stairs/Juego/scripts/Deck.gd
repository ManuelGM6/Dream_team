extends Node2D

const CARD_SCENE_PATH = "res://Juego/escenas/card.tscn"
const CARD_DRAW_SPEED = 0.2
var player_deck = []
var card_database_reference

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	card_database_reference = preload("res://Juego/scripts/CardDatabase.gd")
	create_deck()

func draw_card():
	if player_deck.size() == 1:
		$Area2D/CollisionShape2D.disabled = true
		$Sprite2D.visible = false
		$RichTextLabel.visible = false
		
	var card = player_deck.pop_front()
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	$RichTextLabel.text = str(player_deck.size())
	
	new_card.get_node("CardImage").texture = get_card_texture(card)
	$"../CardManager".add_child(new_card)
	$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
	new_card.get_node("AnimationPlayer").play("card_flip")

func create_deck():
	for palo in card_database_reference.CARDS.keys():
		for numero in card_database_reference.CARDS[palo]:
			player_deck.append({
				"palo": palo,
				"numero": numero
			})
	player_deck.shuffle()
	$RichTextLabel.text = str(player_deck.size())

func get_card_texture(card):
	var ruta = "res://Juego/imgs/Cards/%s/%d_%s.jpg" % [
		card.palo,
		card.numero,
		card.palo
	]
	return load(ruta)
