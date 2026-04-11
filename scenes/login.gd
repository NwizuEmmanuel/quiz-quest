extends Control

@onready var user_input = %UsernameInput
@onready var pass_input = %PasswordInput
@onready var accept_dialog = $AcceptDialog
@onready var quiz_service = $QuizService # The script above

func _on_login_button_pressed():
	var u = user_input.text
	var p = pass_input.text
	quiz_service.login_student(u, p)

# Connected via Signal in the Godot Editor
func _on_quiz_service_login_completed(success, data):
	if success:
		print("Welcome, ", data.name)
		# Save student_id for later use in results
		Global.student_id = data.student_id
		get_tree().change_scene_to_file("res://scenes/start_game.tscn")
	else:
		accept_dialog.dialog_text = "Invalid username or password."
		accept_dialog.popup_centered()
