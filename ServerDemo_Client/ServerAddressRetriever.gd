extends Node
class_name ServerAddressRetriever


const PORT_SERVER_BROWSER: int = 5000
const IP_SERVER_BROWSER: String = "127.0.0.1"

var ownIP: String = "unknown"
var serverBrowserReached: bool = false
var fistConnectAttempt: bool = true

@onready var httpRequest: HTTPRequest = $HTTPRequest
@onready var timerUpdateServer_ips: Timer = $TimerUpdateServerIPs

signal ConsoleMessage(msg)
signal ServerListUpdated(ipList)


func start() -> void:
	timerUpdateServer_ips.start()
	
	
func stop() -> void:
	timerUpdateServer_ips.stop()
	serverBrowserReached = false
	fistConnectAttempt = true


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

	elif status != HTTPClient.STATUS_CONNECTING:
		if serverBrowserReached:
			ConsoleMessage.emit("Lost connection to remote ServerBrowser, status is: %s" % status)
			serverBrowserReached = false


func _on_http_request_request_completed(result, _response_code, _headers, body):
	var validResponse: bool = result == 0
	var responseString: String = body.get_string_from_utf8()
	var serverList = ["127.0.0.1"]  # we always include the localhost address

	if not serverBrowserReached and validResponse:
		ConsoleMessage.emit("Established connection to remote ServerBrowser:\nScanning for remote servers.")
		serverBrowserReached = true

	elif fistConnectAttempt and not validResponse:
		ConsoleMessage.emit("Connection to serverbrowser not possible:\nCan only search for locally hosted servers.")
	
	if validResponse:
		if ownIP == "unknown":
			ownIP = responseString
		else:
			serverList.append_array(_get_remote_servers(responseString))
	
	ServerListUpdated.emit(serverList)
	fistConnectAttempt = false


func _get_remote_servers(string_from_server: String) -> Array:
	var remoteServers: Array = []
	var json: JSON = JSON.new()
	json.parse(string_from_server)
	var listFromServer: Array = json.get_data()
	for ip in listFromServer:
		if ip != ownIP:  # but skip the localhost here
			remoteServers.append(ip)
	
	return remoteServers
