extends Control

@onready var file_dialog = $FileDialog
@onready var pc_number_label: Label = %PcNumberLabel

func _ready() -> void:
	$Gamestartbgm.play()
	var pc_number = load("user://pc_number.res")
	if pc_number == null:
		get_tree().change_scene_to_file("res://scenes/assign_pc_number.tscn") 
	else:
		pc_number_label.text = "PC Number: %s" % pc_number.pc_number

	

	
func _on_create_quiz_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/add_quiz.tscn") 

func _on_start_game_button_pressed() -> void:
	file_dialog.popup_centered()


func _on_exit_game_button_pressed() -> void:
	get_tree().quit()


func _on_view_players_stats_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/view_players_stats.tscn") 


func _on_view_results_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/view_stat.tscn")


func _on_file_dialog_file_selected(path: String) -> void:
	Global.quiz_path = path
	get_tree().change_scene_to_file("res://scenes/login.tscn")
