extends Node

signal aichips_changed(amount: int)
signal aichips_per_click_changed(amount: int)
signal aichips_per_second_changed(amount: int)

var ai_name: String = "AI"

var aichips: int = 0:
	set(value):
		aichips = value
		aichips_changed.emit(aichips)

var aiChipsPerClick: int = 1:
	set(value):
		aiChipsPerClick = value
		aichips_per_click_changed.emit(aiChipsPerClick)

var aiChipsPerSecond: int = 0:
	set(value):
		aiChipsPerSecond = value
		aichips_per_second_changed.emit(aiChipsPerSecond)

var _second_timer: float = 0.0

func _process(delta: float) -> void:
	if aiChipsPerSecond <= 0:
		return
	_second_timer += delta
	while _second_timer >= 1.0:
		_second_timer -= 1.0
		aichips += aiChipsPerSecond
