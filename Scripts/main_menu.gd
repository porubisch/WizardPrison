extends Node3D

@onready var lobby_input: LineEdit = %LobbyIDInput
@onready var status_label: Label = %StatusLabel
@onready var invite_button: Button = %InviteButton


func _ready() -> void:
	Network.status_changed.connect(_on_status_changed)
	Network.game_ready.connect(_on_game_ready)

	invite_button.disabled = true

	%HostButton.pressed.connect(_on_host_pressed)
	%JoinButton.pressed.connect(_on_join_pressed)
	invite_button.pressed.connect(_on_invite_pressed)


func _on_host_pressed() -> void:
	Network.host_game()


func _on_join_pressed() -> void:
	var id_text: String = lobby_input.text.strip_edges()

	if not id_text.is_valid_int():
		status_label.text = "Please enter a valid lobby ID."
		return

	Network.join_game(int(id_text))


func _on_invite_pressed() -> void:
	Network.invite_friends()


func _on_status_changed(message: String) -> void:
	status_label.text = message
	invite_button.disabled = Network.lobby_id == 0



func _on_game_ready() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://Scenes/world.tscn")
