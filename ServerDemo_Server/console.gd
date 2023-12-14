extends PanelContainer
class_name Console


@export var maxLines: int = 20
var addedLineLabels: Array = []

@onready var vbox: VBoxContainer = $VBoxContainer


func print_to_console(text: String) -> void:
	var dt=Time.get_datetime_dict_from_system()
	var timeString: String = "%02d:%02d:%02d: " % [dt.hour,dt.minute,dt.second]	
	text = timeString + text
	print(text)
	if addedLineLabels.size() == maxLines - 1:
		addedLineLabels[0].queue_free()
		addedLineLabels.pop_front()
	
	var newLbl: Label = Label.new()
	vbox.add_child(newLbl)
	newLbl.set_owner(vbox)
	newLbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	newLbl.text = text
