
extends Node3D

const PLAYER_SCENE = preload("res://Scenes/player.tscn")

@onready var players: Node = %Players
@onready var spawner: MultiplayerSpawner = %MultiplayerSpawner


func _ready() -> void:
	spawner.spawn_function = _create_player

	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	if multiplayer.is_server():
		spawner.spawn(1)
	else:
		request_spawn.rpc_id(1)


func _create_player(id: Variant) -> Node:
	var peer_id: int = int(id)

	var player = PLAYER_SCENE.instantiate()

	player.name = str(peer_id)
	player.set_multiplayer_authority(peer_id)

	if peer_id == 1:
		player.position = Vector3(0, 1.5, 0)
	else:
		player.position = Vector3(4 + (peer_id % 4) * 3, 1.5, 0)

	return player


@rpc("any_peer", "reliable")
func request_spawn() -> void:
	if not multiplayer.is_server():
		return

	var peer_id: int = multiplayer.get_remote_sender_id()

	if players.has_node(str(peer_id)):
		return

	spawner.spawn(peer_id)


func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server():
		return

	var player = players.get_node_or_null(str(id))

	if player:
		player.queue_free()
