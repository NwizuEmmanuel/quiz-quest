extends Control

var quiz_items = load(Global.quiz_path) as Questions
var score = Global.score
var total_questions = Global.total_questions
var defeated_boss = Global.defeated_boss
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$quizresultbgm.play()
	show_result()

func show_result():
	var result_text = "SCORE: %d/%d\n" % [score,total_questions]
	if defeated_boss:
		result_text += "YOU BEAT THE BOSS!"
		#$ConfirmationDialog.title = "VICTORY"
		#$ConfirmationDialog.dialog_text = "You defeated the boss! As your reward you can retake the quiz. Your choice?"
		#$ConfirmationDialog.popup_centered()
	else:
		result_text += "YOU WERE DEFEATED!"
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
