extends Control

@export var cost: int = 25
@export var purchase_sound: AudioStreamPlayer
@export var button_path: NodePath = ^"Upgrade-template/Button"
@export var grey_out_when_broke: bool = true

var _button: Button
var _bought: bool = false
var _regex := RegEx.create_from_string("\\bAI\\b")


func _ready() -> void:
	_button = get_node_or_null(button_path) as Button
	_button.pressed.connect(_on_button_pressed)
	globalvars.aichips_changed.connect(_refresh)
	_refresh(globalvars.aichips)


func _on_button_pressed() -> void:
	if _bought or globalvars.aichips < cost:
		return

	_bought = true
	globalvars.aichips -= cost
	globalvars.ai_name = "SI"
	$"../../../../labels/Timer".start()
	$"../../../../labels/text".show()
	$"../../../../labels/Photo".show()
	_replace_in_labels(get_tree().root)
	_button.disabled = true

	if purchase_sound != null:
		purchase_sound.play()


func _refresh(amount: int) -> void:
	if _bought:
		_button.disabled = true
	elif grey_out_when_broke:
		_button.disabled = amount < cost


func _replace_in_labels(node: Node) -> void:
	if node is Label:
		var l := node as Label
		l.text = _regex.sub(l.text, "SI", true)
	for c in node.get_children():
		_replace_in_labels(c)


func _on_timer_timeout() -> void:
	$"../../../../labels/text".hide()
	$"../../../../labels/Photo".hide()
