extends Control

var quiz_items = load(Global.quiz_path) as Questions
var score = Global.score
var total_questions = Global.total_questions
var defeated_boss = Global.defeated_boss

var path = "user://quiz_results/" + Global.username + ".res"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$quizresultbgm.play()
	show_result()
	var result_file = load(path)
	var filename = Global.username +"_result.res"
	export_resource_to_downloads(result_file, filename)

func export_resource_to_downloads(resource_to_save: Resource, filename: String = "Student_Backup.res"):
	# 1. Get the path to the system's Downloads folder
	var downloads_path = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	
	# 2. Create the full path (e.g., C:/Users/Name/Downloads/Student_Backup.res)
	var full_path = downloads_path + "/" + filename
	
	# 3. Save the resource directly to that location
	var error = ResourceSaver.save(resource_to_save, full_path)
	
	if error == OK:
		print("Resource successfully exported to: ", full_path)
	else:
		print("Error: Could not export resource. Error code: ", error)

func show_result():
	var result_text = "[b]See your result file at Download folder[/b]\n"
	result_text += "SCORE: %d/%d\n" % [score,total_questions]
	if defeated_boss:
		result_text += "DEFEATED THE BOSS"
		#$ConfirmationDialog.title = "VICTORY"
		#$ConfirmationDialog.dialog_text = "You defeated the boss! As your reward you can retake the quiz. Your choice?"
		#$ConfirmationDialog.popup_centered()
	else:
		result_text += "YOU LOSS!"
	%ResultRichTextLabel.text = result_text

func _on_go_home_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func restart_quiz() -> void:
	Global.score = 0
	Global.defeated_boss = false
	Global.failed_questions.clear()
	get_tree().change_scene_to_file("res://scenes/play_quiz.tscn")


func _on_confirmation_dialog_confirmed() -> void:
	restart_quiz()
