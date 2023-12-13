extends Node
class_name ServerInfoRetriever


const PORT_UDP_COMM: int = 42424

var udp := PacketPeerUDP.new()
var t0: int

var pingObjects: Dictionary = {}  # Key: IP, val: PingServerObjects

enum UDPState {AwaitingConnection,
			   ReadyToSendPackage,
			   AwaitingAnswer,
			   Disconnected,
			   NotResponding}
			
@onready var timerUpdateServerDict: Timer = $TimerUpdateServerDict

signal ServerDictUpdated(serverDict)

func start() -> void:
	timerUpdateServerDict.start()
	
	
func stop() -> void:
	timerUpdateServerDict.stop()


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


func get_server_infos(ipList: Array) -> void:
	for server in ipList:
		_ping_server(server)


func _on_timer_update_server_dict_timeout():
	var curServers: Dictionary = {}
	for pingObject in pingObjects.values():
		if pingObject.ping >= 0:
			var mapName: String = pingObject.receivedString.split("_")[0]
			var numPlayers: String = pingObject.receivedString.split("_")[1]
			curServers[pingObject.ip] = [mapName, numPlayers, pingObject.ping]
	ServerDictUpdated.emit(curServers)
	
	
func _process(_delta: float) -> void:
	for pingObject in pingObjects.values():
		pingObject = pingObject as PingServerObjects
		
		match pingObject.state:
			UDPState.AwaitingConnection:
				pingObject.try_sending_package()
			UDPState.AwaitingAnswer:
				pingObject.try_receiving_package()


func _ping_server(ip: String) -> void:
	if not ip in pingObjects:
		_add_new_server(ip)
	
	var pingObj: PingServerObjects = pingObjects[ip]
	pingObj.connect_and_prepare_sending_package()
	
	
func _add_new_server(ip: String) -> void:
	var newTimer: Timer = Timer.new()
	add_child(newTimer)
	newTimer.set_owner(self)
	pingObjects[ip] = PingServerObjects.new(ip, newTimer)
