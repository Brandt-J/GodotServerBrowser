extends Node

"""
CODE TO IMPLEMENT ON THE SERVER SIDE.
"""


@onready var httpRequest: HTTPRequest = $HTTPRequest  # <- Add a HTTPRequest-Node to the scene
var logger: Logging.Logger
var serverBrowserIP: String = "127.0.0.1"  # Edit correct IP of server that runs the serverBrowser.py script
var serverBrowserPort: int = 5000  # And the corresponding port
var t0Request: int
var serverBrowserPing: int = -1
var pingsFromServer: Array[int] = []
var maxPingsToServerBrowser: int = 10


	
# Tie this function to a timer to send updates to the server
func _on_push_server_state_timer_timeout():
	var status = httpRequest.get_http_client_status()
	if status == HTTPClient.STATUS_DISCONNECTED:
		var request: String = _get_server_status_request()
		t0Request = Time.get_ticks_msec()
		var error = httpRequest.request(request)
		if error != OK:
			logger.info("Error connecting to SeverBrowser. ErrorCode: %s" % error)
			
	elif status == HTTPClient.STATUS_REQUESTING:
		logger.debug("Not sending update to ServerBrowser, request still pending.")
	elif status == HTTPClient.STATUS_CONNECTING:
		logger.debug("Connectino to ServerBrowser not yet established.")
	else:
		logger.debug("Not requesting, state is %s" % status)


# Tie this function to the http_request_request_completed-signal of the HTTPRequest-Node
func _on_http_request_request_completed(result, response_code, headers, body):
	_compute_ping_to_browser()
	var response: String = body.get_string_from_utf8()
	if response != "OK":
		logger.info("Error pushing server state to ServerBrowser. Response: %s" % response)
		

# Modify this function to gather the information that you want to send to the serverBrowser
func _get_server_status_request() -> String:
	var levelPath: String = get_tree().current_scene.scene_file_path
	levelPath = levelPath.replace("//", "@@")
	levelPath = levelPath.replace("/", "@")
	var numPlayers: int = playerManager.get_number_of_players()
	return "http://%s:%s/set_server/%s/%s/%s" % [serverBrowserIP, serverBrowserPort, levelPath, numPlayers, serverBrowserPing]


func _compute_ping_to_browser() -> void:
	var curPing: int = Time.get_ticks_msec() - t0Request
	if pingsFromServer.size() == maxPingsToServerBrowser:
		pingsFromServer.pop_front()
		
	pingsFromServer.append(curPing)
	var pingSum: int = 0
	for ping in pingsFromServer:
		pingSum += ping
	
	serverBrowserPing = pingSum / pingsFromServer.size()
