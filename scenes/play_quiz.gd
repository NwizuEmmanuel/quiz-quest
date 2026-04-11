extends Control

# Quiz Data (Now populated via API)
var quiz_data: Dictionary
var quiz_items: Array = []

var current_quiz_index = 0
var total_questions = 0
var score = 0
var defeated_boss = false
var boss_life = 100.0
var player_life = 100.0
var is_turn_processing = false

@onready var quiz_service = $QuizService # Your HTTPRequest node

func show_player_mssg(mssg: String):
	%PlayerMssg.text = mssg
	await get_tree().create_timer(1.5).timeout
	%PlayerMssg.text = ""

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
func _ready() -> void:
	$playquizbgm.play()
	
	# 1. Load data from the Global variable populated by the API
	if Global.current_quiz_package.has("questions"):
		quiz_data = Global.current_quiz_package
		quiz_items = quiz_data.questions
		total_questions = quiz_items.size()
	
	%PlayerSprite2D.play("idle")
	%BossSprite2D.play("idle")
	
	run_quiz()

func _process(_delta: float) -> void:
	%ScoreLabel.text = "%d/%d" % [score, total_questions]
	Global.score = score
	Global.total_questions = total_questions
	Global.defeated_boss = defeated_boss

func run_quiz():
	if current_quiz_index >= total_questions:
		%QuizTimer.stop()
		if boss_life <= 0: defeated_boss = true
		
		# 2. Save data to Server instead of local Resource files
		save_to_server()
		return
	
	var quiz = quiz_items[current_quiz_index]
	
	# Use a default time limit (e.g., 30s) if not specified in JSON
	var time_limit = quiz.get("time_limit", 30)
	%QuizTimer.start(time_limit)
	
	%QuestionText.text = str(current_quiz_index + 1) + ": " + quiz.question
	
	# Handle UI switching based on JSON "type"
	if quiz.type == "Identification":
		%IdentificationAnswerBox.show()
		%MultipleChoiceOptionsBox.hide()
		%IdentificationAnswerLineEdit.grab_focus()
	else:
		%IdentificationAnswerBox.hide()
		%MultipleChoiceOptionsBox.show()
		%OptionA.text = quiz.options[0]
		%OptionB.text = quiz.options[1]
		%OptionC.text = quiz.options[2]
		%OptionD.text = quiz.options[3]

func save_to_server():
	# Use .get() to provide a fallback title if 'title' is missing
	var quiz_title = quiz_data.get("title", "Untitled Quiz")

	# Debug: Print the data to see what the server actually sent
	print("Saving results for quiz: ", quiz_title)
	print("Quiz Data content: ", quiz_data)

	# Call the API
	quiz_service.submit_result(
		Global.student_id, 
		quiz_title, 
		score, 
		total_questions
	)

	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/quiz_result.tscn")

func check_identification_answer(ans: String) -> void:
	if is_turn_processing: return
	is_turn_processing = true
	set_input_enabled(false)
	
	var quiz = quiz_items[current_quiz_index]
	# Check string answer
	if ans.to_upper() == str(quiz.answer).to_upper():
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

func check_multiple_choice_answer(ans_text: String) -> void:
	if is_turn_processing: return
	is_turn_processing = true
	set_input_enabled(false)
	
	var quiz = quiz_items[current_quiz_index]
	# In our JSON, 'answer' is the actual text of the correct option
	if ans_text == str(quiz.answer):
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

# --- Button Logic Updated for Text-based Comparison ---
func _on_option_a_pressed(): check_multiple_choice_answer(%OptionA.text)
func _on_option_b_pressed(): check_multiple_choice_answer(%OptionB.text)
func _on_option_c_pressed(): check_multiple_choice_answer(%OptionC.text)
func _on_option_d_pressed(): check_multiple_choice_answer(%OptionD.text)

# --- Damage & Animations (Keep as is, but simplified) ---
func deal_damage() -> float:
	return (100.0 / max(1, total_questions)) + %QuizTimer.time_left

func deal_boss_damage():
	$playerfx.play()
	boss_life = max(0, boss_life - deal_damage())
	%BossLifeBar.value = boss_life
	await attack_boss()

func deal_player_damage():
	$bossfx.play()
	player_life = max(0, player_life - deal_damage())
	%PlayerLifeBar.value = player_life
	await attack_player()

func set_input_enabled(enabled: bool):
	%OptionA.disabled = !enabled
	%OptionB.disabled = !enabled
	%OptionC.disabled = !enabled
	%OptionD.disabled = !enabled
	%IdentificationAnswerLineEdit.editable = enabled
	if enabled: %IdentificationAnswerLineEdit.clear()
