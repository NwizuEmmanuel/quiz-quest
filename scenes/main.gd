extends Control


func _on_create_quiz_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/add_quiz.tscn") 


func _on_start_game_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/select_quiz.tscn")


func _on_exit_game_button_pressed() -> void:
	get_tree().quit()


func _on_view_players_stats_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/view_players_stats.tscn") 


func _on_view_results_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/view_stat.tscn")
