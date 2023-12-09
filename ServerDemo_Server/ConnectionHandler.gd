extends Node
class_name ConnectionHandler

const PORT: int = 42424
var server := UDPServer.new()
var worldParent: world

func _ready():
	server.listen(PORT)
	
	
func set_world_parent(worldNode: world) -> void:
	worldParent = worldNode
	

func _process(delta):
	server.poll() # Important!
	if server.is_connection_available():
		var peer: PacketPeerUDP = server.take_connection()
		var sendPacket: String = ""
		if is_instance_valid(worldParent):
			sendPacket = "%s_%s" % [worldParent.get_map_name(), worldParent.get_num_players()]
		
		peer.put_packet(sendPacket.to_utf8_buffer())
