extends Control

const DEFAULT_PORT: int = 12345
@onready var browserVBox: VBoxContainer = $HBox/VBoxContainer
@onready var serverBrowserUI: ServerBrowserUI = $HBox/VBoxContainer/ServerBrowserUI
@onready var serverBrowser: ServerBrowser = $ServerBrowser
@onready var console: Console = $HBox/Console
@onready var btnDisconnect: Button = $HBox/ButtonDisconnect
@onready var lineEdit: LineEdit = $HBox/VBoxContainer/LineEdit



func _ready():
	lineEdit.grab_focus()
	lineEdit.caret_column = lineEdit.text.length()
	
	multiplayer.connected_to_server.connect(join_as_client)
	multiplayer.server_disconnected.connect(_disconnect_from_server)
	serverBrowser.ServerDictUpdated.connect(serverBrowserUI.update_server_list)
	serverBrowserUI.JoinBtnClicked.connect(_join_server)
	
	serverBrowser.start()
	console.print_to_console("Server Browser started")


func _join_server(ip: String) -> void:
	browserVBox.hide()
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
	var player_name: String = lineEdit.text
	rpc_id(1, "server_spawn_player", client_id, player_name)
	

@rpc("any_peer")
func server_spawn_player(_client_id: int, _player_name: String) -> void:
	pass


func _on_button_disconnect_pressed():
	_disconnect_from_server()
	
	
func _disconnect_from_server() -> void:
	console.print_to_console("Disconnecting from Server")
	multiplayer.multiplayer_peer = null
	btnDisconnect.hide()
	browserVBox.show()
	serverBrowser.start()
	console.print_to_console("Server Browser started")
	
