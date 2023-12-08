extends Node2D

const DEFAULT_PORT: int = 12345
@onready var vbox: VBoxContainer = $VBoxContainer
@onready var serverBrowserUI: ServerBrowserUI = $VBoxContainer/ServerBrowserUI
@onready var serverBrowser: ServerBrowser = $ServerBrowser



func _ready():
	multiplayer.connected_to_server.connect(join_as_client)
	
#	var fakeDict: Dictionary = {"127.0.0.1": ["TinyTown", 3, 25],
#								"45.84.138.205": ["TestMap", 5, 72]}
	serverBrowser.ServerDictUpdated.connect(serverBrowserUI.update_server_list)
#	serverBrowser.update_server_list(fakeDict)
#	join_server()


func join_server() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_client('127.0.0.1', DEFAULT_PORT)
	multiplayer.multiplayer_peer = peer
	_print_to_vbox("Joining Server")


func join_as_client() -> void:
	_print_to_vbox("Connection established, calling to spawn player")
	var client_id: int = multiplayer.get_unique_id()
	var player_name: String = "Test_Player"
	rpc_id(1, "server_spawn_player", client_id, player_name)
	

@rpc("any_peer")
func server_spawn_player(client_id: int, player_name: String) -> void:
	pass


@rpc
func create_player_node() -> void:
	_print_to_vbox("Now actually running code to create the player here")
	

func _print_to_vbox(text: String) -> void:
	print(text)
	var newLbl: Label = Label.new()
	newLbl.text = text
	vbox.add_child(newLbl)
	newLbl.set_owner(vbox)
	
