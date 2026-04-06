extends Control

@onready var pc_number_input = %PCNumberInput


func _on_assign_btn_pressed() -> void:
	var res = PcNumber.new()
	res.pc_number = pc_number_input.value
	ResourceSaver.save(res,"user://pc_number.res")
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	
