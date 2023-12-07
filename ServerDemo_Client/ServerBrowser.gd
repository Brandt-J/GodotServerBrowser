extends Control
class_name ServerBrowser


@onready var grid: GridContainer = $GridContainer
@onready var label_map: Label = $GridContainer/Label_Map
@onready var label_players: Label = $GridContainer/Label_Players
@onready var label_ping: Label = $GridContainer/Label_Ping
@onready var join: Label = $GridContainer/Join

var uiElementsServers: Dictionary = {}  # key: ip, val: [lblIP, lblMap, lblPlayers, lblPing, btnJoin]

signal JoinBtnClicked(ip)


func update_server_list(serverDict: Dictionary) -> void:
	# dict: key: ip, val: [mapname, numPlayers, ping]
	for ip in serverDict:
		if ip not in uiElementsServers:
			_add_new_server(ip, serverDict[ip])



func _add_new_server(ip: String, details: Array) -> void:
	var lblIP: Label = _get_label_in_grid(ip)
	var lblMap: Label = _get_label_in_grid(details[0])
	var lblPlayers: Label = _get_label_in_grid("%s" % details[1])
	var lblPing: Label = _get_label_in_grid("%s" % details[2])
	var btnJoin: Button = _get_join_btn_in_grid(ip)
	
	


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
