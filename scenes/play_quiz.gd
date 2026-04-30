extends Control

# Quiz Data
var quiz_data: Dictionary
var quiz_items: Array = []
var quiz_history: Array = [] 

var current_quiz_index: int = 0
var total_questions: int = 0
var score: int = 0
var defeated_boss: bool = false
var boss_life: float = 100.0
var player_life: float = 100.0
var is_turn_processing: bool = false

@onready var quiz_service = $QuizService 

func _ready() -> void:
	$playquizbgm.play()
	
	# Load data from Global
	if Global.current_quiz_package.has("questions"):
		quiz_data = Global.current_quiz_package
		quiz_items = quiz_data.questions
		total_questions = quiz_items.size()
	
	%PlayerSprite2D.play("idle")
	%BossSprite2D.play("idle")
	
	if total_questions > 0:
		run_quiz()
	else:
		push_error("No questions found in quiz_package!")

func _process(_delta: float) -> void:
	%TimerLabel.text = str(round(%QuizTimer.time_left))
	%ScoreLabel.text = "%d/%d" % [score, total_questions]
	Global.score = score
	Global.total_questions = total_questions
	Global.defeated_boss = defeated_boss

func run_quiz():
	# Check if we finished the quiz
	if current_quiz_index >= total_questions:
		%QuizTimer.stop()
		if boss_life <= 0: 
			defeated_boss = true
		save_to_server()
		return
	
	is_turn_processing = false # Reset flag for the new question
	set_input_enabled(true)
	
	var quiz = quiz_items[current_quiz_index]
	var time_limit = quiz.get("time_limit", 30)
	
	%QuestionText.text = str(current_quiz_index + 1) + ": " + quiz.question
	%QuizTimer.start(time_limit)
	
	if quiz.type == "Identification":
		%IdentificationAnswerBox.show()
		%MultipleChoiceOptionsBox.hide()
		%IdentificationAnswerLineEdit.grab_focus()
	else:
		%IdentificationAnswerBox.hide()
		%MultipleChoiceOptionsBox.show()
		# Use .get() or array size checks to avoid out-of-bounds errors
		%OptionA.text = quiz.options[0] if quiz.options.size() > 0 else ""
		%OptionB.text = quiz.options[1] if quiz.options.size() > 1 else ""
		%OptionC.text = quiz.options[2] if quiz.options.size() > 2 else ""
		%OptionD.text = quiz.options[3] if quiz.options.size() > 3 else ""

## Damage Calculation
func deal_damage() -> float:
	# Prevent division by zero if quiz is empty
	var base_dmg = 100.0 / max(1, total_questions)
	return base_dmg + (%QuizTimer.time_left * 0.5) # Bonus for speed

func deal_boss_damage():
	$playerfx.play()
	boss_life = max(0, boss_life - deal_damage())
	%BossLifeBar.value = boss_life
	await attack_boss()

func deal_player_damage():
	$bossfx.play()
	player_life = max(0, player_life - 10.0) # Static penalty or logic
	%PlayerLifeBar.value = player_life
	await attack_player()

## Answer Checking Logic
func check_identification_answer(ans: String) -> void:
	if is_turn_processing: return
	is_turn_processing = true
	%QuizTimer.stop()
	set_input_enabled(false)
	
	var quiz = quiz_items[current_quiz_index]
	var is_correct = (ans.strip_edges().to_upper() == str(quiz.answer).to_upper())

	quiz_history.append({
		"question": quiz.question,
		"student_answer": ans if ans != "" else "[No Answer]",
		"correct_answer": quiz.answer,
		"status": "Correct" if is_correct else "Failed"
	})
	
	if is_correct:
		score += 1
		await show_player_mssg("CORRECT")
		await deal_boss_damage()
	else:
		await show_player_mssg("WRONG")
		await deal_player_damage()

	current_quiz_index += 1
	run_quiz()

func check_multiple_choice_answer(ans_text: String) -> void:
	if is_turn_processing: return
	is_turn_processing = true
	%QuizTimer.stop()
	set_input_enabled(false)
	
	var quiz = quiz_items[current_quiz_index]
	var is_correct = (ans_text == str(quiz.answer))

	quiz_history.append({
		"question": quiz.question,
		"student_answer": ans_text,
		"correct_answer": quiz.answer,
		"status": "Correct" if is_correct else "Failed"
	})
	
	if is_correct:
		score += 1
		await show_player_mssg("CORRECT")
		await deal_boss_damage()
	else:
		await show_player_mssg("WRONG")
		await deal_player_damage()

	current_quiz_index += 1
	run_quiz()

func _on_quiz_timer_timeout() -> void:
	if is_turn_processing: return
	is_turn_processing = true
	set_input_enabled(false)
	
	var quiz = quiz_items[current_quiz_index]
	quiz_history.append({
		"question": quiz.question,
		"student_answer": "[TIME OUT]",
		"correct_answer": quiz.answer,
		"status": "Failed"
	})

	await show_player_mssg("TIME'S UP!")
	await deal_player_damage()

	current_quiz_index += 1
	await get_tree().create_timer(0.5).timeout
	run_quiz()

## Animation Helpers
func attack_boss():
	%PlayerSprite2D.play("attack")
	await %PlayerSprite2D.animation_finished
	$characterhit.play()
	if boss_life <= 0:
		%BossSprite2D.play("death")
		$characterdeathfx.play()
		await %BossSprite2D.animation_finished
	else:
		%BossSprite2D.play("hurt")
		await %BossSprite2D.animation_finished
		%BossSprite2D.play("idle")
	%PlayerSprite2D.play("idle")
	
func attack_player():
	%BossSprite2D.play("attack")
	await %BossSprite2D.animation_finished
	$characterhit.play()
	if player_life <= 0:
		%PlayerSprite2D.play("death")
		$characterdeathfx.play()
		await %PlayerSprite2D.animation_finished
	else:
		%PlayerSprite2D.play("hurt")
		await %PlayerSprite2D.animation_finished
		%PlayerSprite2D.play("idle")
	%BossSprite2D.play("idle")

func show_player_mssg(mssg: String):
	%PlayerMssg.text = mssg
	await get_tree().create_timer(1.0).timeout
	%PlayerMssg.text = ""

func set_input_enabled(enabled: bool):
	%OptionA.disabled = !enabled
	%OptionB.disabled = !enabled
	%OptionC.disabled = !enabled
	%OptionD.disabled = !enabled
	%IdentificationAnswerLineEdit.editable = enabled
	if not enabled:
		%IdentificationAnswerLineEdit.release_focus()

func save_to_server():
	var quiz_title = quiz_data.get("title", "Untitled Quiz")
	var def_boss = "yes" if defeated_boss else "no"
	var code = Global.quiz_code
	var start_time = Global.start_time
	var end_time = Global.end_time
	
	quiz_service.submit_result(
		Global.student_id, 
		quiz_title, 
		score, 
		total_questions, 
		def_boss, 
		quiz_history,
		code,
		start_time,
		end_time
	)
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://scenes/quiz_result.tscn")

# Signals
func _on_option_a_pressed(): check_multiple_choice_answer(%OptionA.text)
func _on_option_b_pressed(): check_multiple_choice_answer(%OptionB.text)
func _on_option_c_pressed(): check_multiple_choice_answer(%OptionC.text)
func _on_option_d_pressed(): check_multiple_choice_answer(%OptionD.text)

func _on_identification_answer_line_edit_text_submitted(new_text: String) -> void:
	check_identification_answer(new_text)
	%IdentificationAnswerLineEdit.clear()

func _on_quit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/quiz_result.tscn")
