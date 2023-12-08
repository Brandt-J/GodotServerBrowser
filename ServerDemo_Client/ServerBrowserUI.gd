extends Control
class_name ServerBrowserUI


@onready var grid: GridContainer = $GridContainer
@onready var label_map: Label = $GridContainer/Label_Map
@onready var label_players: Label = $GridContainer/Label_Players
@onready var label_ping: Label = $GridContainer/Label_Ping
@onready var join: Label = $GridContainer/Join

var uiElementsServers: Dictionary = {}  # key: ip, val: [lblIP, lblMap, lblPlayers, lblPing, btnJoin]

signal JoinBtnClicked(ip)


func update_server_list(newServerDict: Dictionary) -> void:
#	print("new Server Dict: ", newServerDict)
	# dict: key: ip, val: [mapname, numPlayers, ping]
	for ip in uiElementsServers:
		if ip in newServerDict:
			_update_server_entries(ip, newServerDict[ip])
		else:
			_remove_server_entries(ip)
	
	for ip in newServerDict:
		if not ip in uiElementsServers:
			_add_new_server(ip, newServerDict[ip])


func _update_server_entries(ip: String, serverInfo: Array) -> void:
	# serverInfo = [mapname, numPlayers, ping]
	uiElementsServers[ip][1].text = serverInfo[0]
	uiElementsServers[ip][2].text = "%s" % serverInfo[1]
	uiElementsServers[ip][3].text = "%s" % serverInfo[2]


func _remove_server_entries(ip: String) -> void:
	for element in uiElementsServers[ip]:
		element.queue_free()
	uiElementsServers.erase(ip)
	

func _add_new_server(ip: String, details: Array) -> void:
	var lblIP: Label = _get_label_in_grid(ip)
	var lblMap: Label = _get_label_in_grid(details[0])
	var lblPlayers: Label = _get_label_in_grid("%s" % details[1])
	var lblPing: Label = _get_label_in_grid("%s" % details[2])
	var btnJoin: Button = _get_join_btn_in_grid(ip)
	uiElementsServers[ip] = [lblIP, lblMap, lblPlayers, lblPing, btnJoin]
	
	
func _get_label_in_grid(labelText: String) -> Label:
	var lbl: Label = Label.new()
	lbl.text = labelText
	grid.add_child(lbl)
	lbl.set_owner(grid)
	return lbl


func _get_join_btn_in_grid(ip: String) -> Button:
	var newBtn: Button = Button.new()
	newBtn.text = "Join"
	var btnFunc: Callable = func(): _joinBtnClicked(ip)
	newBtn.pressed.connect(btnFunc)
	grid.add_child(newBtn)
	newBtn.set_owner(grid)
	return newBtn
	
	

func _joinBtnClicked(ip: String) -> void:
	JoinBtnClicked.emit(ip)
