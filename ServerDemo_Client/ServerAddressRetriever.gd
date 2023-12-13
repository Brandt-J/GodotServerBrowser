extends Node
class_name ServerAddressRetriever


const PORT_SERVER_BROWSER: int = 5000
const IP_SERVER_BROWSER: String = "127.0.0.1"

var ownIP: String = "unknown"

@onready var httpRequest: HTTPRequest = $HTTPRequest
@onready var timerUpdateServer_ips: Timer = $TimerUpdateServerIPs

signal ConsoleMessage(msg)
signal ServerListUpdated(ipList)


func start() -> void:
	timerUpdateServer_ips.start()
	
	
func stop() -> void:
	timerUpdateServer_ips.stop()


func _on_timer_update_server_i_ps_timeout():
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


func _on_http_request_request_completed(result, _response_code, _headers, body):
	if result != 0:
		ConsoleMessage.emit("Could not receive info from ServerBrowser")
		return
	
	if ownIP == "unknown":
		ownIP = body.get_string_from_utf8()
	else:
		_update_server_list(body.get_string_from_utf8())


func _update_server_list(string_from_server: String) -> void:
	var serverList = ["127.0.0.1"]  # we always include the localhost address
	var json: JSON = JSON.new()
	json.parse(string_from_server)
	var listFromServer: Array = json.get_data()
	for ip in listFromServer:
		if ip != ownIP:  # but skip the localhost here
			serverList.append(ip)
	
	ServerListUpdated.emit(serverList)
