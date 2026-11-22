extends Area2D

@export var click_sound: AudioStreamPlayer
@export var speed: float = 300.0
@export var chips_label: Label
@export var per_click_label: Label
@export var walls_path: NodePath = ^"../Bg"
@export var bounce_sound_path: NodePath = ^"../bounce-music"
@export var step_size: float = 2.0
@export var debug_draw: bool = false
@export var click_shrink_px: float = 10.0
@export var click_anim_time: float = 0.15

var velocity: Vector2 = Vector2.ZERO
var _walls: Node
var _bounce_sound: AudioStreamPlayer
var _wall_polys: Array[PackedVector2Array] = []
var _outer: Rect2
var _start_pos: Vector2
var _sprite: Sprite2D
var _base_scale: Vector2
var _tween: Tween


func _ready() -> void:
	_start_pos = global_position
	
	for c in get_children():
		if c is Sprite2D:
			_sprite = c
			_base_scale = _sprite.scale
			break
	
	if _sprite == null:
		push_warning("dvd_bounce: no Sprite2D child found, click animation is off")
	
	if chips_label == null:
		push_warning("dvd_bounce: drag your chips label into 'Chips Label' in the Inspector")
	globalvars.aichips_changed.connect(_update_label)
	_update_label(globalvars.aichips)
	
	if per_click_label == null:
		push_warning("dvd_bounce: drag your per-click label into 'Per Click Label' in the Inspector")
	globalvars.aichips_per_click_changed.connect(_update_per_click_label)
	_update_per_click_label(globalvars.aiChipsPerClick)
	
	_bounce_sound = get_node_or_null(bounce_sound_path) as AudioStreamPlayer
	if _bounce_sound == null:
		push_warning("dvd_bounce: no AudioStreamPlayer at '%s'" % bounce_sound_path)
	
	_walls = get_node_or_null(walls_path)
	if _walls == null:
		push_warning("dvd_bounce: can't find the walls at '%s'" % walls_path)
		return
	
	_wall_polys = _collect(_walls)
	if _wall_polys.is_empty():
		push_warning("dvd_bounce: no collision shapes under the walls node")
		return
	
	var first := true
	for poly in _wall_polys:
		for p in poly:
			if first:
				_outer = Rect2(p, Vector2.ZERO)
				first = false
			else:
				_outer = _outer.expand(p)

	var angle := deg_to_rad(randf_range(20.0, 70.0) + 90.0 * randi_range(0, 3))
	velocity = Vector2.from_angle(angle) * speed

	if _hits_wall():
		push_warning("dvd_bounce: starting inside a wall, move him into the open area")


func _physics_process(delta: float) -> void:
	if _wall_polys.is_empty():
		return

	var move := velocity * delta
	var chunks := maxi(1, ceili(maxf(absf(move.x), absf(move.y)) / step_size))
	var step := move / chunks
	var bounced := false

	for i in chunks:
		global_position.x += step.x
		if _hits_wall():
			global_position.x -= step.x 
			velocity.x = -velocity.x 
			step.x = -step.x
			bounced = true

		global_position.y += step.y
		if _hits_wall():
			global_position.y -= step.y
			velocity.y = -velocity.y
			step.y = -step.y
			bounced = true

	if bounced and _bounce_sound != null:
		_bounce_sound.play()

	if not _outer.has_point(global_position):
		global_position = _start_pos

	if debug_draw:
		queue_redraw()

func _input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var mouse := get_global_mouse_position()
	for poly in _collect(self):
		if Geometry2D.is_point_in_polygon(mouse, poly):
			globalvars.aichips += globalvars.aiChipsPerClick
			_play_click_anim()
			if click_sound != null:
				click_sound.play()
			return

func _play_click_anim() -> void:
	if _sprite == null:
		return

	var height_px := _sprite.get_rect().size.y * absf(global_scale.y * _base_scale.y)
	if height_px <= 0.0:
		return
	var factor := clampf(1.0 - click_shrink_px / height_px, 0.1, 1.0)

	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_sprite, "scale", _base_scale * factor, click_anim_time * 0.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_sprite, "scale", _base_scale, click_anim_time * 0.6) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	pass


func _update_label(amount: int) -> void:
	if chips_label != null:
		chips_label.text = "%s CHIPS : %d" % [globalvars.ai_name, amount]

func _update_per_click_label(amount: int) -> void:
	if per_click_label != null:
		per_click_label.text = "%s CHIPS PER CLICK : %d" % [globalvars.ai_name, amount]

func _hits_wall() -> bool:
	var mine := _collect(self)
	for m in mine:
		for w in _wall_polys:
			if not Geometry2D.intersect_polygons(m, w).is_empty():
				return true
	return false

func _collect(parent: Node) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for c in parent.get_children():
		var poly := _node_polygon(c)
		if poly.size() >= 3:
			result.append(poly)
	return result


func _node_polygon(n: Node) -> PackedVector2Array:
	var out := PackedVector2Array()

	if n is CollisionPolygon2D:
		var cp := n as CollisionPolygon2D
		if cp.disabled:
			return out
		var t := cp.global_transform
		for p in cp.polygon:
			out.append(t * p)
		return out

	if n is CollisionShape2D:
		var cs := n as CollisionShape2D
		if cs.disabled or cs.shape == null:
			return out
		var t := cs.global_transform
		var local := PackedVector2Array()
		var s := cs.shape
		if s is RectangleShape2D:
			var h: Vector2 = (s as RectangleShape2D).size / 2.0
			local = PackedVector2Array([Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)])
		elif s is CircleShape2D:
			var r: float = (s as CircleShape2D).radius
			for i in 24:
				local.append(Vector2.from_angle(TAU * i / 24.0) * r)
		elif s is CapsuleShape2D:
			var cap := s as CapsuleShape2D
			var h2 := Vector2(cap.radius, cap.height / 2.0)
			local = PackedVector2Array([Vector2(-h2.x, -h2.y), Vector2(h2.x, -h2.y), Vector2(h2.x, h2.y), Vector2(-h2.x, h2.y)])
		for p in local:
			out.append(t * p)
	return out


func _draw() -> void:
	if not debug_draw:
		return
	for poly in _collect(self):
		_draw_poly(poly, Color.RED)
	for poly in _wall_polys:
		_draw_poly(poly, Color.GREEN)


func _draw_poly(poly: PackedVector2Array, color: Color) -> void:
	var pts := PackedVector2Array()
	for p in poly:
		pts.append(to_local(p))
	pts.append(pts[0])
	draw_polyline(pts, color, 3.0)
