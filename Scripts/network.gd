#adkjsjsjs
extends Node

signal status_changed(message: String)
signal game_ready

const MAX_PLAYERS: int = 8

var lobby_id: int = 0
var steam_initialized: bool = false
var hosting: bool = false

var steam_peer: SteamMultiplayerPeer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.join_requested.connect(_on_join_requested)

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	var result: Dictionary = Steam.steamInitEx()

	if result["status"] == 0:
		steam_initialized = true
		print("Steam initialized successfully!")
		print("Steam username: ", Steam.getPersonaName())
	else:
		push_error("Steam initialization failed: " + str(result["verbal"]))


func _process(_delta: float) -> void:
	if steam_initialized:
		Steam.run_callbacks()


func host_game() -> void:
	if not steam_initialized:
		status_changed.emit("Steam is not initialized!")
		return

	if lobby_id != 0:
		status_changed.emit("Already in a lobby!")
		return

	hosting = true
	status_changed.emit("Creating Steam lobby...")

	Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, MAX_PLAYERS)


func _on_lobby_created(result: int, new_lobby_id: int) -> void:
	if result != 1:
		hosting = false
		status_changed.emit("Failed to create lobby!")
		return

	lobby_id = new_lobby_id

	Steam.setLobbyData(lobby_id, "name", Steam.getPersonaName() + "'s Game")
	Steam.setLobbyData(lobby_id, "game_id", "my_team_game")

	steam_peer = SteamMultiplayerPeer.new()
	steam_peer.server_relay = true

	var error: Error = steam_peer.create_host(0)

	if error != OK:
		status_changed.emit("Failed to start Steam host!")
		Steam.leaveLobby(lobby_id)
		lobby_id = 0
		hosting = false
		steam_peer = null
		return

	multiplayer.multiplayer_peer = steam_peer

	print("Hosting Steam lobby: ", lobby_id)
	status_changed.emit("Hosting! Lobby ID: " + str(lobby_id))
	game_ready.emit()



func join_game(id: int) -> void:
	if not steam_initialized:
		status_changed.emit("Steam is not initialized!")
		return

	if lobby_id != 0:
		status_changed.emit("Leave your current lobby first!")
		return

	if id <= 0:
		status_changed.emit("Invalid lobby ID!")
		return

	hosting = false
	status_changed.emit("Joining Steam lobby...")

	Steam.joinLobby(id)


func _on_lobby_joined(joined_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if hosting:
		return

	if response != 1:
		status_changed.emit("Unable to join Steam lobby!")
		return

	lobby_id = joined_id

	var host_steam_id: int = Steam.getLobbyOwner(lobby_id)
	
	
	print("CLIENT: Joined Steam lobby!")
	print("CLIENT: Host Steam ID: ", host_steam_id)
	print("CLIENT: My Steam ID: ", Steam.getSteamID())


	steam_peer = SteamMultiplayerPeer.new()
	steam_peer.server_relay = true

	var error: Error = steam_peer.create_client(host_steam_id, 0)

	if error != OK:
		status_changed.emit("Failed to connect to Steam host!")
		Steam.leaveLobby(lobby_id)
		lobby_id = 0
		steam_peer = null
		return

	multiplayer.multiplayer_peer = steam_peer
	
	print("CLIENT: Steam peer assigned!")
	print("CLIENT: Connection status: ", steam_peer.get_connection_status())

	status_changed.emit("Connecting to host...")


func invite_friends() -> void:
	if lobby_id == 0:
		status_changed.emit("Host or join a lobby first!")
		return

	Steam.activateGameOverlayInviteDialog(lobby_id)


func _on_join_requested(requested_lobby_id: int, _friend_id: int) -> void:
	if lobby_id != 0:
		leave_game()

	join_game(requested_lobby_id)


func leave_game() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	steam_peer = null

	if lobby_id != 0:
		Steam.leaveLobby(lobby_id)

	lobby_id = 0
	hosting = false
	status_changed.emit("Disconnected")


func _on_peer_connected(id: int) -> void:
	print("Peer connected: ", id)
	status_changed.emit("Player connected! Peer ID: " + str(id))


func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected: ", id)
	status_changed.emit("Player disconnected: " + str(id))


func _on_connected_to_server() -> void:
	print("Connected to Steam host!")
	status_changed.emit("Connected to host!")
	game_ready.emit()


func _on_connection_failed() -> void:
	print("Connection failed!")
	leave_game()
	status_changed.emit("Connection failed!")


func _on_server_disconnected() -> void:
	print("Host disconnected!")
	leave_game()
	status_changed.emit("Host disconnected!")
