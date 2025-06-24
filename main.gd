extends Node

# In functions requiring angles, Godot uses radians instead of degrees
const FULL_TURN = TAU # PI * 2
const HALF_TURN = PI
const QUARTER_TURN = PI / 2
const EIGHTH_TURN = PI / 4

@export var mob_scene: PackedScene
@export var point_orb_scene: PackedScene
@export var difficulty_scale: int
var score

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect signals
	$Player.hit.connect(_on_player_hit)
	$Player.boost_changed.connect(_on_player_boost_changed)
	$HUD.start_game.connect(_on_hud_start_game)
	$MobTimer.timeout.connect(_on_mob_timer_timeout)
	$StartTimer.timeout.connect(_on_start_timer_timeout)
	$ScoreTimer.timeout.connect(_on_score_timer_timeout)
	$DifficultyTimer.timeout.connect(_on_difficulty_timer_timeout)
	#$PointOrbTimer.timeout.connect(_on_point_orb_timer_timeout)

	# Hide player until game starts
	$Player.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_player_hit():
	$GameOver.play()
	$HUD.show_game_over()
	$Player.hide()
	$MobTimer.stop()
	$Music.stop()
	$ScoreTimer.stop()
	

func new_game():
	# clean up previous game
	get_tree().call_group("mobs", "queue_free")
	score = 0
	difficulty_scale = 1
	
	# start new game
	$Player.show()
	$Player.start($StartPosition.position)
	$HUD.update_boost($Player.boost)
	$Music.play()
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")
	$StartTimer.start()
	$DifficultyTimer.start()


func _on_mob_timer_timeout():
	print('mob timer - spawn mob')
	# Create a new instance of the Mob scene.
	var mob = mob_scene.instantiate()

	# Choose a random location on Path2D.
	var mob_spawn_location = $MobPath/MobSpawnLocation
	# progress_ratio is a decimal (0.0-1.0) representing a % along the path
	# randf() returns a random float 0.0 ≤ x ≤ 1.0
	# so we end up in a random position along the path
	mob_spawn_location.progress_ratio = randf()

	# Set the mob's position to the random location.
	mob.position = mob_spawn_location.position

	# Set the mob's direction perpendicular to the path direction.
	# The path automatically rotates as it moves, so it always
	# takes a 1/4 turn to be perpendicular.
	var direction = mob_spawn_location.rotation + QUARTER_TURN

	# Add some randomness to the direction.
	direction += randf_range(-1 * EIGHTH_TURN, EIGHTH_TURN)
	mob.rotation = direction

	# Choose the velocity for the mob with a random speed
	var min_speed = 100.0 + (50.0 * difficulty_scale)
	var max_speed = 200.0 + (50.0 * difficulty_scale)
	var velocity = Vector2(randf_range(min_speed, max_speed), 0.0)
	mob.linear_velocity = velocity.rotated(direction)

	# Spawn the mob by adding it to the Main scene.
	add_child(mob)

func _on_point_orb_timer_timeout():
	print('point orb timout - making new orb')
	# Create a new instance of the Mob scene.
	var point_orb = point_orb_scene.instantiate()
	point_orb.picked_up.connect(_on_point_orb_picked_up)

	# Choose a random location on Path2D.
	var point_orb_spawn_location = $PointOrbPath/PointOrbSpawnLocation
	# progress_ratio is a decimal (0.0-1.0) representing a % along the path
	# randf() returns a random float 0.0 ≤ x ≤ 1.0
	# so we end up in a random position along the path
	point_orb_spawn_location.progress_ratio = randf()

	# Set the mob's position to the random location.
	point_orb.position = point_orb_spawn_location.position

	# Spawn the mob by adding it to the Main scene.
	add_child(point_orb)
	#$PointOrbTimer.stop()

func _on_hud_start_game() -> void:
	new_game()

func _on_score_timer_timeout() -> void:
	self.score += 1
	$HUD.update_score(score)

func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	#$PointOrbTimer.start() # TODO: fix pickup/collision logic
	$ScoreTimer.start()

func _on_player_boost_changed() -> void:
	$HUD.update_boost($Player.boost)

func _on_difficulty_timer_timeout() -> void:
	self.difficulty_scale += 1

func _on_point_orb_picked_up() -> void:
	print('picked up orb')
	self.score += 100
	point_orb_scene.queue_free()
	$PointOrbTimer.start()
