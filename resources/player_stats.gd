extends Resource

class_name PlayerStats

func _init() -> void:
	date_added = get_datetime()

func get_datetime()->String:
	var time = Time.get_datetime_string_from_system(false,true)
	return time

@export var score: int = 0
@export var total_questions = 0
@export var quiz_title: String = ""
@export var username: String = ""
@export var password: String = ""
@export var defeated_boss: bool
@export var date_added:String
@export var schedule_date: String
@export var schedule_time_from: String
@export var schedule_time_to: String
