extends Node
class_name ConnectionHandler

const PORT_UDP_COMM: int = 42424
const PORT_SERVER_BROWSER: int = 5000
const IP_SERVER_BROWSER: String = "127.0.0.1"

var server := UDPServer.new()
var worldParent: world

var serverBrowserReached: bool = false

@onready var httpRequest: HTTPRequest = $HTTPRequest


func _ready():
	server.listen(PORT_UDP_COMM)
	
	
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


func _on_push_update_timer_timeout():
	var status = httpRequest.get_http_client_status()
	if status == HTTPClient.STATUS_DISCONNECTED:
		var request: String = "http://%s:%s/set_server" % [IP_SERVER_BROWSER, PORT_SERVER_BROWSER]
		var error = httpRequest.request(request)
		if error != OK:
			print("Error connecting to SeverBrowser. ErrorCode: %s" % error)
			
	elif status == HTTPClient.STATUS_REQUESTING:
		print("Not sending update to ServerBrowser, request still pending.")
	elif status == HTTPClient.STATUS_CONNECTING:
		print("Connection to ServerBrowser not yet established.")
	else:
		print("Not requesting, state is %s" % status)


func _on_http_request_request_completed(result, response_code, headers, body):
	var response: String = body.get_string_from_utf8()
	if response != "OK":
		print("Error pushing server state to ServerBrowser. Response: %s" % response)
