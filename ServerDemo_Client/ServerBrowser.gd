extends Node
class_name ServerBrowser

const PORT_UDP_COMM: int = 42424
const PORT_SERVER_BROWSER: int = 5000
const IP_SERVER_BROWSER: String = "127.0.0.1"

var udp := PacketPeerUDP.new()
var t0: int
var connected: bool = false
var ownIP: String = "unknown"

var serverList: Array = ["127.0.0.1", "45.84.138.205"]
var pingObjects: Dictionary = {}  # Key: IP, val: PingServerObjects

@onready var timerPingServers = $PingServersTimer
@onready var TimerUpdateServers = $UpdateServersTimer
@onready var httpRequest: HTTPRequest = $HTTPRequest


enum UDPState {AwaitingConnection,
			   ReadyToSendPackage,
			   AwaitingAnswer,
			   Disconnected,
			   NotResponding}
			

signal ServerDictUpdated(serverDict)
signal ConsoleMessage(msg)

class PingServerObjects:
	var ip: String
	var timer: Timer
	var udp: PacketPeerUDP
	var t0: int = -1
	var state: UDPState
	var receivedString: String
	var ping: int = -1
	
	func _init(ping_ip: String, ping_timer: Timer) -> void:
		ip = ping_ip
		timer = ping_timer
		udp = PacketPeerUDP.new()
		state = UDPState.Disconnected

	func connect_and_prepare_sending_package() -> void:
		if state != UDPState.Disconnected:  # i.e., got stuck somewhere
			ping = -1
			state = UDPState.Disconnected
			return
			
		udp.connect_to_host(ip, PORT_UDP_COMM)
		state = UDPState.AwaitingConnection
		
	func try_sending_package() -> void:
		if udp.is_socket_connected():
			udp.put_packet("0".to_utf8_buffer())
			state = UDPState.AwaitingAnswer
			t0 = Time.get_ticks_msec()
		
	func try_receiving_package() -> void:
		if udp.get_available_packet_count() > 0:
			var packet: PackedByteArray = udp.get_packet()
			receivedString = packet.get_string_from_utf8()
			ping = Time.get_ticks_msec() - t0
			udp.close()
			state = UDPState.Disconnected


func start() -> void:
	timerPingServers.start()
	TimerUpdateServers.start()
	

func stop() -> void:
	timerPingServers.stop()
	TimerUpdateServers.stop()


func ping_server(ip: String) -> void:
	if not ip in pingObjects:
		_add_new_server(ip)
	
	var pingObj: PingServerObjects = pingObjects[ip]
	pingObj.connect_and_prepare_sending_package()
		

func _process(_delta: float) -> void:
	for pingObject in pingObjects.values():
		pingObject = pingObject as PingServerObjects
		
		match pingObject.state:
			UDPState.AwaitingConnection:
				pingObject.try_sending_package()
			UDPState.AwaitingAnswer:
				pingObject.try_receiving_package()


func _on_update_servers_timer_timeout():
	_get_pings_and_emit_server_list()
	_request_remote_server_list()


func _get_pings_and_emit_server_list() -> void:
	var curServers: Dictionary = {}
	for pingObject in pingObjects.values():
		if pingObject.ping >= 0:
			var mapName: String = pingObject.receivedString.split("_")[0]
			var numPlayers: String = pingObject.receivedString.split("_")[1]
			curServers[pingObject.ip] = [mapName, numPlayers, pingObject.ping]
	ServerDictUpdated.emit(curServers)
	
	
func _request_remote_server_list() -> void:
	var status = httpRequest.get_http_client_status()
	var error
	if status == HTTPClient.STATUS_DISCONNECTED:
		if ownIP == "unknown":
			error = httpRequest.request("http://%s:%s/get_own_ip" % [IP_SERVER_BROWSER, PORT_SERVER_BROWSER])
		else:
			error = httpRequest.request("http://%s:%s/get_server_list" % [IP_SERVER_BROWSER, PORT_SERVER_BROWSER])
		
		if error != OK:
			ConsoleMessage.emit("Error connecting serverBrowser! ErrorCode: %s" % error)

	elif status == HTTPClient.STATUS_REQUESTING:
		ConsoleMessage.emit("Not sending update to ServerBrowser, request still pending")
	else:
		ConsoleMessage.emit("Not requesting, state is %s" % status)
		
	
func _add_new_server(ip: String) -> void:
	var newTimer: Timer = Timer.new()
	add_child(newTimer)
	newTimer.set_owner(self)
	pingObjects[ip] = PingServerObjects.new(ip, newTimer)


func _on_ping_servers_timer_timeout():
	for server in serverList:
		ping_server(server)


func _on_http_request_request_completed(result, response_code, headers, body):
	if result != 0:
		ConsoleMessage.emit("Could not receive info from ServerBrowser")
		return
	
	if ownIP == "unknown":
		ownIP = body.get_string_from_utf8()
	else:
		_update_server_list(body.get_string_from_utf8())


func _update_server_list(string_from_server: String) -> void:
	var serverDict = {}
	var json: JSON = JSON.new()
	json.parse(string_from_server)
	var dictFromServer: Array = json.get_data()
	var curServerInfo
	var levelPath: String
	var serverIP: String
	for dict in dictFromServer:
		serverIP = dict["ip"]
		if serverIP == ownIP:
			serverIP = "127.0.0.1"
			
#		curServerInfo = networkManager.ServerInfo.new(serverIP)
		levelPath = dict["levelPath"]
		levelPath = levelPath.replace("@@", "//")
		levelPath = levelPath.replace("@", "/")
#		curServerInfo.levelPath = levelPath
#		curServerInfo.mapName = _get_mapname_from_levelpath(levelPath)
#		curServerInfo.numPlayers = dict["numPlayers"]
		if serverIP == "127.0.0.1":
			curServerInfo.ping = "-"
		else:
			curServerInfo.ping = dict["ping"]

		serverDict[serverIP] = curServerInfo

#	networkManager.emit_signal("ServerListUpdated", serverDict)
