extends PanelContainer
class_name Console


@export var maxLines: int = 20
var addedLineLabels: Array = []

@onready var vbox: VBoxContainer = $VBoxContainer


func print_to_console(text: String) -> void:
	print(text)
	if addedLineLabels.size() == maxLines - 1:
		addedLineLabels[0].queue_free()
		addedLineLabels.pop_front()
	
	var newLbl: Label = Label.new()
	vbox.add_child(newLbl)
	newLbl.set_owner(vbox)
	newLbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	newLbl.text = text
