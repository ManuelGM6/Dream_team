extends Node2D

var card_in_slot = null

func esta_ocupado() -> bool:
	return card_in_slot != null

func place_card(card: Node2D) -> void:
	card_in_slot = card
	card.ranura_actual = self

func remove_card() -> void:
	if card_in_slot:
		card_in_slot.ranura_actual = null
	card_in_slot = null
