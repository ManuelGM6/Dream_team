extends Node2D

const CARD_SCENE_PATH = "res://Juego/escenas/card.tscn"
const CARD_DRAW_SPEED = 0.2

var player_deck = ["1 de mundial", "1 de mundial", "1 de mundial"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func draw_card():
	var card_drawn = player_deck [0]
	player_deck.erase(card_drawn)
#
	if player_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$Sprite2D.visible = false

	var card_scene = preload(CARD_SCENE_PATH)
	for i in range(player_deck.size()):
		var new_card = card_scene.instantiate()
		$"../CardManager".add_child(new_card)
		new_card.name = "Card"
		$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
