extends Node2D
var selected_sprite : Sprite2D = null
var rest_nodes = []
var rest_point : Vector2
var original_positions = {} 
const SNAP_DISTANCE = 75
var lastclick = 0.0
var doubleclickwindow = 0.3
var Sprite_in_question : Sprite2D = null
#var ability =''
################################
##Ideas
#so for the responding make it that if sprite is clicked single its responding(not sure how to make an undo for this 
#### update on this i want to make it so that if single click on a group name initials hides that initial and unhides the other sprite thats named the smae
#back to that ffirst one maybe a undo button??? not sure how to do that yet might tie into the menu bar
#still need to make that top bar, might just make that a sprite idk
#make it so only one sprite can be attached to a larger sprit, make it so when they go to RIT or assigned a new val they then clear old sprite
#ghostiunbg and recodding need to add rit and rehab 
#medic 1-99
#misc units - hazmat pother random stuff (make it so you can make own sprites?)(maybe color code)

#bottom row, could be drop down of other controls(about 15 min in)
	#
#10 min checker can go away once done
#mayday is reactionary

# reference to inital_nodes NODE (using group system)
var initial_nodes_script = null
signal hide(sprite_name)
func _ready():
	add_to_group("dfd_group")
	
	# Wait for all nodes to be ready before looking for the group
	await get_tree().process_frame
	
	initial_nodes_script = get_tree().get_first_node_in_group("initial_nodes_group")
	
	if initial_nodes_script:
		print("Found inital_nodes at:", initial_nodes_script.get_path())
		initial_nodes_script.connect("og_sprite_clicked", Callable(self, "_on_og_sprite_clicked"))
		print("Successfully connected to inital_nodes signal")
	else:
		print("Error: couldn't find inital_nodes in group 'initial_nodes_group'!")
	
	# hide all unit sprites initially
	for sprite in get_tree().get_nodes_in_group("units"):
		sprite.hide()
		# Store original positions for reset
		original_positions[sprite] = sprite.global_position
		# Connect input events for dragging
		var area = sprite.get_node_or_null("Area2D")
		if area:
			area.connect("input_event", Callable(self, "_on_sprite_input_event").bind(sprite))
		else:
			print("Warning: No Area2D found on sprite:", sprite.name)
			

			
			
	# Collect all Marker2D nodes for snapping
	for node in get_tree().get_nodes_in_group("homezone"):
		if node is Marker2D:
			rest_nodes.append(node)
	print("Found", rest_nodes.size(), "snap zones")

func _on_og_sprite_clicked(sprite_name):
	print("og sprite clicked working")
	
	# look for matching sprite in "units" group
	for sprite in get_tree().get_nodes_in_group("units"):
		if sprite.name == sprite_name:
			sprite.show()
			print("Showed matching unit:", sprite.name)


func _on_sprite_input_event(viewport, event, shape_idx, sprite):
	print('sprite input wokrking')
	if Input.is_action_just_pressed("click"):
		selected_sprite = sprite

func _physics_process(delta):
	if selected_sprite:
		selected_sprite.global_position = selected_sprite.global_position.lerp(get_global_mouse_position(), 25 * delta)
	# Highlight near areas in the da house(the people.. like this???
	for zone in rest_nodes:
		if selected_sprite and selected_sprite.global_position.distance_to(zone.global_position) < SNAP_DISTANCE:
			zone.highlight()
		else:
			zone.unhighlight()

func _input(event):
	print('input')
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and selected_sprite:
			var currenttime = Time.get_ticks_msec()/1000
			var nearest_zone : Marker2D = null
			var shortest_dist = SNAP_DISTANCE
			var current_position = selected_sprite.global_position

			if currenttime - lastclick <= doubleclickwindow:
				_show_option_button_popup(selected_sprite)
			lastclick = currenttime

			for zone in rest_nodes:
				var distance = selected_sprite.global_position.distance_to(zone.global_position)
				if distance < shortest_dist:
					shortest_dist = distance
					nearest_zone = zone

			if nearest_zone:
				selected_sprite.global_position = nearest_zone.global_position
				_ghost_time(selected_sprite,current_position)
			else:
				# return home command
				########################################
				#lowkey might want to change this to return to last position me thinks idk
				selected_sprite.global_position = original_positions[selected_sprite]
			selected_sprite = null

#drop down wit double click above.. i hope
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
	mybutton.get_popup().add_item("Clear")
	mybutton.get_popup().add_item("Undo")
	mybutton.get_popup().connect("id_pressed", Callable(self, "_on_popup_item_selected").bind(mybutton))
	


func _on_popup_item_selected(id, mybutton):
	var item = mybutton.get_popup().get_item_text(id)
	_add_sprite(item, mybutton)

#func to add sprite for their job on the fire ground
func _add_sprite(item, mybutton):
	var sprite = mybutton.get_parent().get_parent()
	if not sprite:
		return
	
	if sprite.has_meta("ability_label"):
		var old_ability = sprite.get_meta("ability_label")
		if old_ability and old_ability.is_inside_tree():
			old_ability.free()
		sprite.set_meta("ability_label", null)

	if item == "Clear":
		return
	if item == "Undo":
		sprite.hide()
		emit_signal("hide", sprite.name)  # This line already exists
		
	var ability = Sprite2D.new()
	ability.name = "ability_label"
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
		return

	sprite.add_child(ability)
	ability.position = Vector2(20, 10)
	ability.scale = Vector2(1.2, 1.2)
	ability.z_index = 1

	# save function for multi use
	sprite.set_meta("ability_label", ability)

func _ogs_event(sprite):
	sprite.show()

#ok i want to add a function that will leave a slash through the it
##Logic
# i think it needs to check if global is != to its original position

func _ghost_time(selected_sprite,current_position):
	var slasher = selected_sprite.duplicate()
	slasher.position(current_position)
	
	



#func _input(event):
#	print('input')
#	if event is InputEventMouseButton:
#		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and selected_sprite:
#			var currenttime = Time.get_ticks_msec()/1000
#			var nearest_zone : Marker2D = null
#			var shortest_dist = SNAP_DISTANCE
#
#			if currenttime - lastclick <= doubleclickwindow:
#				_show_option_button_popup(selected_sprite)
#			lastclick = currenttime
#
#			for zone in rest_nodes:
#				var distance = selected_sprite.global_position.distance_to(zone.global_position)
#				if distance < shortest_dist:
#					shortest_dist = distance
#					nearest_zone = zone
#
#			if nearest_zone:
#				selected_sprite.global_position = nearest_zone.global_position
#			else:
#				# return home command
#				########################################
#				#lowkey might want to change this to return to last position me thinks idk
#				selected_sprite.global_position = original_positions[selected_sprite]
#			selected_sprite = null
