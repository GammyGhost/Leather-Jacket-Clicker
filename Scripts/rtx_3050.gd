extends Control

@export var cost: int = 1000
@export var per_click_gain: int = 10
@export var per_click_label: Label
@export var purchase_sound: AudioStreamPlayer
@export var button_path: NodePath = ^"Upgrade-template/Button"
@export var grey_out_when_broke: bool = true

var _button: Button


func _ready() -> void:
	globalvars.aichips_per_click_changed.connect(_update_per_click_label)
	_update_per_click_label(globalvars.aiChipsPerClick)
	_button = get_node_or_null(button_path) as Button
	_button.pressed.connect(_on_button_pressed)
	globalvars.aichips_changed.connect(_refresh)
	_refresh(globalvars.aichips)


func _on_button_pressed() -> void:
	if globalvars.aichips < cost:
		return

	globalvars.aichips -= cost
	globalvars.aiChipsPerClick += per_click_gain

	if purchase_sound != null:
		purchase_sound.play()


func _update_per_click_label(amount: int) -> void:
	if per_click_label != null:
		per_click_label.text = "%s CHIPS PER SECOND : %d" % [globalvars.ai_name, amount]


func _refresh(amount: int) -> void:
	if grey_out_when_broke:
		_button.disabled = amount < cost
