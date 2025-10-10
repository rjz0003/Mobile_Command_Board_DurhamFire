extends Node2D

var selected_sprite : Sprite2D = null
var rest_nodes = []
var rest_point : Vector2
var original_positions = {} 
const SNAP_DISTANCE = 75
var lastclick = 0.0
var doubleclickwindow = 0.3

func _ready():
	rest_nodes = get_tree().get_nodes_in_group("homezone")
	for sprite in get_tree().get_nodes_in_group("units"):
		original_positions[sprite] = sprite.global_position
		var area = sprite.get_node("Area2D")
		if area:
			area.connect("input_event", Callable(self, "_on_sprite_input_event").bind(sprite))

func _on_sprite_input_event(viewport, event, shape_idx, sprite):
	if Input.is_action_just_pressed("click"):
		selected_sprite = sprite

func _physics_process(delta):
	if selected_sprite:
		selected_sprite.global_position = selected_sprite.global_position.lerp(get_global_mouse_position(), 25 * delta)
	# Highlight near areas in the da house
	for zone in rest_nodes:
		if selected_sprite and selected_sprite.global_position.distance_to(zone.global_position) < SNAP_DISTANCE:
			zone.highlight()
		else:
			zone.unhighlight()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and selected_sprite:
			var currenttime = Time.get_ticks_msec()/1000
			var nearest_zone : Marker2D = null
			var shortest_dist = SNAP_DISTANCE

			if currenttime - lastclick <= doubleclickwindow:
				print('double')
				_show_option_button_popup(selected_sprite)
			else:
				print('single')
			lastclick = currenttime

			# Find nearest zone to snap to
			for zone in rest_nodes:
				var distance = selected_sprite.global_position.distance_to(zone.global_position)
				if distance < shortest_dist:
					shortest_dist = distance
					nearest_zone = zone

			if nearest_zone:
				selected_sprite.global_position = nearest_zone.global_position
			else:
				# return home command
				selected_sprite.global_position = original_positions[selected_sprite]
			selected_sprite = null

#option button initiation with double click above.. i hope
func _show_option_button_popup(sprite):
	if not sprite:
		return
	var button = sprite.get_node("Area2D/OptionButton")
	_option_button_stuff(button)
	if button:
		var pos = button.get_global_position()
		button.get_popup().popup(Rect2(pos, Vector2(1, 1)))
	else:
		print("OptionButton not found on sprite:", sprite)

func _option_button_stuff(mybutton):
	mybutton.get_popup().clear()
	mybutton.get_popup().add_item("Line A")
	mybutton.get_popup().add_item("Line B")
	mybutton.get_popup().add_item("Search")
	mybutton.get_popup().add_item("2nd Search")
	mybutton.get_popup().add_item("Laddering")
	mybutton.get_popup().add_item("Vent")
	mybutton.get_popup().add_item("Extrication")
	mybutton.get_popup().add_item("Utilities")
	mybutton.get_popup().add_item("Salvage")
	mybutton.get_popup().add_item("Overhaul")
	mybutton.get_popup().add_item("Division")
	mybutton.get_popup().add_item("Group")
	mybutton.get_popup().connect("id_pressed", Callable(self, "_on_popup_item_selected").bind(mybutton))


func _on_popup_item_selected(id, mybutton):
	var item = mybutton.get_popup().get_item_text(id)
	_add_sprite(item,mybutton)
	print("You picked:", item)
	
func _add_sprite(item, mybutton):
	var ability = Sprite2D.new()
	
	if item == "Line A":
		ability.texture = preload("res://Letters/A-removebg-preview.png")
	elif item == "Line B":
		ability.texture = preload("res://Letters/B-removebg-preview.png")
	elif item == "Search":
		ability.texture = preload("res://Letters/S-removebg-preview.png")
	elif item == "2nd Search":
		ability.texture = preload("res://Letters/SS-removebg-preview.png")
	elif item == "Laddering":
		ability.texture = preload("res://Letters/L-removebg-preview.png")
	elif item == "Vent":
		ability.texture = preload("res://Letters/V-removebg-preview.png")
	elif item == "Extrication":
		ability.texture = preload("res://Letters/X-removebg-preview.png")
	elif item == "Utilities":
		ability.texture = preload("res://Letters/U-removebg-preview.png")
	elif item == "Salvage":
		ability.texture = preload("res://Letters/_-removebg-preview.png")
	elif item == "Overhaul":
		ability.texture = preload("res://Letters/O-removebg-preview.png")
	elif item == "Division":
		ability.texture = preload("res://Letters/D-removebg-preview.png")
	elif item == "Group":
		ability.texture = preload("res://Letters/G-removebg-preview.png")
	else:
		return  # Exit if no match

	var sprite = mybutton.get_parent()
	sprite.add_child(ability)

	# Position the letter relative to the sprite
	ability.position = Vector2(20, 10)  
	ability.scale = Vector2(1.2, 1.2)
	#ability.modulate = Color(1, 1, 1) 
