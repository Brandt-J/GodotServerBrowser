extends Control
class_name world


const DEFAULT_PORT: int = 12345
var connectedPeers: Dictionary = {}  # key: id, val: playerName
@onready var console: Console = $HBox/Console
@onready var btnMapSelector: OptionButton = $HBox/PanelContainer/GridContainer/MapSelector
@onready var lblNumPlayers: Label = $HBox/PanelContainer/GridContainer/LabelNumPlayers
@onready var connectionHandler: ConnectionHandler = $ConnectionHandler


func _ready():
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	connectionHandler.set_world_parent(self)
	start_server()
	

func start_server() -> void:
	var port: int = DEFAULT_PORT
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	console.print_to_console("Server running.")
	

func _peer_connected(id: int) -> void:
	connectedPeers[id] = "UnknownPlayer"
	console.print_to_console("Peer %s connected." % id)
	lblNumPlayers.text = "%s" % connectedPeers.size()
	
	
func _peer_disconnected(id: int) -> void:
	console.print_to_console("Player %s disconnected." % connectedPeers[id])
	connectedPeers.erase(id)
	lblNumPlayers.text = "%s" % connectedPeers.size()


func get_map_name() -> String:
	return btnMapSelector.text
	
	
func get_num_players() -> int:
	return connectedPeers.size()
	

@rpc("any_peer")
func server_spawn_player(client_id: int, player_name: String) -> void:
	console.print_to_console("Spawning %s on network ID %s" % [player_name, client_id])
	connectedPeers[client_id] = player_name
