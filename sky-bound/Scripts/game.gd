extends Node3D
@onready var label: Label = $Label
@onready var death_panel: Panel = $CanvasLayer/DeathPanel


var player_score = 0
@export var scores_per_step := 5

func _ready() -> void:
	death_panel.hide()
func increase_score(score):
	player_score += score # or += scores_per_step if you want to use that export
	label.text = "Score: " + str(player_score)

func get_current_score():
	return player_score
var single_scoreboard = 0
var players
var multi_scoreboard: Dictionary = {}

var single_scoreboard = 0
var players
var multi_scoreboard: Dictionary = {}

@export var scores_per_step:=5

func _ready() -> void:
	players = multiplayer.get_peers()
	players.append(multiplayer.get_unique_id())
	# Instantiate scoreboard for players
	for player in players:
		multi_scoreboard[player] = 0
		
	_update_label()
	
func increase_score_for_id(id: int):
	if id not in multi_scoreboard:
		multi_scoreboard[id] = 1
	else:
		multi_scoreboard[id] += 1
		
	if multiplayer.is_server():
		_update_multi_scoreboard_rpc.rpc(multi_scoreboard)
	_update_label()
		
func increase_score_single():
	single_scoreboard += 1
	_update_label()

func _on_mob_spawner_3d_mob_spawned(mob):
	if not multiplayer.is_server():
		return
	mob.died_by.connect(func(id):
		if NetworkConnection.is_multiplayer:
			increase_score_for_id(id)
		)
	mob.died.connect(func():
		increase_score(1)
	)
		increase_score_single())

func _on_boss_mob_spawner_3d_mob_spawned(mob):
	mob.died.connect(func():
		increase_score(5)
	)
func end_game():
	# Make sure the panel processes while paused
	$CanvasLayer.process_mode = Node.PROCESS_MODE_ALWAYS
	death_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var score_label := death_panel.get_node("FinalScoreLabel") as Label
	if score_label:
		score_label.text = "Score: " + str(player_score)
	# Show the panel and pause gameplay
	death_panel.show()
	get_tree().paused = true
		increase_score_single())

func _on_killplane_body_entered(body: Node3D) -> void:
	# Only end the game if the player hits the kill plane
	if body.is_in_group("player") or body.name == "Player":
		call_deferred("end_game")
	get_tree().reload_current_scene.call_deferred()

func _update_label():
	if not NetworkConnection.is_multiplayer:
		# Singleplayer output
		label.text = "Score: " + str(single_scoreboard)
		return

	# Multiplayer scoreboard output
	var text := ""
	for id in multi_scoreboard.keys():
		text += str(id) + ": " + str(multi_scoreboard[id]) + "\n"
	label.text = text

@rpc("reliable", "call_local")
func _update_multi_scoreboard_rpc(updated: Dictionary):
	multi_scoreboard = updated
	_update_label()
