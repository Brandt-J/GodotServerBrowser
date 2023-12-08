extends Node
class_name ServerBrowser

const PORT: int = 42424
var udp := PacketPeerUDP.new()
var t0: int
var connected: bool = false

var serverList: Array = ["127.0.0.1", "45.84.138.205"]
var pingObjects: Dictionary = {}  # Key: IP, val: PingServerObjects


enum UDPState {AwaitingConnection,
			   ReadyToSendPackage,
			   AwaitingAnswer,
			   Disconnected,
			   NotResponding}
			

signal ServerDictUpdated(serverDict)


class PingServerObjects:
	var ip: String
	var timer: Timer
	var udp: PacketPeerUDP
	var t0: int = -1
	var state: UDPState
	var packetString: String
	var ping: int = -1
	
	func _init(ping_ip: String, ping_timer: Timer) -> void:
		ip = ping_ip
		timer = ping_timer
		udp = PacketPeerUDP.new()
		state = UDPState.Disconnected
		packetString = "%s" % randi_range(0, 5000)

	func connect_and_prepare_sending_package() -> void:
		if state != UDPState.Disconnected:  # i.e., got stuck somewhere
			ping = -1
			state = UDPState.Disconnected
			return
			
		udp.connect_to_host(ip, PORT)
		state = UDPState.AwaitingConnection
		
	func try_sending_package() -> void:
		if udp.is_socket_connected():
			udp.put_packet(packetString.to_utf8_buffer())
			state = UDPState.AwaitingAnswer
			t0 = Time.get_ticks_msec()
		
	func try_receiving_package() -> void:
		if udp.get_available_packet_count() > 0:
			ping = Time.get_ticks_msec() - t0
			udp.close()
			state = UDPState.Disconnected
		

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
	var curServers: Dictionary = {}
	randomize()
	for pingObject in pingObjects.values():
		curServers[pingObject.ip] = ["Tiny Town", randi_range(2, 5), pingObject.ping]
		print("Server %s: State: %s, Ping: %s" % [pingObject.ip, pingObject.state, pingObject.ping])
	ServerDictUpdated.emit(curServers)

	
func _add_new_server(ip: String) -> void:
	var newTimer: Timer = Timer.new()
	add_child(newTimer)
	newTimer.set_owner(self)
	pingObjects[ip] = PingServerObjects.new(ip, newTimer)


func _on_ping_servers_timer_timeout():
	for server in serverList:
		ping_server(server)
