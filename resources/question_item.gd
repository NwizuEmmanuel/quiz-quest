extends Resource
class_name QuestionItem

enum QuestionType {
	IDENTIFICATION,
	MULTIPLE_CHOICE
}

@export var text: String
@export var question_type: QuestionType
@export var options: Array[String] = []
@export var correct_option: int
@export var correct_answer: String
@export var time_limit: int
