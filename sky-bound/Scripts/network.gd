extends Control


func _on_server_pressed() -> void:
	NetworkConnection.start_server()


func _on_client_pressed() -> void:
	NetworkConnection.start_client()
	NetworkConnection.connected.connect(on_connected)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/menu.tscn")

func on_connected():
	get_tree().change_scene_to_file("res://Character/Scene/main.tscn")
