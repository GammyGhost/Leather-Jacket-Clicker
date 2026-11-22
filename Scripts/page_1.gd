extends Control

@export var next_sound: AudioStreamPlayer

func _ready() -> void:
	$Button.hide()

func _on_timer_timeout() -> void:
	$Button.show()

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/page_2.tscn")
	next_sound.play()
