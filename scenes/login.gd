extends Control

@onready var password_input = %PasswordInput
@onready var username_input = %UsernameInput
@onready var accept_dialog = $AcceptDialog

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	delete_folder_recursive("user://quiz_results/")

func _on_show_password_btn_pressed() -> void:
	password_input.secret = !password_input.secret

func time_to_seconds(time_str: String) -> int:
	var parts = time_str.split(":")
	var h = parts[0].to_int()
	var m = parts[1].to_int()
	var s = parts[2].to_int()
	return (h * 3600) + (m * 60) + s

func is_time_in_range_complex(start_str: String, end_str: String) -> bool:
	var now_dict = Time.get_time_dict_from_system()
	var now_sec = (now_dict.hour * 3600) + (now_dict.minute * 60) + now_dict.second
	var start_sec = time_to_seconds(start_str)
	var end_sec = time_to_seconds(end_str)
	
	if start_sec <= end_sec:
		# Standard range (e.g. 9am to 10am)
		return now_sec >= start_sec and now_sec <= end_sec
	else:
		# Overnight range (e.g. 11pm to 1am)
		return now_sec >= start_sec or now_sec <= end_sec

func delete_folder_recursive(path: String):
	var dir = DirAccess.open(path)
	
	if dir:
		# 1. Start listing the files inside
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir():
				# If it's a sub-folder, call this function again (Recursion)
				delete_folder_recursive(path + "/" + file_name)
			else:
				# If it's a file, delete it
				dir.remove(file_name)
				print("Deleted file: ", file_name)
				
			file_name = dir.get_next()
		
		# 2. The folder is now empty, so we can delete the folder itself
		# Note: we need to go "up" one level or use the full path to remove it
		var upper_dir = DirAccess.open(path.get_base_dir())
		upper_dir.remove(path.get_file())
		print("Folder fully removed: ", path)
	else:
		print("Error: Could not open folder at ", path)

func show_dialog(mssg: String):
	accept_dialog.dialog_text = mssg
	accept_dialog.popup_centered()

func _on_login_btn_pressed() -> void:
	var input_user = username_input.text.strip_edges()
	var input_pass = password_input.text.strip_edges()
	
	# 1. Load Files & Setup
	var quiz_file = load(Global.quiz_path) as Questions
	var from = quiz_file.schedule_time_from
	var to = quiz_file.schedule_time_to
	
	# check user pc
	var pc_number_res = load("user://pc_number.res")
	for p in quiz_file.participants:
		if p.pc_number != pc_number_res.pc_number:
			show_dialog("Asses Denied: Unauthorized use of PC.")
			return
	
	# 2. Check Schedule First (Don't even look at users if time is wrong)
	if not is_time_in_range_complex(from, to):
		delete_folder_recursive("user://quiz_results/")
		show_dialog("Access Denied: Outside of scheduled time.")
		return # Stop here

	# 3. Find if the student exists in participants
	var current_student = null
	for p in quiz_file.participants:
		if p.username == input_user and p.password == input_pass:
			current_student = p
			break # Found them! Stop looking.

	if current_student == null:
		show_dialog("Access Denied: User not found or wrong password.")
		return

	# 4. Check Tracking (Has the student already played?)
	var tracker = load("user://track_students.res") as TrackStudents
	if tracker != null:
		for j in tracker.players:
			if j.username == input_user:
				# Compare specific quiz details to see if THIS specific one was taken
				if j.schedule_date == quiz_file.schedule_date and j.schedule_time_from == from:
					show_dialog("You have already taken this quiz.")
					return

	# 5. Success: Save to Global and Change Scene
	Global.username = input_user
	Global.password = input_pass
	Global.quiz_title = quiz_file.title
	Global.quiz_schedule_time_from = from
	Global.quiz_schedule_time_to = to
	Global.quiz_schedule_date = quiz_file.schedule_date
	
	get_tree().change_scene_to_file("res://scenes/play_quiz.tscn")


func _on_return_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
