extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_quiz_list()


func update_quiz_list():
	var path = "user://play_quizzes"
	%QuizItemList.clear()
	
	if DirAccess.dir_exists_absolute(path):
		var dir = DirAccess.open(path)
		dir.list_dir_begin()
		
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".res"):
				var idx = %QuizItemList.add_item(file_name.get_basename())
				
				var full_path = path.path_join(file_name)
				%QuizItemList.set_item_metadata(idx, full_path)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("Quiz directory does not exist.") 

func _on_add_quiz_button_pressed() -> void:
	%FileDialog.popup_centered()

func show_accept_dialog(title: String, dialog_text: String):
	%AcceptDialog.title = title
	%AcceptDialog.dialog_text = dialog_text
	%AcceptDialog.popup_centered()

func _on_file_dialog_file_selected(path: String) -> void:
	var destination_dir = "user://play_quizzes/"
	
	if not DirAccess.dir_exists_absolute(destination_dir):
		DirAccess.make_dir_absolute(destination_dir)
	
	var file_name = path.get_file()
	var final_destination = destination_dir.path_join(file_name)
	
	if FileAccess.file_exists(final_destination):
		show_accept_dialog("DUPLICATE", "THIS QUIZ ALREADY EXISTS")
		return
		
	var error = DirAccess.copy_absolute(path,final_destination)
	
	if error == OK:
		show_accept_dialog("SUCCESS", "QUIZ ADDED SUCCESSFULLY")
	else :
		show_accept_dialog("ERROR", "FAILED TO COPY FILE: " + str(error))
	update_quiz_list() 


func _on_go_to_hub_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _on_play_button_pressed() -> void:
	if %QuizItemList.is_anything_selected():
		var selected_items = %QuizItemList.get_selected_items()
		var index = selected_items[0]
		QuizData.quiz_title = %QuizItemList.get_item_text(index)
		QuizData.quiz_path = %QuizItemList.get_item_metadata(index)
		
		var player_stats = load("user://data/player_stats.res") as PlayerStats
		DirAccess.make_dir_recursive_absolute("user://data/")
		if player_stats == null:
			player_stats = PlayerStats.new()
			ResourceSaver.save(player_stats, "user://data/player_stats.res")
		if player_stats.username == "":
			get_tree().change_scene_to_file("res://scenes/create_username/create_username.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/play_quiz/play_quiz.tscn")
	else:
		show_accept_dialog("WARNING", "SELECT A QUIZ TO PLAY")


func _on_delete_button_pressed() -> void:
	var selected_items = %QuizItemList.get_selected_items()
	if selected_items.size() > 0:
		var index = selected_items[0]
		var file_to_delete = %QuizItemList.get_item_metadata(index)
		var error = DirAccess.remove_absolute(file_to_delete)
		if error == OK:
			%QuizItemList.remove_item(index)
			show_accept_dialog("DELETED", "THE QUIZ HAS BEEN REMOVED.")
		else:
			show_accept_dialog("ERROR", "COULD NOT DELETE FILE. ERROR: " + str(error))
	else:
		show_accept_dialog("SELECT", "PLEASE SELECT A QUIZ TO DELETE FIRST.") 


func _on_view_results_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/view_stats/view_stat.tscn")
