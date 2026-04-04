extends Node

@onready var item_list: ItemList = %ItemList
@onready var content_display: RichTextLabel = %RichTextLabel
@onready var folder_dialog: FileDialog = $ExportFolderDialog
@onready var accept_dialog: AcceptDialog = $AcceptDialog

# Set this to where your quiz or save files are stored
var folder_path: String = "user://quiz_results/"

func _ready():
	DirAccess.dir_exists_absolute(folder_path)
	# 1. Setup ItemList
	item_list.item_selected.connect(_on_item_selected)
	
	# 2. Load the files immediately
	load_file_list()

func load_file_list():
	var player_stats = load("user://player_stats.res") as PlayerStats
	change_all_usernames(player_stats.username)
	item_list.clear()
	
	var dir = DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			# Only add files (ignore folders and hidden system files)
			if not dir.current_is_dir() and not file_name.begins_with("."):
				# Add the filename to the list
				var index = item_list.add_item(file_name)
				# Store the full path in metadata for easy access later
				item_list.set_item_metadata(index, folder_path.path_join(file_name))
			
			file_name = dir.get_next()
	else:
		print("Error: Could not open directory: ", folder_path)

func _on_item_selected(index: int):
	var full_path = item_list.get_item_metadata(index)
	display_file_data(full_path)

func display_file_data(path: String):
	# Check if the file exists before trying to load
	if not FileAccess.file_exists(path):
		content_display.text = "Error: File not found."
		return
	
	# Load the resource natively
	var resource = ResourceLoader.load(path)
	
	# Verify it's the correct type of data
	if resource is PlayerStats:
		var data = resource as PlayerStats
		
		# Build the BBCode display
		var bbcode = "[b]Quiz Info:[/b] %s\n" % data.quiz_title
		bbcode += "-------------------\n"
		bbcode += "Player Id: %s\n" % data.id
		bbcode += "Date: %s\n" % data.date_added
		bbcode += "Player Name: %s\n" % data.username
		bbcode += "Quiz Title: %s\n" % data.quiz_title
		bbcode += "Score: [color=yellow]%d[/color]\n" % data.score
		bbcode += "Total questions: %s\n" % data.total_questions
		
		if data.defeated_boss_count > 0:
			bbcode += "Status: [color=green]Boss Defeated[/color]"
		else:
			bbcode += "Status: [color=red]Boss Active[/color]"
			
		content_display.text = bbcode
	else:
		content_display.text = "Error: File is not a valid GameData resource."


func _on_go_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/select_quiz.tscn")


func _on_export_button_pressed():
	# 1. Verify selection
	var selected_indices = item_list.get_selected_items()
	if selected_indices.is_empty():
		print("Please select a file from the list first.")
		return
	
	# 2. Open the folder picker
	folder_dialog.popup_centered()


# Connect the 'file_selected' signal from the FileDialog to this function
func _on_export_dialog_dir_selected(target_path: String):
	# 1. Get the source file path from ItemList metadata
	var index = item_list.get_selected_items()[0]
	var source_path = item_list.get_item_metadata(index)
	
	# 2. Get the original file name (e.g., "Math_Quiz.res")
	var file_name = source_path.get_file()
	var username = load(source_path).username
	if username == "nil":
		accept_dialog.dialog_text = "Enter your name"
		accept_dialog.popup_centered()
		return 
	
	# 3. Create the final destination path inside the new directory
	var final_destination = target_path.path_join(file_name)
	
	# 4. Perform the copy
	var err = DirAccess.copy_absolute(source_path, final_destination)
	
	if err == OK:
		print("File successfully exported to: ", final_destination)
		accept_dialog.dialog_text = "File successfully exported to: "+ final_destination
		accept_dialog.popup_centered()
		# Optional: Open the folder in your Ubuntu file manager (Nautilus)
		# OS.shell_open(target_dir_path)
	else:
		print("Export failed. Error code: ", err)
		accept_dialog.dialog_text = "Export failed. Error code: "+ err
		accept_dialog.popup_centered()

func change_all_usernames(new_name: String):
	var dir = DirAccess.open(folder_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			# Only process Godot resource files
			if not dir.current_is_dir() and file_name.ends_with(".res"):
				var file_path = folder_path + file_name
				update_single_file(file_path, new_name)
			
			file_name = dir.get_next()
		print("All usernames updated to: ", new_name)
	else:
		print("Error: Could not open directory.")


func update_single_file(path: String, new_name: String):
	# 1. Load the existing resource
	var result = ResourceLoader.load(path) as PlayerStats
	
	if result:
		# 2. Update the username property
		result.username = new_name
		
		# 3. Save it back to the exact same path
		var error = ResourceSaver.save(result, path)
		
		if error != OK:
			print("Failed to save updated name for: ", path)

func _on_save_button_pressed() -> void:
	var new_name = %YourNameInput.text
	var player_stats = load("user://player_stats.res") as PlayerStats
	player_stats.username = new_name
	ResourceSaver.save(player_stats,"user://player_stats.res")
	change_all_usernames(new_name)
	accept_dialog.dialog_text = "All result have been updated."
	accept_dialog.popup_centered()
	load_file_list()
