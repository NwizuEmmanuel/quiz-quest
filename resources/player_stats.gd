extends Resource

class_name PlayerStats

func _init() -> void:
	id = generate_unique_id()

func generate_unique_id()->String:
	var hardware_id = OS.get_unique_id()
	var hashed_id = hardware_id.sha256_text().substr(0,12)
	return hashed_id

@export var id: String
@export var score: int = 0
@export var quiz_title: String = ""
@export var username: String = "Nil"
@export var quiz_frequency: int = 0
@export var defeated_boss_count: int = 0
@export var ip_address: String = ""
