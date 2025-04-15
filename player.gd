extends Area2D

# Custom signal the player emits when they collide with an enemy
signal hit
signal boost_changed

const BASE_SPEED = 200
# Moving diagonally slows you down
const DIAGONAL_PENALTY_RATIO = 0.8
# Boosting speeds you up
const BOOST_RATIO = 1.6
const MAX_BOOST = 100

# How fast the player will move (pixels/sec)
@export var boost = 100
# Size of game window
var screen_size


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Step 0 - setup variables
	var velocity = Vector2.ZERO # The player's movement vector.
	var speed = BASE_SPEED
	
	# Step 1 - Get player input
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("boost") && self.boost > 0:
		add_boost(-1)
		speed *= BOOST_RATIO

	# Step 2 - Orient sprite
	if velocity.x != 0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_v = velocity.y > 0

	# Step 3 - Determine how far the sprite will move
	if velocity.length() > 0:
		# moving diagonally slows you down
		if velocity.length() > 1:
			speed *= DIAGONAL_PENALTY_RATIO

		# need to normalize to avoid "bonus" movement when going diagonally
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()

	# Step 4 - Actually move the sprite
	position += velocity * delta
	# Don't go off screen!
	position = position.clamp(Vector2.ZERO, screen_size)

# Reset the player for a new game!
func start(pos):
	self.boost = MAX_BOOST
	position = pos
	show()
	$CollisionShape2D.disabled = false
	$BoostTimer.start()

func add_boost(val):
	self.boost += val
	if boost > MAX_BOOST:
		self.boost = MAX_BOOST
	boost_changed.emit()

func set_boost(val):
	self.boost = val
	if boost > MAX_BOOST:
		self.boost = MAX_BOOST
	boost_changed.emit()

func _on_body_entered(_body: Node2D) -> void:
	hide() # Player disappears after being hit.
	hit.emit()
	# Must be deferred as we can't change physics properties on a physics callback.
	$CollisionShape2D.set_deferred("disabled", true)
	$BoostTimer.stop()

func _on_boost_timer_timeout() -> void:
	if self.boost < MAX_BOOST && !Input.is_action_pressed("boost"):
		add_boost(1)
