extends RigidBody2D

signal picked_up

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimatedSprite2D.play() 
	body_entered.connect(_on_body_entered)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_entered(_body: Node2D) -> void:
	print('body entered')
	picked_up.emit()
