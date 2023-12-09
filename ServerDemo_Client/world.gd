extends Control

const DEFAULT_PORT: int = 12345
@onready var serverBrowserUI: ServerBrowserUI = $ServerBrowserUI
@onready var serverBrowser: ServerBrowser = $ServerBrowser
@onready var console: Console = $Console
@onready var btnDisconnect: Button = $ButtonDisconnect



func _ready():
	multiplayer.connected_to_server.connect(join_as_client)
	serverBrowser.ServerDictUpdated.connect(serverBrowserUI.update_server_list)
	serverBrowserUI.JoinBtnClicked.connect(_join_server)
	serverBrowser.start()
	console.print_to_console("Server Browser started")


func _join_server(ip: String) -> void:
	serverBrowserUI.hide()
	btnDisconnect.show()
	serverBrowser.stop()
	console.print_to_console("Server Browser stopped")
	
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, DEFAULT_PORT)
	multiplayer.multiplayer_peer = peer
	console.print_to_console("Joining Server")


func join_as_client() -> void:
	console.print_to_console("Connection established, calling to spawn player")
	var client_id: int = multiplayer.get_unique_id()
	var player_name: String = "DefaultPlayer"
	rpc_id(1, "server_spawn_player", client_id, player_name)
	

@rpc("any_peer")
func server_spawn_player(client_id: int, player_name: String) -> void:
	pass


@rpc
func create_player_node() -> void:
	console.print_to_console("Now actually running code to create the player here")
	


func _on_button_disconnect_pressed():
	console.print_to_console("Disconnecting from Server")
	multiplayer.multiplayer_peer = null
	btnDisconnect.hide()
	serverBrowserUI.show()
	serverBrowser.start()
	console.print_to_console("Server Browser started")
	
