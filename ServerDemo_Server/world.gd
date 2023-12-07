extends Node2D


const DEFAULT_PORT: int = 12345
@onready var vbox: VBoxContainer = $VBoxContainer


func _ready():
	multiplayer.peer_connected.connect(self._peer_connected)
	start_server()
	

func start_server() -> void:
	var port: int = DEFAULT_PORT
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	

func _peer_connected(id: int) -> void:
	_print_to_vbox("Peer %s connected." % id)


@rpc("any_peer")
func server_spawn_player(client_id: int, player_name: String) -> void:
	_print_to_vbox("Spawning player %s on network ID %s" % [player_name, client_id])
	rpc_id(client_id, "create_player_node")


@rpc
func create_player_node() -> void:
	pass
	

func _print_to_vbox(text: String) -> void:
	print(text)
	var newLbl: Label = Label.new()
	newLbl.text = text
	vbox.add_child(newLbl)
	newLbl.set_owner(vbox)
