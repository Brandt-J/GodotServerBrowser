extends Node
class_name ConnectionHandler

const PORT_UDP_COMM: int = 42424
const PORT_SERVER_BROWSER: int = 5000
const IP_SERVER_BROWSER: String = "127.0.0.1"

var server := UDPServer.new()
var worldParent: world

var serverBrowserReached: bool = false
var fistConnectAttempt: bool = true

@onready var httpRequest: HTTPRequest = $HTTPRequest

signal ConsoleMessage(msg)


func _ready():
	server.listen(PORT_UDP_COMM)
	
	
func set_world_parent(worldNode: world) -> void:
	worldParent = worldNode
	

func _process(_delta):
	server.poll() # Important!
	if server.is_connection_available():
		var peer: PacketPeerUDP = server.take_connection()
		var sendPacket: String = ""
		if is_instance_valid(worldParent):
			sendPacket = "%s_%s" % [worldParent.get_map_name(), worldParent.get_num_players()]
		
		peer.put_packet(sendPacket.to_utf8_buffer())


func _on_push_update_timer_timeout():
	var status = httpRequest.get_http_client_status()
	if status == HTTPClient.STATUS_DISCONNECTED:
		var request: String = "http://%s:%s/set_server" % [IP_SERVER_BROWSER, PORT_SERVER_BROWSER]
		var error = httpRequest.request(request)
		if error != OK:
			ConsoleMessage.emit("Error connecting to SeverBrowser. ErrorCode: %s" % error)
	
	else:
		if serverBrowserReached:
			ConsoleMessage.emit("Lost connection to remote ServerBrowser\nOnly scanning for local servers.")
			serverBrowserReached = false


func _on_http_request_request_completed(_result, _response_code, _headers, body):
	var response: String = body.get_string_from_utf8()
	
	if not serverBrowserReached and response == "OK":
		ConsoleMessage.emit("Established connection to remote ServerBrowser")
		serverBrowserReached = true
		
	elif fistConnectAttempt and response != "OK":
		ConsoleMessage.emit("Connection to serverbrowser not possible")

	fistConnectAttempt = false
