extends Control


func _on_connect_btn_pressed() -> void:
	Global.server_ip = %ServerIpInput.text.strip_edges()
	get_tree().change_scene_to_file("res://scenes/login.tscn")
