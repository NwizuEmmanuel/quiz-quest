extends Control

# Data is now pulled from Global variables set during play_quiz.gd
@onready var score = Global.score
@onready var total_questions = Global.total_questions
@onready var defeated_boss = Global.defeated_boss
@onready var quiz_title = Global.current_quiz_package.get("title", "Quiz")

func _ready() -> void:
	$quizresultbgm.play()
	show_result()

func show_result():
	var result_text = "[center][b]QUIZ COMPLETED[/b][/center]\n\n"
	result_text += "QUIZ: %s\n" % quiz_title
	result_text += "SCORE: %d/%d\n" % [score, total_questions]
	
	# Calculate percentage for display
	var percentage = (float(score) / float(total_questions)) * 100
	result_text += "PERCENTAGE: %.2f%%\n" % percentage
	
	if defeated_boss:
		result_text += "[color=green]STATUS: DEFEATED THE BOSS![/color]"
	else:
		result_text += "[color=red]STATUS: THE BOSS ESCAPED...[/color]"
	
	%ResultRichTextLabel.text = result_text


func _on_replay_quiz_btn_pressed() -> void:
	Global.score = 0
	Global.defeated_boss = false
	get_tree().change_scene_to_file("res://scenes/play_quiz.tscn")


func _on_exit_quiz_btn_pressed() -> void:
	get_tree().quit()
