extends RichTextLabel

func _ready() -> void:
	visible_ratio = 0.0
	var tween = create_tween()
	tween.tween_property(self, "visible_ratio", 1.0, 4.0)
	$"../Button".show()
