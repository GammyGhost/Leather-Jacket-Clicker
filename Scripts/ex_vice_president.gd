extends Control

@export var cost: int = 999
@export var per_sec_gain: int = 10
@export var per_sec_label: Label
@export var purchase_sound: AudioStreamPlayer
@export var button_path: NodePath = ^"Upgrade-template/Button"
@export var grey_out_when_broke: bool = true

var _button: Button

func _ready() -> void:
	globalvars.aichips_per_second_changed.connect(_update_per_sec_label)
	_update_per_sec_label(globalvars.aiChipsPerSecond)
	
	_button = get_node_or_null(button_path) as Button
	if _button == null:
		var found := find_children("*", "Button", true, false)
		if not found.is_empty():
			_button = found[0] as Button
	
	if _button == null:
		push_warning("gtx_1080ti: couldn't find the Button")
		return

	_button.pressed.connect(_on_button_pressed)

	globalvars.aichips_changed.connect(_refresh)
	_refresh(globalvars.aichips)

func _on_button_pressed() -> void:
	if globalvars.aichips < cost:
		return
	
	globalvars.aichips -= cost
	globalvars.aiChipsPerSecond += per_sec_gain
	
	$"../../../../labels/Timer".start()
	$"../../../../labels/baddie".show()
	$"../../../../labels/RealBaddie".show()
	
	if purchase_sound != null:
		purchase_sound.play()

func _update_per_sec_label(amount: int) -> void:
	if per_sec_label != null:
		per_sec_label.text = "AI CHIPS PER SECOND : %d" % amount

func _refresh(amount: int) -> void:
	if grey_out_when_broke:
		_button.disabled = amount < cost


func _on_timer_timeout() -> void:
	$"../../../../labels/baddie".hide()
	$"../../../../labels/RealBaddie".hide()
