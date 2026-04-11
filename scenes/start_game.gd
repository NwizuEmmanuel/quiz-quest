extends Control

@onready var quiz_service = $QuizService # Ensure you have the HTTPRequest node here

func _on_start_game_btn_pressed() -> void:
	# 1. First, we need to know WHICH quiz to take. 
	# Let's fetch the list of active schedules.
	quiz_service.get_active_schedules()

# This signal comes from the QuizService when it gets the list of quizzes
func _on_quiz_service_schedules_received(schedules: Array):
	if schedules.size() > 0:
		# 2. Pick the first active quiz and download its full content
		var first_quiz_id = schedules[0].id
		quiz_service.download_quiz(first_quiz_id)
	else:
		print("No active quizzes scheduled right now!")

# This signal triggers once the full JSON (questions + title) is downloaded
func _on_quiz_service_quiz_downloaded(data: Dictionary):
	# 3. Store the data in Global so the next scene can see it
	Global.current_quiz_package = data
	
	# 4. NOW change the scene
	get_tree().change_scene_to_file("res://scenes/play_quiz.tscn")

func _on_quiz_service_error_occurred(message):
	print("Error: ", message)
