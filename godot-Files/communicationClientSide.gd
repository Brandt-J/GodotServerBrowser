extends Node


"""
Implement this code somewhere on the Client Side
"""

var serverBrowserIP: String = "127.0.0.1"   # Edit correct IP of server that runs the serverBrowser.py script
var serverBrowserPort: int = 5000  # And the corresponding port

@onready var logger: Logging.Logger = Logging.get_logger("Connection Handler")
@onready var updateTimer: Timer = $UpdateTimer  # Add a timer for retrieving the server list
@onready var httpRequest: HTTPRequest = $HTTPRequest  # Add a HTTPRequest-Node for communication to the serverBrowser


# Convenience functions to start/stop requesting server updates
func start_scanning_servers() -> void:
	updateTimer.start()
	

func stop_scanning_servers() -> void:
	updateTimer.stop()

	
# Tie this function to the timeout of the UpdateTimer
func _on_update_timer_timeout():
	var status = httpRequest.get_http_client_status()
	if status == HTTPClient.STATUS_DISCONNECTED:
		var error = httpRequest.request("http://%s:%s/get_server_list" % [serverBrowserIP, serverBrowserPort])
		if error != OK:
			logger.critical("Error connecting serverBrowser! ErrorCode: %s" % error)
			
	elif status == HTTPClient.STATUS_REQUESTING:
		logger.debug("Not sending update to ServerBrowser, request still pending")
	else:
		logger.debug("Not requesting, state is %s" % status)



# Convenience function to retrieve the mapname from the scenePath. No need to use if you don't need it
func _get_mapname_from_levelpath(levelPath: String) -> String:
	var mapName: String = levelPath.split("/")[-1]  # yields mapname.tscn
	mapName = mapName.split(".")[0]
	return mapName


# Tie this function to the http_request_request_completed-Signal of the HTTPRequest-Node
func _on_http_request_request_completed(result, response_code, headers, body):
	var serverDict = {}
	if result != 0:
		logger.critical("Could not receive info from ServerBrowser")
	else:
		var json: JSON = JSON.new()
		json.parse(body.get_string_from_utf8())
		var dictFromServer: Array = json.get_data()
		var curServerInfo
		var levelPath: String
		for dict in dictFromServer:
			curServerInfo = networkManager.ServerInfo.new(dict["ip"])
			levelPath = dict["levelPath"]
			levelPath = levelPath.replace("@@", "//")
			levelPath = levelPath.replace("@", "/")
			curServerInfo.levelPath = levelPath
			curServerInfo.mapName = _get_mapname_from_levelpath(levelPath)
			curServerInfo.numPlayers = dict["numPlayers"]
			curServerInfo.ping = dict["ping"]

			serverDict[dict["ip"]] = curServerInfo

	networkManager.emit_signal("ServerListUpdated", serverDict)  # <- Here I use a global Singletonn to emit when a new server list was retrieved
