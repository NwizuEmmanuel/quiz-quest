extends Control

var quiz_items = load(QuizData.quiz_path) as Questions
var score = QuizData.score
var total_questions = QuizData.total_questions
var defeated_boss = QuizData.defeated_boss
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	show_result()

func show_result():
	var result_text = "SCORE: %d/%d\n" % [score,total_questions]
	if defeated_boss:
		result_text += "DEFEATED THE BOSS"
		#$ConfirmationDialog.title = "VICTORY"
		#$ConfirmationDialog.dialog_text = "You defeated the boss! As your reward you can retake the quiz. Your choice?"
		#$ConfirmationDialog.popup_centered()
	else:
		result_text += "YOU LOSS!"
	%ResultRichTextLabel.text = result_text

func _on_go_home_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func restart_quiz() -> void:
	QuizData.score = 0
	QuizData.defeated_boss = false
	QuizData.failed_questions.clear()
	get_tree().change_scene_to_file("res://scenes/play_quiz/play_quiz.tscn")


func _on_confirmation_dialog_confirmed() -> void:
	restart_quiz()
