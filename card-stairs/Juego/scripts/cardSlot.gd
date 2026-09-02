extends Node2D

var card_in_slot = null

func is_occupied() -> bool:
	return card_in_slot != null

func place_card(card: Node2D) -> void:
	card_in_slot = card
	card.current_slot = self

func remove_card() -> void:
	if card_in_slot:
		card_in_slot.current_slot = null
	card_in_slot = null
