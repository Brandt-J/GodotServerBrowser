extends Node
class_name ServerBrowser


@onready var serverAddressRetriever = $ServerAddressRetriever
@onready var serverInfoRetriever = $ServerInfoRetriever

signal ServerDictUpdated(serverDict)
signal ConsoleMessage(msg)


func _ready():
	serverAddressRetriever.ServerListUpdated.connect(serverInfoRetriever.get_server_infos)
	serverAddressRetriever.ConsoleMessage.connect(_re_emit_console_message)
	serverInfoRetriever.ServerDictUpdated.connect(_re_emit_server_dict_update)


func start() -> void:
	serverAddressRetriever.start()
	serverInfoRetriever.start()
	

func stop() -> void:
	serverAddressRetriever.stop()
	serverInfoRetriever.stop()


func _re_emit_server_dict_update(serverDict: Dictionary) -> void:
	ServerDictUpdated.emit(serverDict)
	

func _re_emit_console_message(msg: String) -> void:
	ConsoleMessage.emit(msg)
