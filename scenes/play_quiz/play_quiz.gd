extends Control

var current_quiz_index = 0
var questions: Questions
var quiz_items: Array[QuestionItem]
var total_questions = 0
var score = 0
var GRACE_POINT = 0.5
var boss_life = 100.0
var player_life = 100.0
var defeated_boss = false
var identification_answer = ""
var multiple_choice_answer = 0

const SPEED = 400.0


func _ready() -> void:
	if load(QuizData.quiz_path) != null:
		questions = load(QuizData.quiz_path) as Questions
		quiz_items = questions.questions
	total_questions = quiz_items.size()
	run_quiz()


func _process(_delta: float) -> void: 
	%TimerLabel.text = "TIME: %d" % int(%QuizTimer.time_left)
	%ScoreLabel.text = "SCORE: %d/%d" % [score, total_questions]
	if %QuizTimer.time_left == 0:
		deal_player_damage()
		show_player_mssg("TOO LATE")
		current_quiz_index += 1
		run_quiz()


func save_data():
	QuizData.score = score
	QuizData.total_questions = total_questions
	QuizData.defeated_boss = defeated_boss
	DirAccess.make_dir_recursive_absolute("user://quiz_results")
	var quiz_title = QuizData.quiz_title
	var player_stats = load("user://data/player_stats.res") as PlayerStats
	player_stats.score = score
	player_stats.total_questions = total_questions
	player_stats.quiz_frequency += 1
	if defeated_boss:
		player_stats.defeated_boss_count += 1
	player_stats.quiz_title = quiz_title
	ResourceSaver.save(player_stats, "user://quiz_results/"+quiz_title+".res")

func deal_damage() -> float:
	if total_questions <= 0:
		return 0
	#if %QuizTimer.is_stopped():
		#return 0
	var time_left = %QuizTimer.time_left
	var damage_point = 100.0 / max(1, total_questions - GRACE_POINT)
	return damage_point + time_left

func deal_boss_damage():
	boss_life = max(0, boss_life - deal_damage())
	%BossLifeBar.value = boss_life
	attack_boss()


func deal_player_damage():
	player_life = max(0, player_life - deal_damage())
	%PlayerLifeBar.value = player_life
	attack_player()

func run_quiz():
	if  current_quiz_index >= total_questions:
		# check if boss is defeated
		if boss_life == 0:
			defeated_boss = true
		save_data()
		print(QuizData.defeated_boss)
		get_tree().change_scene_to_file("res://scenes/quiz_result/quiz_result.tscn")
		return
	
	var quiz = quiz_items[current_quiz_index]
	%QuizTimer.start(quiz.time_limit)
	
	%QuestionText.text = str(current_quiz_index+1)+": "+quiz.text
	if quiz.question_type == QuestionItem.QuestionType.IDENTIFICATION:
		%OptionsTextBox.hide()
		%IdentificationAnswerBox.show()
		%IdentificationAnswerLineEdit.grab_focus()
		%MultipleChoiceOptionsBox.hide()
	elif quiz.question_type == QuestionItem.QuestionType.MULTIPLE_CHOICE:
		%IdentificationAnswerBox.hide()
		%OptionsTextBox.show()
		%MultipleChoiceOptionsBox.show()
		%OptionsText1.text = "A: "+quiz.options[0]
		%OptionsText2.text = "B: "+quiz.options[1]
		%OptionsText3.text = "C: "+quiz.options[2]
		%OptionsText4.text = "D: "+quiz.options[3]


func show_player_mssg(mssg: String):
	%PlayerMssg.text = mssg
	await get_tree().create_timer(1.5).timeout
	%PlayerMssg.text = ""


func check_identification_answer(ans: String):
	if current_quiz_index < total_questions:
		var quiz = quiz_items[current_quiz_index]
		if ans.to_upper() == quiz.correct_answer.to_upper():
			score += 1
			deal_boss_damage()
			show_player_mssg("CORRECT")
		else:
			deal_player_damage()
			show_player_mssg("WRONG")
	current_quiz_index += 1

func check_multiple_choice_answer(ans:int):
	if current_quiz_index < total_questions:
		var quiz = quiz_items[current_quiz_index]
		if ans == quiz.correct_option:
			score += 1
			deal_boss_damage()
			show_player_mssg("CORRECT")
		else:
			deal_player_damage()
			show_player_mssg("WRONG")
	current_quiz_index += 1
	
	
func _on_option_a_pressed() -> void:
	check_multiple_choice_answer(1)
	run_quiz()


func _on_option_b_pressed() -> void:
	check_multiple_choice_answer(2)
	run_quiz()


func _on_option_c_pressed() -> void:
	check_multiple_choice_answer(3)
	run_quiz()


func _on_option_d_pressed() -> void:
	check_multiple_choice_answer(4)
	run_quiz()


func _on_identification_answer_line_edit_text_submitted(new_text: String) -> void:
	check_identification_answer(new_text.strip_edges())
	run_quiz()
	%IdentificationAnswerLineEdit.clear()

@onready var confirm_dialog = $ConfirmationDialog
func _on_button_pressed() -> void:
	confirm_dialog.dialog_text = "Do you want to stop this quiz?"
	confirm_dialog.popup_centered()


func _on_confirmation_dialog_confirmed() -> void:
	get_tree().change_scene_to_file("res://scenes/select_quiz/select_quiz.tscn")

# Move distances
var ATTACK_DISTANCE = 900
const MOVE_TIME = 0.4 # How fast they slide forward/back
const WAIT_TIME = 0.5 # How long they stay at the impact point

## Player attacks from Left to Right
func attack_boss():
	var tween = create_tween()
	var start_pos = %PlayerSprite2D.position
	var target_pos = start_pos + Vector2(ATTACK_DISTANCE, 0)

	# 1. Slide Right (Forward)
	tween.tween_property(%PlayerSprite2D, "position", target_pos, MOVE_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. Pause for the "hit"
	tween.tween_interval(WAIT_TIME)

	# 3. Slide Left (Back)
	tween.tween_property(%PlayerSprite2D, "position", start_pos, MOVE_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	## Boss attacks from Right to Left
func attack_player():
	var tween = create_tween()
	var start_pos = %BossSprite2D.position
	# Note the MINUS sign to move left
	var target_pos = start_pos + Vector2(-ATTACK_DISTANCE, 0) 

	# 1. Slide Left (Forward)
	tween.tween_property(%BossSprite2D, "position", target_pos, MOVE_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. Pause
	tween.tween_interval(WAIT_TIME)

	# 3. Slide Right (Back)
	tween.tween_property(%BossSprite2D, "position", start_pos, MOVE_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
