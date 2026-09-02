extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2
const  DEFAULT_CARD_MOVE_SPEED = 0.1

const DEFAULT_SCALE = Vector2(0.75, 0.75)
const HOVER_SCALE = Vector2(1, 1)
const DRAG_SCALE = Vector2(1, 1)
const HOVER_LIFT = 45.0 
const HOVER_SPEED = 0.12

var screen_size
var card_being_dragged
var currently_hovered_card = null
var player_hand_reference

func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_hand_reference = $"../PlayerHand"
	$"../InputManager".connect("left_mouse_button_released", on_left_click_released)


@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x), 
			clamp(mouse_pos.y, 0, screen_size.y))

func start_drag(card):
	card_being_dragged = card
	card.animate_to({"scale": DRAG_SCALE, "rotation_degrees": 0}, 0.1)
	if card.current_slot:
		card.current_slot.remove_card()

func finish_drag():
	card_being_dragged.scale = DEFAULT_SCALE
	var card_slot_found = raycast_check_for_card_slot()
	if card_slot_found and not card_slot_found.is_occupied():
		player_hand_reference.remove_card_from_hand(card_being_dragged)
		card_being_dragged.position = card_slot_found.position
		card_slot_found.place_card(card_being_dragged)
	else:
		player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
	card_being_dragged = null

func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)
	
func on_left_click_released():
	if card_being_dragged:
		finish_drag()

func on_hovered_over_card(card):
	if card_being_dragged:
		return
	if currently_hovered_card == card:
		return
	if currently_hovered_card:
		highlight_card(currently_hovered_card, false)
	currently_hovered_card = card
	highlight_card(card, true)

func on_hovered_off_card(card):
	if card_being_dragged:
		return
	if currently_hovered_card != card:
		return
	highlight_card(card, false)
	currently_hovered_card = null
	var new_card_hovered = raycast_check_for_card()
	if new_card_hovered:
		currently_hovered_card = new_card_hovered
		highlight_card(new_card_hovered, true)

func highlight_card(card, hovered):
	if hovered:
		card.z_index = 2
		card.animate_to({
			"scale": HOVER_SCALE,
			"position": card.starting_position + Vector2(0, -HOVER_LIFT)
		}, HOVER_SPEED)
	else:
		card.z_index = 1
		card.animate_to({
			"scale": DEFAULT_SCALE,
			"position": card.starting_position
		}, HOVER_SPEED)

func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	
	var result = space_state.intersect_point(parameters)
	
	if result.size() > 0:
		return get_card_with_highest_z_index(result)
	return null

func raycast_check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT
	
	var result = space_state.intersect_point(parameters)
	
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null

func get_card_with_highest_z_index(cards):
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card
