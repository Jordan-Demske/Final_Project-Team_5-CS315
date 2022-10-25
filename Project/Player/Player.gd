extends KinematicBody2D

signal no_health
signal health_changed(value)
signal max_health_changed(value)

enum State {
	MOVE,
	ROLL,
	ATTACK,
}

const _ACCELERATION := 400
const _FRICTION := 400
const _MAX_SPEED := 100
const _ROLL_SPEED := 120

export(int) var max_health := 1 setget set_max_health
var health := max_health setget set_health
var _state = State.MOVE
var _knockback_vector := Vector2.DOWN
var _velocity := Vector2.ZERO
var _roll_vector := Vector2.DOWN
var footsteps_playing = false

onready var _swordHitbox := $HitboxPivot/SwordHitbox
onready var _animationPlayer := $AnimationPlayer
onready var _animationTree := $AnimationTree
onready var _hurtbox := $Hurtbox
onready var _animationState = _animationTree.get("parameters/playback")
onready var _flashTimer = $Hurtbox/FlashTimer

func _ready():
	self.set_max_health(self.max_health)
	self.set_health(self.max_health)
# warning-ignore:return_value_discarded
	self.connect("no_health", self, "queue_free")
	_animationTree.active = true
	_swordHitbox.knockback_vector = _knockback_vector


func _physics_process(delta):
	match _state:
		State.MOVE:
			move_state(delta)
			
		State.ATTACK:
			attack_state(delta)
			
		State.ROLL:
			roll_state(delta)


func move_state(delta):
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		_roll_vector = input_vector
		if $Footsteps.playing == false:
			$Footsteps.playing = true
		_swordHitbox.knockback_vector = input_vector
		_animationTree.set("parameters/Idle/blend_position", input_vector)
		_animationTree.set("parameters/Run/blend_position", input_vector)
		_animationTree.set("parameters/Attack/blend_position", input_vector)
		_animationTree.set("parameters/Roll/blend_position", input_vector)
		_animationState.travel("Run")
		_velocity = _velocity.move_toward(input_vector * _MAX_SPEED, _ACCELERATION * delta)
	else:
		if $Footsteps.playing == true:
			$Footsteps.playing = false
		_animationState.travel("Idle")
		_velocity = _velocity.move_toward(Vector2.ZERO, _FRICTION * delta)
	
	move()
	
	if Input.is_action_just_pressed("roll"):
		_state = State.ROLL
	
	if Input.is_action_just_pressed("attack"):
		$SwordSwoosh.play()
		_state = State.ATTACK


func roll_state(_delta):
	_velocity = _roll_vector * _ROLL_SPEED
	_animationState.travel("Roll")
	move()


func attack_state(_delta):
	_velocity = Vector2.ZERO
	_animationState.travel("Attack")


func move():
	_velocity = move_and_slide(_velocity)	


func attack_animation_finished():
	_velocity = Vector2.ZERO
	_state = State.MOVE


func roll_animation_finished():
	_state = State.MOVE


func _on_Hurtbox_area_entered(area):
	$Hit.play()
	self.health -= area.damage
	_hurtbox.start_invincibility(1)
	_hurtbox.create_hit_effect(area)
	flash()

func flash():
	$Sprite.material.set_shader_param("flash_modifier", 1)
	_flashTimer.start()


func _on_FlashTimer_timeout():
	$Sprite.material.set_shader_param("flash_modiefier", 0)


func set_max_health(value):
	max_health = value
# warning-ignore:narrowing_conversion
	self.health = min(health, max_health)
	emit_signal("max_health_changed", max_health)


func set_health(value):
	health = value
	emit_signal("health_changed", health)
	if health <= 0:
		emit_signal("no_health")


func _on_HealHeart_body_entered(_body):
	addHeart()

func _on_HealHeart2_body_entered(_body):
	print(2)
	addHeart()

func _on_HealHeart3_body_entered(_body):
	addHeart()


func addHeart():
	if(health < max_health):
		set_health(health + (max_health - health))
