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
var is_turn_processing = false

const SPEED = 400.0

func _ready() -> void:
	$playquizbgm.play()
	if load(Global.quiz_path) != null:
		questions = load(Global.quiz_path) as Questions
		quiz_items = questions.questions
		
	total_questions = quiz_items.size()
	
	%PlayerSprite2D.play("idle")
	%BossSprite2D.play("idle")
	
	run_quiz()


func _process(_delta: float) -> void: 
	%TimerLabel.text = "TIME: %d" % int(%QuizTimer.time_left)
	%ScoreLabel.text = "SCORE: %d/%d" % [score, total_questions]
	
	if %QuizTimer.time_left == 0:
		deal_player_damage()
		show_player_mssg("TOO LATE")
		current_quiz_index += 1
		run_quiz()

func track_student():
	var path = "user://track_students.res"
	var tracker: TrackStudents
	
	# 1. Load the existing file if it exists, otherwise create a new one
	if FileAccess.file_exists(path):
		tracker = load(path) as TrackStudents
	else:
		tracker = TrackStudents.new()
	
	# 2. Load the current student's performance
	var current_stats = load("user://player_stats.res")
	
	if current_stats != null:
		# 3. Add the new stats to the existing list
		tracker.players.append(current_stats)
		
		# 4. Save the ENTIRE updated tracker back to the file
		var error = ResourceSaver.save(tracker, path)
		
		if error == OK:
			print("Student tracking updated successfully.")
		else:
			print("Failed to save tracker. Error: ", error)
	else:
		print("Error: player_stats.res not found. Nothing to track.")

func save_data():
	Global.score = score
	Global.total_questions = total_questions
	Global.defeated_boss = defeated_boss
	DirAccess.make_dir_recursive_absolute("user://quiz_results/")
	var quiz_title = Global.quiz_title
	var username = Global.username
	var player_stats = load("user://player_stats.res") as PlayerStats
	player_stats.score = score
	player_stats.total_questions = total_questions
	player_stats.defeated_boss = defeated_boss
	player_stats.username = username
	player_stats.password = Global.password
	player_stats.quiz_title = quiz_title
	player_stats.schedule_date = Global.quiz_schedule_date
	player_stats.schedule_time_from = Global.quiz_schedule_time_from
	player_stats.schedule_time_to = Global.quiz_schedule_time_to
	player_stats.date_added = Time.get_datetime_string_from_system(false,true)
	ResourceSaver.save(player_stats, "user://quiz_results/"+username+".res")
	ResourceSaver.save(player_stats, "user://player_stats.res")
	track_student()

func deal_damage() -> float:
	if total_questions <= 0:
		return 0
	var time_left = %QuizTimer.time_left
	var damage_point = 100.0 / max(1, total_questions - GRACE_POINT)
	return damage_point + time_left

func deal_boss_damage() -> void:
	$playerfx.play()
	boss_life = max(0, boss_life - deal_damage())
	%BossLifeBar.value = boss_life
	await attack_boss()


func deal_player_damage() -> void:
	$bossfx.play()
	player_life = max(0, player_life - deal_damage())
	%PlayerLifeBar.value = player_life
	await attack_player()

func run_quiz():
	if  current_quiz_index >= total_questions:
		%QuizTimer.stop()
		# check if boss is defeated
		if boss_life == 0:
			defeated_boss = true
		save_data()
		print(Global.defeated_boss)
		
		if is_inside_tree():
			get_tree().change_scene_to_file("res://scenes/quiz_result.tscn")
		return
	
	var quiz = quiz_items[current_quiz_index]
	%QuizTimer.start(quiz.time_limit)
	
	%QuestionText.text = str(current_quiz_index+1)+": "+quiz.text
	if quiz.question_type == QuestionItem.QuestionType.IDENTIFICATION:
		%IdentificationAnswerBox.show()
		%IdentificationAnswerLineEdit.grab_focus()
		%MultipleChoiceOptionsBox.hide()
	elif quiz.question_type == QuestionItem.QuestionType.MULTIPLE_CHOICE:
		%IdentificationAnswerBox.hide()
		%MultipleChoiceOptionsBox.show()
		%OptionA.text = "A: "+quiz.options[0]
		%OptionB.text = "B: "+quiz.options[1]
		%OptionC.text = "C: "+quiz.options[2]
		%OptionD.text = "D: "+quiz.options[3]

func show_player_mssg(mssg: String):
	%PlayerMssg.text = mssg
	await get_tree().create_timer(1.5).timeout
	%PlayerMssg.text = ""

func check_identification_answer(ans: String) -> void:
	if is_turn_processing:
		return
	
	is_turn_processing = true
	set_input_enabled(false)
	
	if current_quiz_index < total_questions:
		var quiz = quiz_items[current_quiz_index]

		if ans.to_upper() == quiz.correct_answer.to_upper():
			score += 1
			await deal_boss_damage()
			await show_player_mssg("CORRECT")
		else:
			await deal_player_damage()
			await show_player_mssg("WRONG")

	current_quiz_index += 1
	run_quiz()
	
	is_turn_processing = false
	set_input_enabled(true)

func check_multiple_choice_answer(ans: int) -> void:
	if is_turn_processing:
		return
	is_turn_processing = true
	set_input_enabled(false)
	
	if current_quiz_index < total_questions:
		var quiz = quiz_items[current_quiz_index]

		if ans == quiz.correct_option:
			score += 1
			await deal_boss_damage()
			await show_player_mssg("CORRECT")
		else:
			await deal_player_damage()
			await show_player_mssg("WRONG")

	current_quiz_index += 1
	run_quiz()
	
	is_turn_processing = false
	set_input_enabled(true)
	
func _on_option_a_pressed() -> void:
	check_multiple_choice_answer(1)

func _on_option_b_pressed() -> void:
	check_multiple_choice_answer(2)

func _on_option_c_pressed() -> void:
	check_multiple_choice_answer(3)

func _on_option_d_pressed() -> void:
	check_multiple_choice_answer(4)

func _on_identification_answer_line_edit_text_submitted(new_text: String) -> void:
	await check_identification_answer(new_text.strip_edges())
	run_quiz()
	%IdentificationAnswerLineEdit.clear()

@onready var confirm_dialog = $ConfirmationDialog
func _on_button_pressed() -> void:
	confirm_dialog.dialog_text = "Do you want to stop this quiz?"
	confirm_dialog.popup_centered()


func _on_confirmation_dialog_confirmed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


## Player attacks from Left to Right
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

func _on_quiz_timer_timeout() -> void:
	if is_turn_processing:
		return

	is_turn_processing = true
	set_input_enabled(false)

	await deal_player_damage()
	await show_player_mssg("TOO LATE")

	current_quiz_index += 1
	run_quiz()

	is_turn_processing = false
	set_input_enabled(true)

func set_input_enabled(enabled: bool):
	%OptionA.disabled = !enabled
	%OptionB.disabled = !enabled
	%OptionC.disabled = !enabled
	%OptionD.disabled = !enabled
	%IdentificationAnswerLineEdit.editable = enabled
