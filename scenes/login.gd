extends Control

@onready var user_input: LineEdit = %UsernameInput
@onready var pass_input: LineEdit = %PasswordInput
@onready var accept_dialog = $AcceptDialog
@onready var quiz_service = $QuizService # The script above
@onready var code_input:LineEdit = $%QuizcodeLineEdit

func _on_login_button_pressed():
	var u = user_input.text.strip_edges()
	var p = pass_input.text.strip_edges()
	var c = code_input.text.strip_edges()
	
	Global.quiz_code = c
	quiz_service.login_student(u, p, c)

# Connected via Signal in the Godot Editor
func _on_quiz_service_login_completed(success, data):
	if success:
		print("Welcome, ", data.name)
		# Save student_id for later use in results
		Global.student_id = data.student_id
		Global.start_time = data.start_time
		Global.end_time = data.end_time
		get_tree().change_scene_to_file("res://scenes/start_game.tscn")
	else:
		accept_dialog.dialog_text = "Invalid username, password or quiz code.\nOr check Server IP"
		accept_dialog.popup_centered()


func _on_show_password_btn_pressed() -> void:
	pass_input.secret = !pass_input.secret


func _on_change_server_ip_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ConnectToServer.tscn")
