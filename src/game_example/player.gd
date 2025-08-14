extends CharacterBody2D


const SPEED = 400.0


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("left", "right", "up", "down")
	
	if direction:
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
