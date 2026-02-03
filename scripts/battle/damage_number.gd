extends Label
class_name DamageNumber
## DamageNumber - Floating damage number that fades out

var velocity: Vector2 = Vector2(0, -30)
var lifetime: float = 0.8
var timer: float = 0.0


func _ready() -> void:
	# Random horizontal drift
	velocity.x = randf_range(-20, 20)


func _process(delta: float) -> void:
	timer += delta

	# Move upward
	position += velocity * delta

	# Slow down
	velocity *= 0.95

	# Fade out
	var alpha = 1.0 - (timer / lifetime)
	modulate.a = alpha

	# Remove when done
	if timer >= lifetime:
		queue_free()


static func create(damage: float, pos: Vector2, is_crit: bool = false) -> DamageNumber:
	var num = DamageNumber.new()
	num.text = str(int(damage))
	num.position = pos
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if is_crit:
		num.text += "!"
		num.add_theme_color_override("font_color", Color.YELLOW)
		num.scale = Vector2(1.3, 1.3)
	else:
		num.add_theme_color_override("font_color", Color.WHITE)

	return num
