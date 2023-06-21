extends Control

var addedElements: Array = []  # stores ui elements that were created
var ip2LevelPath: Dictionary = {}  # key: IP, value: Path of Level to load
	
@onready var gridContainer: GridContainer = $VBoxContainer/GridContainer
@onready var editName: LineEdit = $VBoxContainer/LineEditPlayerName


func _ready():
	networkManager.connect("ServerListUpdated", _update_server_entries)  # Here I connect to a global signal that communicates the updated server list. Use, whatever is convenient for you ;)
	editName.text = globals.playerName
	networkManager.start_server_browser()
		

func _update_server_entries(serverInfo: Dictionary) -> void:
	_reset()
	var lblIP: Label
	var lblMap: Label
	var lblPlayers: Label
	var lblPing: Label
	var joinBtn: Button
	var lambdaJoin: Callable
	
	for ip in serverInfo:
		ip2LevelPath[ip] = serverInfo[ip].levelPath

		lblIP = Label.new()
		lblIP.text = ip
		
		lblMap = Label.new()
		lblMap.text = serverInfo[ip].mapName 

		lblPlayers = Label.new()
		lblPlayers.text = "%s" % serverInfo[ip].numPlayers
		
		lblPing = Label.new()
		lblPing.text = "%s" % serverInfo[ip].ping

		joinBtn = Button.new()
		lambdaJoin = func(): _join_server(ip)
		joinBtn.connect("pressed", lambdaJoin)
		joinBtn.text = "Join Server"

		for element in [lblIP, lblMap, lblPlayers, lblPing, joinBtn]:
			gridContainer.add_child(element)
			element.set_owner(gridContainer)
			addedElements.append(element)
	

func _reset() -> void:
	for element in addedElements:
		element.queue_free()
	
	ip2LevelPath = {}
	addedElements = []


func _join_server(serverIP: String) -> void:
	networkManager.stop_server_browser()
	globals.gameServerIP = serverIP
	globals.playerName = editName.text
	
	SceneLoader.goto_scene(ip2LevelPath[serverIP])
