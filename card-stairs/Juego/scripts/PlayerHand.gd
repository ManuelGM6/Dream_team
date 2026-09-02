extends Node2D

const HAND_Y_POSITION = 775
const DEFAULT_CARD_MOVE_SPEED = 0.1
const FAN_ANGLE_STEP = 5.0
const FAN_RADIUS = 1500.0

var player_hand = []
var center_screen_x

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2
	
func add_card_to_hand(card, speed):
	if card not in player_hand:
		player_hand.insert(0, card)
		update_hand_positions(speed)
	else:
		card.animate_to({
			"position": card.starting_position,
			"rotation_degrees": card.starting_rotation
		}, DEFAULT_CARD_MOVE_SPEED)

func update_hand_positions(speed):
	for i in range(player_hand.size()):
		var fan_transform = calculate_fan_transform(i)
		var card = player_hand[i]
		card.starting_position = fan_transform.position
		card.starting_rotation = fan_transform.rotation
		card.animate_to({
			"position": fan_transform.position,
			"rotation_degrees": fan_transform.rotation
		}, speed)

func calculate_fan_transform(index) -> Dictionary:
	var center_index = (player_hand.size() - 1) / 2.0
	var angle_deg = (index - center_index) * FAN_ANGLE_STEP
	var angle_rad = deg_to_rad(angle_deg)
	var x = center_screen_x + 200 + sin(angle_rad) * FAN_RADIUS
	var y = HAND_Y_POSITION + FAN_RADIUS * (1 - cos(angle_rad))
	return {"position": Vector2(x, y), "rotation": angle_deg}

func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_positions(DEFAULT_CARD_MOVE_SPEED)
