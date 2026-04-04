extends Resource

class_name Questions

@export var title: String
@export var questions: Array[QuestionItem]
@export var participants: Array[Student] = []
@export var schedule_time_from: String
@export var schedule_time_to: String
@export var schedule_date: String
